"""Concrete Smali transformation specifications for entry loader, URL rewriter, and SSL bypass."""

from __future__ import annotations

from pathlib import Path
import re
from typing import List

from arcaea_patcher.smali.transformer import (
    SmaliTransform,
    SmaliTransformResult,
    inject_param_static_filter,
    replace_method_with_neutral_return,
)

ENTRY_CALL_SNIPPET = "    invoke-static/range {p0 .. p0}, Lmoe/ext/arc/ExtEntry;->init(Landroid/content/Context;)V\n"
CANDIDATE_ACTIVITIES = (
    "**/AppActivity.smali",
    "**/MainActivity.smali",
    "**/Cocos2dxActivity.smali",
)
REWRITER_DESCRIPTOR = "Lmoe/ext/arc/network/DomainUrlRewriter;->rewriteUrl(Ljava/lang/String;)Ljava/lang/String;"


class EntryLoaderHookTransform(SmaliTransform):
    """Injects ExtEntry.init(p0) immediately after super.onCreate() in primary Activity."""

    name = "smali-ext-entry-loader"

    def apply(self, decoded_dir: Path) -> List[SmaliTransformResult]:
        for pattern in CANDIDATE_ACTIVITIES:
            for path in decoded_dir.glob(pattern):
                rel = path.relative_to(decoded_dir).as_posix()
                content = path.read_text(encoding="utf-8")

                if "Lmoe/ext/arc/ExtEntry;->init" in content:
                    return [SmaliTransformResult(self.name, rel, True, 1, "already injected")]

                method_match = re.search(
                    r"(\.method\s+[^\n]*onCreate\(Landroid/os/Bundle;\)V\r?\n)(.*?)(\.end method)",
                    content,
                    re.DOTALL,
                )
                if not method_match:
                    continue

                header, body, footer = method_match.groups()
                super_match = re.search(
                    r"(invoke-super(?:/range)?\s+\{[^\}]+\},\s+L[^\n]+;->onCreate\(Landroid/os/Bundle;\)V\r?\n)",
                    body,
                )

                if super_match:
                    new_body = body.replace(super_match.group(1), super_match.group(1) + ENTRY_CALL_SNIPPET, 1)
                else:
                    reg_match = re.search(r"(\s*\.(?:locals|registers)\s+\d+\r?\n)", body)
                    if reg_match:
                        new_body = body.replace(reg_match.group(1), reg_match.group(1) + ENTRY_CALL_SNIPPET, 1)
                    else:
                        new_body = ENTRY_CALL_SNIPPET + body

                content = content.replace(method_match.group(0), f"{header}{new_body}{footer}", 1)
                path.write_text(content, encoding="utf-8")
                return [SmaliTransformResult(self.name, rel, True, 1, "ExtEntry.init injected")]

        return [SmaliTransformResult(self.name, "Activity.smali", False, 0, "no suitable Activity found")]


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


class UrlRewriterHookTransform(SmaliTransform):
    """Hooks Cocos2dxDownloader, AsyncHttpClient, MyRedirectHandler, and Cocos2dxHttpURLConnection."""

    name = "smali-url-rewriter"

    def apply(self, decoded_dir: Path) -> List[SmaliTransformResult]:
        results: List[SmaliTransformResult] = []

        # 1. Cocos2dxDownloader.createTask(..., String url, String path) -> p2 is url
        for path in decoded_dir.glob("**/org/cocos2dx/lib/Cocos2dxDownloader.smali"):
            rel = path.relative_to(decoded_dir).as_posix()
            ok = inject_param_static_filter(
                path,
                r"createTask\(Lorg/cocos2dx/lib/Cocos2dxDownloader;ILjava/lang/String;Ljava/lang/String;\)V",
                "p2",
                REWRITER_DESCRIPTOR,
            )
            results.append(SmaliTransformResult(f"{self.name}:createTask", rel, ok, 1 if ok else 0, "p2 url rewrite"))

        # 2. AsyncHttpClient.getUrlWithQueryString & getURI -> p1 is url
        for path in decoded_dir.glob("**/com/loopj/android/http/AsyncHttpClient.smali"):
            rel = path.relative_to(decoded_dir).as_posix()
            c1 = inject_param_static_filter(
                path,
                r"getUrlWithQueryString\(ZLjava/lang/String;Lcom/loopj/android/http/RequestParams;\)Ljava/lang/String;",
                "p1",
                REWRITER_DESCRIPTOR,
            )
            c2 = inject_param_static_filter(
                path,
                r"getURI\(Ljava/lang/String;\)Ljava/net/URI;",
                "p1",
                REWRITER_DESCRIPTOR,
            )
            count = int(c1) + int(c2)
            results.append(SmaliTransformResult(f"{self.name}:AsyncHttpClient", rel, count > 0, count, f"{count} entrypoint(s)"))

        # 3. MyRedirectHandler.getLocationURI -> Location header rewrite
        for path in decoded_dir.glob("**/com/loopj/android/http/MyRedirectHandler.smali"):
            rel = path.relative_to(decoded_dir).as_posix()
            ok = self._inject_redirect_location(path)
            results.append(SmaliTransformResult(f"{self.name}:MyRedirectHandler", rel, ok, 1 if ok else 0, "Location header rewrite"))

        # 4. Cocos2dxHttpURLConnection.createHttpURLConnection(String linkURL) -> p0 is linkURL
        for path in decoded_dir.glob("**/org/cocos2dx/lib/Cocos2dxHttpURLConnection.smali"):
            rel = path.relative_to(decoded_dir).as_posix()
            ok = inject_param_static_filter(
                path,
                r"createHttpURLConnection\(Ljava/lang/String;\)Ljava/net/HttpURLConnection;",
                "p0",
                REWRITER_DESCRIPTOR,
            )
            results.append(SmaliTransformResult(f"{self.name}:HttpURLConnection", rel, ok, 1 if ok else 0, "p0 linkURL rewrite"))

        return results

    @staticmethod
    def _inject_redirect_location(path: Path) -> bool:
        content = path.read_text(encoding="utf-8")
        if REWRITER_DESCRIPTOR in content:
            return True

        target_re = re.compile(
            r"(invoke-interface\s+\{v0\},\s+Lcz/msebera/android/httpclient/Header;->getValue\(\)Ljava/lang/String;\s*\r?\n"
            r"\s*move-result-object\s+v0\r?\n)"
        )
        match = target_re.search(content)
        if not match:
            return False

        snippet = (
            match.group(1)
            + f"\n    invoke-static {{v0}}, {REWRITER_DESCRIPTOR}\n"
            + "    move-result-object v0\n"
        )
        content = content.replace(match.group(1), snippet, 1)
        path.write_text(content, encoding="utf-8")
        return True


def ssl_bypass_transforms() -> List[SmaliTransform]:
    return [
        CocosHttpSslBypassTransform(),
        AsyncHttpSslBypassTransform(),
    ]

