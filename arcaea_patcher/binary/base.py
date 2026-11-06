"""Declarative binary patch specifications for ELF shared libraries."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Dict

from arcaea_patcher.binary.arm_asm import EM_AARCH64, EM_ARM
from arcaea_patcher.binary.elf_map import ElfBinary
from arcaea_patcher.binary.pattern import find_first


@dataclass(frozen=True)
class BinaryPatchResult:
    name: str
    ok: bool
    already_patched: bool
    offset: int
    detail: str
    optional: bool = False


class BinaryPatchSpec(ABC):
    name: str
    desc: str
    optional: bool = False

    @abstractmethod
    def apply(self, data: bytearray, elf: ElfBinary) -> BinaryPatchResult:
        raise NotImplementedError


@dataclass()
class SymbolPatchSpec(BinaryPatchSpec):
    """Patches an exported .dynsym function entry point with architecture/Thumb awareness."""
    name: str
    symbol: str
    arm64_stub: bytes
    arm32_stub: bytes
    thumb_stub: bytes
    desc: str = ""
    optional: bool = True

    def apply(self, data: bytearray, elf: ElfBinary) -> BinaryPatchResult:
        found = elf.find_dynsym_offset(self.symbol)
        if found is None:
            return BinaryPatchResult(
                name=self.name,
                ok=False,
                already_patched=False,
                offset=-1,
                detail=f"{self.symbol} not in .dynsym",
                optional=self.optional,
            )

        offset, is_thumb = found
        if elf.e_machine == EM_AARCH64:
            patch = self.arm64_stub
        elif elf.e_machine == EM_ARM:
            patch = self.thumb_stub if is_thumb else self.arm32_stub
        else:
            return BinaryPatchResult(
                name=self.name,
                ok=False,
                already_patched=False,
                offset=offset,
                detail=f"unsupported arch 0x{elf.e_machine:X}",
                optional=self.optional,
            )

        end = offset + len(patch)
        if end > len(data):
            return BinaryPatchResult(
                name=self.name,
                ok=False,
                already_patched=False,
                offset=offset,
                detail="offset out of bounds",
                optional=self.optional,
            )

        mode_note = f"{self.desc}, Thumb" if is_thumb else self.desc
        if bytes(data[offset:end]) == patch:
            return BinaryPatchResult(
                name=self.name,
                ok=True,
                already_patched=True,
                offset=offset,
                detail=f"already patched ({mode_note})",
                optional=self.optional,
            )

        data[offset:end] = patch
        return BinaryPatchResult(
            name=self.name,
            ok=True,
            already_patched=False,
            offset=offset,
            detail=mode_note,
            optional=self.optional,
        )


@dataclass()
class PatternPatchSpec(BinaryPatchSpec):
    """Locates a site via IDA-style pattern per architecture + anchor shift, then writes stub."""
    name: str
    patterns_by_arch: Dict[int, str]
    stubs_by_arch: Dict[int, bytes]
    anchor_by_arch: Dict[int, int]
    desc: str = ""
    optional: bool = False

    def apply(self, data: bytearray, elf: ElfBinary) -> BinaryPatchResult:
        pattern = self.patterns_by_arch.get(elf.e_machine)
        stub = self.stubs_by_arch.get(elf.e_machine)
        anchor = self.anchor_by_arch.get(elf.e_machine, 0)

        if not pattern or not stub:
            return BinaryPatchResult(
                name=self.name,
                ok=False,
                already_patched=False,
                offset=-1,
                detail=f"unsupported arch 0x{elf.e_machine:X}",
                optional=self.optional,
            )

        text_bounds = elf.section_bounds(".text")
        hit = find_first(data, pattern, text_bounds)
        if hit < 0 and text_bounds is not None:
            hit = find_first(data, pattern, None)

        offset = hit + anchor
        if hit < 0 or offset < 0 or (offset + len(stub)) > len(data):
            return BinaryPatchResult(
                name=self.name,
                ok=False,
                already_patched=False,
                offset=-1,
                detail="pattern signature not found",
                optional=self.optional,
            )

        if bytes(data[offset:offset + len(stub)]) == stub:
            return BinaryPatchResult(
                name=self.name,
                ok=True,
                already_patched=True,
                offset=offset,
                detail=f"already patched ({self.desc})",
                optional=self.optional,
            )

        data[offset:offset + len(stub)] = stub
        return BinaryPatchResult(
            name=self.name,
            ok=True,
            already_patched=False,
            offset=offset,
            detail=self.desc,
            optional=self.optional,
        )
