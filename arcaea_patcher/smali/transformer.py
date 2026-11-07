"""Base abstractions and bytecode rewriting helpers for Smali transformations."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
import re
from typing import Dict, List, Tuple

NEUTRAL_RETURN_BODIES: Dict[str, str] = {
    "V": "    .locals 0\n    return-void\n",
    "Z": "    .locals 1\n    const/4 v0, 0x1\n    return v0\n",
    "I": "    .locals 1\n    const/4 v0, 0x1\n    return v0\n",
}


@dataclass(frozen=True)
class SmaliTransformResult:
    name: str
    target: str
    ok: bool
    sites_modified: int
    detail: str


class SmaliTransform(ABC):
    name: str

    @abstractmethod
    def apply(self, decoded_dir: Path) -> List[SmaliTransformResult]:
        raise NotImplementedError


def replace_method_with_neutral_return(content: str, method_name: str) -> Tuple[str, int, str]:
    """Replaces all non-native/abstract overloads of method_name with a neutral return body."""
    pattern = re.compile(
        rf"(\.method\s+[^\n]*\b{re.escape(method_name)}\([^\n]*\)([^\s\r\n]+)\r?\n)"
        r"(.*?)"
        r"(\.end method)",
        re.DOTALL,
    )

    patched = 0
    skipped: List[str] = []

    def _sub(match: re.Match) -> str:
        nonlocal patched
        header, ret_type, _body, footer = match.groups()
        if re.search(r"\b(?:native|abstract)\b", header):
            skipped.append("native/abstract")
            return match.group(0)
        replacement = NEUTRAL_RETURN_BODIES.get(ret_type)
        if replacement is None:
            skipped.append(f"unsupported return '{ret_type}'")
            return match.group(0)
        patched += 1
        return f"{header}{replacement}{footer}"

    new_content = pattern.sub(_sub, content)
    return new_content, patched, "; ".join(sorted(set(skipped)))


def inject_param_static_filter(
    path: Path,
    method_sig_regex: str,
    param_reg: str,
    static_method_descriptor: str,
) -> bool:
    """Injects a static String->String filter call on param_reg at the start of a Smali method."""
    content = path.read_text(encoding="utf-8")
    pattern = re.compile(
        rf"(\.method\s+[^\n]*\b{method_sig_regex}\r?\n)(.*?)(\.end method)",
        re.DOTALL,
    )
    match = pattern.search(content)
    if not match:
        return False

    header, body, footer = match.groups()
    if static_method_descriptor in body:
        return True

    call_snippet = (
        f"    invoke-static {{{param_reg}}}, {static_method_descriptor}\n"
        f"    move-result-object {param_reg}\n"
    )
    reg_match = re.search(r"(\s*\.(?:locals|registers)\s+\d+\r?\n)", body)
    if reg_match:
        new_body = body.replace(reg_match.group(1), reg_match.group(1) + call_snippet, 1)
    else:
        new_body = call_snippet + body

    content = content.replace(match.group(0), f"{header}{new_body}{footer}", 1)
    path.write_text(content, encoding="utf-8")
    return True

