"""Concrete ELF binary patch specifications separated into Symbol and Pattern patches."""

from __future__ import annotations

from typing import List

from arcaea_patcher.binary.patcher import (
    ARM32_RET,
    ARM32_RET_0,
    ARM32_RET_1,
    ARM64_RET,
    ARM64_RET_0,
    ARM64_RET_1,
    EM_AARCH64,
    EM_ARM,
    THUMB_RET,
    THUMB_RET_0,
    THUMB_RET_1,
    BinaryPatchSpec,
    PatternPatchSpec,
    SymbolPatchSpec,
)

# =============================================================================
# 1. Symbol Patch Specifications (.dynsym)
# =============================================================================

_VOID_SYMBOLS = (
    "SSL_CTX_set_verify",
    "SSL_set_verify",
    "SSL_CTX_set_custom_verify",
    "SSL_CTX_set_cert_verify_callback",
)

_RET1_SYMBOLS = (
    "X509_verify_cert",
    "SSL_set1_host",
    "X509_check_host",
)

_RET0_SYMBOLS = (
    "SSL_get_verify_result",
)


def symbol_patch_specs() -> List[SymbolPatchSpec]:
    """Builds declarative symbol patch specifications for exported dynamic symbols."""
    specs: List[SymbolPatchSpec] = []

    for sym in _VOID_SYMBOLS:
        specs.append(
            SymbolPatchSpec(
                name=f"sym-{sym}",
                symbol=sym,
                arm64_stub=ARM64_RET,
                arm32_stub=ARM32_RET,
                thumb_stub=THUMB_RET,
                desc="void",
                optional=True,
            )
        )

    for sym in _RET1_SYMBOLS:
        specs.append(
            SymbolPatchSpec(
                name=f"sym-{sym}",
                symbol=sym,
                arm64_stub=ARM64_RET_1,
                arm32_stub=ARM32_RET_1,
                thumb_stub=THUMB_RET_1,
                desc="return 1",
                optional=True,
            )
        )

    for sym in _RET0_SYMBOLS:
        specs.append(
            SymbolPatchSpec(
                name=f"sym-{sym}",
                symbol=sym,
                arm64_stub=ARM64_RET_0,
                arm32_stub=ARM32_RET_0,
                thumb_stub=THUMB_RET_0,
                desc="return 0",
                optional=True,
            )
        )

    return specs


# =============================================================================
# 2. Pattern Patch Specifications (.text instruction signatures)
# =============================================================================

_CURL_PATTERNS = {
    EM_AARCH64: "F8 5F 02 A9 F6 57 03 A9 F4 4F 04 A9 FD 43 00 91 FF 07 00 F9 42 05 00 B4",
    EM_ARM: "00 40 A0 E3 00 00 52 E3 04 40 8D E5 01 70 A0 11 5A 40 A0 13 00 00 51 13",
}

_CURL_STUBS = {
    EM_AARCH64: ARM64_RET_0,
    EM_ARM: ARM32_RET_0,
}

_CURL_ANCHORS = {
    EM_AARCH64: -len(ARM64_RET_0),
    EM_ARM: -len(ARM32_RET_0),
}


def pattern_patch_specs() -> List[PatternPatchSpec]:
    """Builds declarative wildcard pattern patch specifications for binary functions."""
    return [
        PatternPatchSpec(
            name="curl-pinned-pubkey-bypass",
            patterns_by_arch=_CURL_PATTERNS,
            stubs_by_arch=_CURL_STUBS,
            anchor_by_arch=_CURL_ANCHORS,
            desc="CURLE_OK (return 0)",
            optional=False,
        )
    ]


# =============================================================================
# Aggregated Specifications
# =============================================================================

def all_binary_specs() -> List[BinaryPatchSpec]:
    """Returns all symbol and pattern patch specifications."""
    specs: List[BinaryPatchSpec] = []
    specs.extend(symbol_patch_specs())
    specs.extend(pattern_patch_specs())
    return specs
