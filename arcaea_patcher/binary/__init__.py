"""Declarative ELF binary patching subsystem."""

from arcaea_patcher.binary.elf import ElfBinary, SectionHeader
from arcaea_patcher.binary.patcher import (
    ARCH_NAMES,
    EM_AARCH64,
    EM_ARM,
    BinaryPatchResult,
    BinaryPatchSpec,
    Pattern,
    PatternPatchSpec,
    SymbolPatchSpec,
    find_all,
    find_first,
    parse_pattern,
)
from arcaea_patcher.binary.specs import (
    all_binary_specs,
    pattern_patch_specs,
    symbol_patch_specs,
)

__all__ = [
    "ARCH_NAMES",
    "EM_AARCH64",
    "EM_ARM",
    "BinaryPatchResult",
    "BinaryPatchSpec",
    "PatternPatchSpec",
    "SymbolPatchSpec",
    "ElfBinary",
    "SectionHeader",
    "Pattern",
    "parse_pattern",
    "find_all",
    "find_first",
    "symbol_patch_specs",
    "pattern_patch_specs",
    "all_binary_specs",
]
