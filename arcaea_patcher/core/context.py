"""Runtime context for an APK patching session."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from arcaea_patcher.config import PatchConfig


@dataclass
class PatchContext:
    config: PatchConfig
    temp_root: Path
    templates_dir: Path

    @property
    def decoded_dir(self) -> Path:
        return self.temp_root / "decoded"

    @property
    def unaligned_apk(self) -> Path:
        return self.temp_root / "unaligned.apk"
