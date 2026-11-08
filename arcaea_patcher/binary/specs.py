"""Concrete ELF binary patch specifications for exported dynamic symbols."""

from __future__ import annotations

from typing import List

from arcaea_patcher.binary.patcher import (
    ARM32_RET,
    ARM32_RET_0,
    ARM32_RET_1,
    ARM64_RET,
    ARM64_RET_0,
    ARM64_RET_1,
    THUMB_RET,
    THUMB_RET_0,
    THUMB_RET_1,
    BinaryPatchSpec,
    PatternPatchSpec,
    SymbolPatchSpec,
)

# =============================================================================
# Symbol Patch Specifications (.dynsym)
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


def pattern_patch_specs() -> List[PatternPatchSpec]:
    """Pattern patch specs. Obsolete curl patches have been moved to runtime detour hooks."""
    return []


def all_binary_specs() -> List[BinaryPatchSpec]:
    """Returns all active binary patch specifications."""
    specs: List[BinaryPatchSpec] = []
    specs.extend(symbol_patch_specs())
    return specs
