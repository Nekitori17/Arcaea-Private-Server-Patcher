"""Structured diagnostic records and pipeline summary reporting."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List

from arcaea_patcher.utils.logger import Logger


@dataclass(frozen=True)
class Record:
    stage: str
    name: str
    target: str
    ok: bool
    detail: str = ""
    optional: bool = False


@dataclass
class Report:
    records: List[Record] = field(default_factory=list)

    def add(
        self,
        stage: str,
        name: str,
        target: str,
        ok: bool,
        detail: str = "",
        optional: bool = False,
    ) -> None:
        self.records.append(Record(stage, name, target, ok, detail, optional))

    @property
    def ok(self) -> bool:
        return all(r.ok or r.optional for r in self.records)

    def print_summary(self, log: Logger) -> None:
        log.header("Patch Pipeline Summary")
        applied = sum(1 for r in self.records if r.ok)
        skipped_opt = sum(1 for r in self.records if not r.ok and r.optional)
        failed = sum(1 for r in self.records if not r.ok and not r.optional)

        log.info(
            f"Total checks: {len(self.records)} | Applied: {applied} | "
            f"Optional-Skipped: {skipped_opt} | Failed: {failed}"
        )

        for r in self.records:
            suffix = f" ({r.detail})" if r.detail else ""
            if r.ok:
                log.detail(f"[OK]   {r.stage:<10} :: {r.name:<28} -> {r.target}{suffix}")
            elif r.optional:
                log.detail(f"[SKIP] {r.stage:<10} :: {r.name:<28} -> {r.target}{suffix}")
            else:
                log.error(f"[FAIL] {r.stage:<10} :: {r.name:<28} -> {r.target}{suffix}")
