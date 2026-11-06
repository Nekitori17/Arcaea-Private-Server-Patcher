"""libcurl pinned-public-key verifier bypass specifications."""

from __future__ import annotations

from typing import List

from arcaea_patcher.binary.arm_asm import ARM32_RET_0, ARM64_RET_0, EM_AARCH64, EM_ARM
from arcaea_patcher.binary.base import BinaryPatchSpec, PatternPatchSpec

# Matches the prologue tail of curl's pkp_pin_peer_pubkey so that an already-patched
# function prologue is still detected idempotently at (hit - 8).
_PATTERNS = {
    EM_AARCH64: "F8 5F 02 A9 F6 57 03 A9 F4 4F 04 A9 FD 43 00 91 FF 07 00 F9 42 05 00 B4",
    EM_ARM: "00 40 A0 E3 00 00 52 E3 04 40 8D E5 01 70 A0 11 5A 40 A0 13 00 00 51 13",
}

_STUBS = {
    EM_AARCH64: ARM64_RET_0,
    EM_ARM: ARM32_RET_0,
}

_ANCHORS = {
    EM_AARCH64: -len(ARM64_RET_0),
    EM_ARM: -len(ARM32_RET_0),
}


def specs() -> List[BinaryPatchSpec]:
    return [
        PatternPatchSpec(
            name="curl-pinned-pubkey-bypass",
            patterns_by_arch=_PATTERNS,
            stubs_by_arch=_STUBS,
            anchor_by_arch=_ANCHORS,
            desc="CURLE_OK (return 0)",
            optional=False,
        )
    ]
