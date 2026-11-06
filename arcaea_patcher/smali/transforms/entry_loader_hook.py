"""Injects ExtEntry.init(Context) into the launcher Activity's onCreate()."""

from __future__ import annotations

from pathlib import Path
import re
from typing import List

from arcaea_patcher.smali.base import SmaliTransform, SmaliTransformResult

ENTRY_CALL_SNIPPET = "    invoke-static/range {p0 .. p0}, Lmoe/ext/arc/ExtEntry;->init(Landroid/content/Context;)V\n"
CANDIDATE_ACTIVITIES = (
    "**/AppActivity.smali",
    "**/MainActivity.smali",
    "**/Cocos2dxActivity.smali",
)


class EntryLoaderHookTransform(SmaliTransform):
    """Injects ExtEntry.init(p0) immediately after super.onCreate() in primary Activity."""

    name = "smali-ext-entry-loader"

    def apply(self, decoded_dir: Path) -> List[SmaliTransformResult]:
        for pattern in CANDIDATE_ACTIVITIES:
            for path in decoded_dir.glob(pattern):
                rel = path.relative_to(decoded_dir).as_posix()
                content = path.read_text(encoding="utf-8")

                if "Lmoe/ext/arc/ExtEntry;->init" in content:
                    return [SmaliTransformResult(self.name, rel, True, 1, "already injected")]

                method_match = re.search(
                    r"(\.method\s+[^\n]*onCreate\(Landroid/os/Bundle;\)V\r?\n)(.*?)(\.end method)",
                    content,
                    re.DOTALL,
                )
                if not method_match:
                    continue

                header, body, footer = method_match.groups()
                super_match = re.search(
                    r"(invoke-super(?:/range)?\s+\{[^\}]+\},\s+L[^\n]+;->onCreate\(Landroid/os/Bundle;\)V\r?\n)",
                    body,
                )

                if super_match:
                    new_body = body.replace(super_match.group(1), super_match.group(1) + ENTRY_CALL_SNIPPET, 1)
                else:
                    reg_match = re.search(r"(\s*\.(?:locals|registers)\s+\d+\r?\n)", body)
                    if reg_match:
                        new_body = body.replace(reg_match.group(1), reg_match.group(1) + ENTRY_CALL_SNIPPET, 1)
                    else:
                        new_body = ENTRY_CALL_SNIPPET + body

                content = content.replace(method_match.group(0), f"{header}{new_body}{footer}", 1)
                path.write_text(content, encoding="utf-8")
                return [SmaliTransformResult(self.name, rel, True, 1, "ExtEntry.init injected")]

        return [SmaliTransformResult(self.name, "Activity.smali", False, 0, "no suitable Activity found")]
