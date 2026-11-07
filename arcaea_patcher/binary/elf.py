"""32-bit and 64-bit ELF binary parser for section bounds and dynamic symbols."""

from __future__ import annotations

from dataclasses import dataclass
import struct
from typing import List, Optional, Tuple


@dataclass(frozen=True)
class SectionHeader:
    name_idx: int
    sh_type: int
    sh_flags: int
    sh_addr: int
    sh_offset: int
    sh_size: int
    sh_link: int
    sh_info: int
    sh_addralign: int
    sh_entsize: int


class ElfBinary:
    """Parses ELF headers, sections, and .dynsym symbol offsets."""

    def __init__(self, data: bytes | bytearray):
        self.data = data
        if not self.data.startswith(b"\x7fELF"):
            raise ValueError("Invalid ELF magic header")

        self.ei_class = self.data[4]
        self.ei_data = self.data[5]
        if self.ei_class not in (1, 2) or self.ei_data not in (1, 2):
            raise ValueError("Unsupported ELF class or endianness")

        self.is_64bit = self.ei_class == 2
        self.endian = "<" if self.ei_data == 1 else ">"
        self.e_machine = struct.unpack_from(f"{self.endian}H", self.data, 0x12)[0]
        self.sections: List[SectionHeader] = []
        self.e_shstrndx = 0
        self._parse_sections()

    def _parse_sections(self) -> None:
        shoff_fmt = f"{self.endian}Q" if self.is_64bit else f"{self.endian}I"
        shoff_pos = 0x28 if self.is_64bit else 0x20
        e_shoff = struct.unpack_from(shoff_fmt, self.data, shoff_pos)[0]

        meta_pos = 0x3A if self.is_64bit else 0x2E
        e_shentsize, e_shnum, self.e_shstrndx = struct.unpack_from(
            f"{self.endian}HHH", self.data, meta_pos
        )
        if e_shoff == 0 or e_shnum == 0:
            return

        sec_fmt = f"{self.endian}IIQQQQIIQQ" if self.is_64bit else f"{self.endian}IIIIIIIIII"
        for i in range(e_shnum):
            off = e_shoff + (i * e_shentsize)
            fields = struct.unpack_from(sec_fmt, self.data, off)
            self.sections.append(SectionHeader(*fields))

    def _read_cstr(self, strtab_off: int, strtab_sz: int, index: int) -> str:
        if index >= strtab_sz:
            return ""
        start = strtab_off + index
        end = self.data.find(b"\x00", start, strtab_off + strtab_sz)
        if end == -1:
            end = strtab_off + strtab_sz
        return bytes(self.data[start:end]).decode("ascii", errors="replace")

    def section_bounds(self, section_name: str) -> Optional[Tuple[int, int]]:
        """Returns (file_offset, file_end) for the named section if present."""
        if not self.sections or self.e_shstrndx >= len(self.sections):
            return None
        shstrtab = self.sections[self.e_shstrndx]
        for sec in self.sections:
            name = self._read_cstr(shstrtab.sh_offset, shstrtab.sh_size, sec.name_idx)
            if name == section_name:
                return sec.sh_offset, sec.sh_offset + sec.sh_size
        return None

    def find_dynsym_offset(self, symbol_name: str) -> Optional[Tuple[int, bool]]:
        """Resolves symbol in .dynsym to (file_offset, is_thumb)."""
        if not self.sections or self.e_shstrndx >= len(self.sections):
            return None

        shstrtab = self.sections[self.e_shstrndx]
        dynsym: Optional[SectionHeader] = None
        for sec in self.sections:
            if self._read_cstr(shstrtab.sh_offset, shstrtab.sh_size, sec.name_idx) == ".dynsym":
                dynsym = sec
                break

        if not dynsym or dynsym.sh_link >= len(self.sections):
            return None

        dynstr = self.sections[dynsym.sh_link]
        entry_sz = 24 if self.is_64bit else 16
        count = dynsym.sh_size // entry_sz

        for i in range(count):
            sym_off = dynsym.sh_offset + (i * entry_sz)
            if self.is_64bit:
                st_name, _, _, st_shndx, st_value, _ = struct.unpack_from(
                    f"{self.endian}IBBHQQ", self.data, sym_off
                )
            else:
                st_name, st_value, _, _, _, st_shndx = struct.unpack_from(
                    f"{self.endian}IIIBBH", self.data, sym_off
                )

            if st_shndx == 0 or st_value == 0:
                continue
            if self._read_cstr(dynstr.sh_offset, dynstr.sh_size, st_name) != symbol_name:
                continue

            is_thumb = False
            val = st_value
            if self.e_machine == 0x28 and (val & 1):
                is_thumb = True
                val &= ~1

            for sec in self.sections:
                if sec.sh_addr <= val < (sec.sh_addr + sec.sh_size):
                    return sec.sh_offset + (val - sec.sh_addr), is_thumb
            return None

        return None

