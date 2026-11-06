"""Java-layer SSL pinning and certificate verification bypass transforms."""

from __future__ import annotations

from pathlib import Path
import re
from typing import List

from arcaea_patcher.smali.base import (
    SmaliTransform,
    SmaliTransformResult,
    replace_method_with_neutral_return,
)


class CocosHttpSslBypassTransform(SmaliTransform):
    """Neutralizes setVerifySSL and verifySSLPins in Cocos2dxHttpURLConnection."""

    name = "smali-cocos-http-ssl"
    TARGET_METHODS = ("setVerifySSL", "verifySSLPins")

    def apply(self, decoded_dir: Path) -> List[SmaliTransformResult]:
        files = list(decoded_dir.glob("**/Cocos2dxHttpURLConnection.smali"))
        if not files:
            return [
                SmaliTransformResult(
                    name=self.name,
                    target="Cocos2dxHttpURLConnection.smali",
                    ok=False,
                    sites_modified=0,
                    detail="file not found",
                )
            ]

        results: List[SmaliTransformResult] = []
        for path in files:
            content = path.read_text(encoding="utf-8")
            rel = path.relative_to(decoded_dir).as_posix()
            total_patched = 0

            for method in self.TARGET_METHODS:
                content, count, note = replace_method_with_neutral_return(content, method)
                total_patched += count
                results.append(
                    SmaliTransformResult(
                        name=f"{self.name}:{method}",
                        target=rel,
                        ok=count > 0,
                        sites_modified=count,
                        detail=f"{count} overload(s)" if count else (note or "not found"),
                    )
                )

            if total_patched > 0:
                path.write_text(content, encoding="utf-8")

        return results


class AsyncHttpSslBypassTransform(SmaliTransform):
    """Forces AsyncHttpClient.getDefaultSchemeRegistry to always use MySSLSocketFactory."""

    name = "smali-async-http-ssl"

    def apply(self, decoded_dir: Path) -> List[SmaliTransformResult]:
        files = list(decoded_dir.glob("**/com/loopj/android/http/AsyncHttpClient.smali"))
        if not files:
            return []

        results: List[SmaliTransformResult] = []
        for path in files:
            content = path.read_text(encoding="utf-8")
            rel = path.relative_to(decoded_dir).as_posix()

            match = re.search(
                r"(\.method\s+[^\n]*\bgetDefaultSchemeRegistry\(ZII\)Lcz/msebera/android/httpclient/conn/scheme/SchemeRegistry;\r?\n)"
                r"(.*?)"
                r"(\.end method)",
                content,
                re.DOTALL,
            )
            if not match:
                results.append(
                    SmaliTransformResult(self.name, rel, False, 0, "getDefaultSchemeRegistry not found")
                )
                continue

            header, body, footer = match.groups()
            force_fix = "    const/4 p0, 0x1\n"
            if force_fix.strip() in (line.strip() for line in body.splitlines()[:6]):
                results.append(
                    SmaliTransformResult(self.name, rel, True, 1, "already patched (MySSLSocketFactory)")
                )
                continue

            reg_match = re.search(r"(\s*\.(?:locals|registers)\s+\d+\r?\n)", body)
            if reg_match:
                new_body = body.replace(reg_match.group(1), reg_match.group(1) + force_fix, 1)
            else:
                new_body = force_fix + body

            content = content.replace(match.group(0), f"{header}{new_body}{footer}", 1)
            path.write_text(content, encoding="utf-8")
            results.append(
                SmaliTransformResult(self.name, rel, True, 1, "forced MySSLSocketFactory")
            )

        return results
