"""Declarative ELF binary patching subsystem."""

from arcaea_patcher.binary.arm_asm import ARCH_NAMES, EM_AARCH64, EM_ARM
from arcaea_patcher.binary.base import BinaryPatchResult, BinaryPatchSpec, PatternPatchSpec, SymbolPatchSpec
from arcaea_patcher.binary.elf_map import ElfBinary
from arcaea_patcher.binary.specs import all_binary_specs

__all__ = [
    "ARCH_NAMES",
    "EM_AARCH64",
    "EM_ARM",
    "BinaryPatchResult",
    "BinaryPatchSpec",
    "PatternPatchSpec",
    "SymbolPatchSpec",
    "ElfBinary",
    "all_binary_specs",
]
