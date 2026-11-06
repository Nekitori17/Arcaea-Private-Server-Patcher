"""ARM64, ARM32, and Thumb machine code stubs for binary verification bypasses."""

from __future__ import annotations

from typing import Dict

EM_ARM = 0x28
EM_AARCH64 = 0xB7

ARCH_NAMES: Dict[int, str] = {
    EM_AARCH64: "AArch64",
    EM_ARM: "ARM32",
}

# AArch64 stubs
ARM64_RET = b"\xC0\x03\x5F\xD6"                    # ret
ARM64_RET_1 = b"\x20\x00\x80\x52" + ARM64_RET      # mov w0, #1 ; ret
ARM64_RET_0 = b"\x00\x00\x80\x52" + ARM64_RET      # mov w0, #0 ; ret

# ARM32 (A32) stubs
ARM32_RET = b"\x1E\xFF\x2F\xE1"                    # bx lr
ARM32_RET_1 = b"\x01\x00\xA0\xE3" + ARM32_RET      # mov r0, #1 ; bx lr
ARM32_RET_0 = b"\x00\x00\xA0\xE3" + ARM32_RET      # mov r0, #0 ; bx lr

# ARM32 Thumb (T32) stubs
THUMB_RET = b"\x70\x47"                            # bx lr
THUMB_RET_1 = b"\x01\x20" + THUMB_RET              # movs r0, #1 ; bx lr
THUMB_RET_0 = b"\x00\x20" + THUMB_RET              # movs r0, #0 ; bx lr
