"""IDA-style wildcard pattern matching over binary buffers."""

from __future__ import annotations

from dataclasses import dataclass
from typing import List, Tuple


@dataclass(frozen=True)
class Pattern:
    raw: bytes
    mask: bytes

    def __len__(self) -> int:
        return len(self.raw)


def parse_pattern(pattern_str: str) -> Pattern:
    """Parses 'AA BB ?? CC' or continuous hex into a Pattern with wildcard mask."""
    raw = bytearray()
    mask = bytearray()
    tokens = pattern_str.split()
    if len(tokens) == 1 and "?" not in tokens[0] and len(tokens[0]) % 2 == 0:
        data = bytes.fromhex(tokens[0])
        return Pattern(data, b"\xFF" * len(data))

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


def find_all(buf: bytes | bytearray, pattern: Pattern | str,
             bounds: Tuple[int, int] | None = None) -> List[int]:
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


def find_first(buf: bytes | bytearray, pattern: Pattern | str,
               bounds: Tuple[int, int] | None = None) -> int:
    hits = find_all(buf, pattern, bounds)
    return hits[0] if hits else -1
