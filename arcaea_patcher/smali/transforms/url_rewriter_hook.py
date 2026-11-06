"""Injects DomainUrlRewriter.rewriteUrl() into Java HTTP/Downloader entrypoints."""

from __future__ import annotations

from pathlib import Path
import re
from typing import List

from arcaea_patcher.smali.base import (
    SmaliTransform,
    SmaliTransformResult,
    inject_param_static_filter,
)

REWRITER_DESCRIPTOR = "Lmoe/ext/arc/network/DomainUrlRewriter;->rewriteUrl(Ljava/lang/String;)Ljava/lang/String;"


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
