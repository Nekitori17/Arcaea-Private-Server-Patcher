"""Merges pre-compiled templates (libext.so and Smali classes) into the decoded APK."""

from __future__ import annotations

from pathlib import Path
import re
import shutil
from typing import List


def _resolve_next_smali_dir(decoded_dir: Path) -> Path:
    """Determines the next sequential smali_classes{N} folder in decoded_dir."""
    has_base_smali = (decoded_dir / "smali").is_dir()
    existing_indices = [
        int(m.group(1))
        for d in decoded_dir.iterdir()
        if d.is_dir() and (m := re.match(r"^smali_classes(\d+)$", d.name))
    ]
    if existing_indices:
        next_idx = max(existing_indices) + 1
        return decoded_dir / f"smali_classes{next_idx}"
    if has_base_smali:
        return decoded_dir / "smali_classes2"
    return decoded_dir / "smali"


def merge_baked_templates(templates_dir: Path, decoded_dir: Path) -> List[str]:
    """Copies template libraries and places template Smali into a dedicated DEX folder."""
    if not templates_dir.is_dir():
        return []

    target_smali_dir = _resolve_next_smali_dir(decoded_dir)
    merged: List[str] = []

    for src in sorted(templates_dir.rglob("*")):
        if not src.is_file():
            continue
        rel = src.relative_to(templates_dir)
        parts = rel.parts
        if parts and parts[0].startswith("smali"):
            sub_rel = Path(*parts[1:])
            dst = target_smali_dir / sub_rel
        else:
            dst = decoded_dir / rel

        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        merged.append(dst.relative_to(decoded_dir).as_posix())

    return merged

