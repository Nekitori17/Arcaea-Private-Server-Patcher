"""ARM machine code stubs, pattern matching engine, and base ELF patch specifications."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Dict, List, Tuple

from arcaea_patcher.binary.elf import ElfBinary

# Architecture constants
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


# --- Pattern Matching ---

@dataclass(frozen=True)
class Pattern:
    raw: bytes
    mask: bytes

    def __len__(self) -> int:
        return len(self.raw)


def parse_pattern(pattern_str: str) -> Pattern:
    """Parses 'AA BB ?? CC' or continuous hex into a Pattern with wildcard mask."""
    tokens = pattern_str.split()
    if len(tokens) == 1 and "?" not in tokens[0] and len(tokens[0]) % 2 == 0:
        data = bytes.fromhex(tokens[0])
        return Pattern(data, b"\xFF" * len(data))

    raw = bytearray()
    mask = bytearray()
    for tok in tokens:
        if tok in ("?", "??"):
            raw.append(0x00)
            mask.append(0x00)
        else:
            raw.append(int(tok, 16))
            mask.append(0xFF)
    return Pattern(bytes(raw), bytes(mask))


def _fixed_runs(pattern: Pattern) -> List[Tuple[int, bytes]]:
    runs: List[Tuple[int, bytes]] = []
    start: int | None = None
    for i, m in enumerate(pattern.mask):
        if m:
            if start is None:
                start = i
        elif start is not None:
            runs.append((start, pattern.raw[start:i]))
            start = None
    if start is not None:
        runs.append((start, pattern.raw[start:]))
    return [r for r in runs if r[1]]


def find_all(
    buf: bytes | bytearray,
    pattern: Pattern | str,
    bounds: Tuple[int, int] | None = None,
) -> List[int]:
    """Returns every buffer offset matching the pattern within optional (lo, hi) bounds."""
    pat = parse_pattern(pattern) if isinstance(pattern, str) else pattern
    n = len(pat)
    lo = bounds[0] if bounds else 0
    hi = min(bounds[1], len(buf)) if bounds else len(buf)

    if n == 0 or (hi - lo) < n:
        return []

    raw, mask = pat.raw, pat.mask
    view = bytes(buf)
    hits: List[int] = []

    if all(mask):
        pos = lo
        while True:
            idx = view.find(raw, pos, hi)
            if idx < 0:
                return hits
            hits.append(idx)
            pos = idx + 1

    runs = _fixed_runs(pat)
    if not runs:
        return []

    anchor_off, anchor = max(runs, key=lambda r: len(r[1]))
    pos = lo + anchor_off
    while True:
        idx = view.find(anchor, pos, hi)
        if idx < 0:
            return hits
        cand = idx - anchor_off
        if cand >= lo and cand + n <= hi:
            if all(not mask[j] or buf[cand + j] == raw[j] for j in range(n)):
                hits.append(cand)
        pos = idx + 1


def find_first(
    buf: bytes | bytearray,
    pattern: Pattern | str,
    bounds: Tuple[int, int] | None = None,
) -> int:
    hits = find_all(buf, pattern, bounds)
    return hits[0] if hits else -1


# --- Patch Specification Bases ---

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


@dataclass
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


@dataclass
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

