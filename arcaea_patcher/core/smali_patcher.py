from pathlib import Path
import re
from typing import List, Tuple

from arcaea_patcher.utils.logger import logger


class SmaliPatcher:
    """Patches Smali bytecode for Java-level SSL bypass and native hook loading."""

    _NEUTRAL_BODIES = {
        "V": "    .locals 0\n    return-void\n",
        "Z": "    .locals 1\n    const/4 v0, 0x1\n    return v0\n",
        "I": "    .locals 1\n    const/4 v0, 0x1\n    return v0\n",
    }

    def __init__(self, decoded_dir: Path):
        self.decoded_dir = decoded_dir

    def _replace_method_body(self, content: str, method_name: str) -> Tuple[str, int, str]:
        """Replaces method body with neutral return instruction."""
        pattern = re.compile(
            rf"(\.method\s+[^\n]*\b{re.escape(method_name)}\([^\n]*\)([^\s\r\n]+)\r?\n)"
            r"(.*?)"
            r"(\.end method)",
            re.DOTALL,
        )

        patched = 0
        skipped: List[str] = []

        def _replace(match: re.Match) -> str:
            nonlocal patched
            header, ret_type, _body, footer = match.groups()
            if re.search(r"\b(?:native|abstract)\b", header):
                skipped.append("native/abstract method")
                return match.group(0)
            replacement = self._NEUTRAL_BODIES.get(ret_type)
            if replacement is None:
                skipped.append(f"unsupported return type '{ret_type}'")
                return match.group(0)
            patched += 1
            return f"{header}{replacement}{footer}"

        new_content = pattern.sub(_replace, content)
        return new_content, patched, "; ".join(sorted(set(skipped)))

    def patch_ssl_pinning(self) -> None:
        """Neutralizes Java verification in Cocos2dxHttpURLConnection and AsyncHttpClient."""
        smali_files = list(self.decoded_dir.glob("**/Cocos2dxHttpURLConnection.smali"))
        if not smali_files:
            logger.warn("Cocos2dxHttpURLConnection.smali not found; skipping Java SSL patch")
        else:
            target_methods = ["setVerifySSL", "verifySSLPins"]
            for path in smali_files:
                content = path.read_text(encoding="utf-8")
                changed = False
                rel = path.relative_to(self.decoded_dir)

                for method in target_methods:
                    content, patched, note = self._replace_method_body(content, method)
                    if patched:
                        logger.success(f"Patched Java {method} ({patched} overload(s)) in {rel}")
                        if note:
                            logger.warn(f"Untouched in {method}: {note}")
                        changed = True
                    else:
                        logger.warn(f"Could not patch {method} in {rel}: {note or 'not found'}")

                if changed:
                    path.write_text(content, encoding="utf-8")

        self._patch_async_http_client_ssl()

    def _patch_async_http_client_ssl(self) -> None:
        """Forces AsyncHttpClient.getDefaultSchemeRegistry to always use MySSLSocketFactory."""
        for path in self.decoded_dir.glob("**/com/loopj/android/http/AsyncHttpClient.smali"):
            content = path.read_text(encoding="utf-8")
            rel = path.relative_to(self.decoded_dir)

            method_match = re.search(
                r"(\.method\s+[^\n]*\bgetDefaultSchemeRegistry\(ZII\)Lcz/msebera/android/httpclient/conn/scheme/SchemeRegistry;\r?\n)"
                r"(.*?)"
                r"(\.end method)",
                content,
                re.DOTALL,
            )
            if not method_match:
                logger.warn(f"getDefaultSchemeRegistry not found in {rel}")
                continue

            header, body, footer = method_match.groups()
            force_fix = "    const/4 p0, 0x1\n"
            if force_fix.strip() in (line.strip() for line in body.splitlines()[:6]):
                logger.detail(f"AsyncHttpClient SSL already patched in {rel}")
                continue

            reg_match = re.search(r"(\s*\.(?:locals|registers)\s+\d+\r?\n)", body)
            if reg_match:
                new_body = body.replace(reg_match.group(1), reg_match.group(1) + force_fix, 1)
            else:
                new_body = force_fix + body

            content = content.replace(method_match.group(0), f"{header}{new_body}{footer}", 1)
            path.write_text(content, encoding="utf-8")
            logger.success(f"Patched AsyncHttpClient SSL (MySSLSocketFactory) in {rel}")

    def inject_downloader_url_rewriter(self) -> int:
        """Injects DomainUrlRewriter.rewriteUrl() into Java HTTP/Downloader entrypoints."""
        injected = 0

        # 1. Cocos2dxDownloader.createTask(..., String url, String path) -> p2 is url
        for path in self.decoded_dir.glob("**/org/cocos2dx/lib/Cocos2dxDownloader.smali"):
            if self._inject_param_rewrite(
                path,
                r"createTask\(Lorg/cocos2dx/lib/Cocos2dxDownloader;ILjava/lang/String;Ljava/lang/String;\)V",
                "p2",
            ):
                logger.success(f"Injected DomainUrlRewriter into {path.relative_to(self.decoded_dir)} (createTask)")
                injected += 1

        # 2. AsyncHttpClient.getUrlWithQueryString(boolean, String url, RequestParams) -> p1 is url
        #    and AsyncHttpClient.getURI(String url) -> p1 is url (instance method: p0=this, p1=url)
        for path in self.decoded_dir.glob("**/com/loopj/android/http/AsyncHttpClient.smali"):
            c1 = self._inject_param_rewrite(
                path,
                r"getUrlWithQueryString\(ZLjava/lang/String;Lcom/loopj/android/http/RequestParams;\)Ljava/lang/String;",
                "p1",
            )
            c2 = self._inject_param_rewrite(
                path,
                r"getURI\(Ljava/lang/String;\)Ljava/net/URI;",
                "p1",
            )
            if c1 or c2:
                logger.success(f"Injected DomainUrlRewriter into {path.relative_to(self.decoded_dir)}")
                injected += 1

        # 3. MyRedirectHandler.getLocationURI(HttpResponse, HttpContext) -> rewrite Location header value
        for path in self.decoded_dir.glob("**/com/loopj/android/http/MyRedirectHandler.smali"):
            if self._inject_redirect_location_rewrite(path):
                logger.success(f"Injected DomainUrlRewriter into {path.relative_to(self.decoded_dir)} (getLocationURI)")
                injected += 1

        # 4. Cocos2dxHttpURLConnection.createHttpURLConnection(String linkURL) -> p0 is linkURL
        for path in self.decoded_dir.glob("**/org/cocos2dx/lib/Cocos2dxHttpURLConnection.smali"):
            if self._inject_param_rewrite(
                path,
                r"createHttpURLConnection\(Ljava/lang/String;\)Ljava/net/HttpURLConnection;",
                "p0",
            ):
                logger.success(f"Injected DomainUrlRewriter into {path.relative_to(self.decoded_dir)} (createHttpURLConnection)")
                injected += 1

        return injected

    def _inject_param_rewrite(self, path: Path, method_sig_regex: str, param_reg: str) -> bool:
        """Injects DomainUrlRewriter.rewriteUrl(param_reg) at the start of a Smali method."""
        content = path.read_text(encoding="utf-8")
        pattern = re.compile(
            rf"(\.method\s+[^\n]*\b{method_sig_regex}\r?\n)(.*?)(\.end method)",
            re.DOTALL,
        )
        match = pattern.search(content)
        if not match:
            return False

        header, body, footer = match.groups()
        if "Lmoe/neki/arc/DomainUrlRewriter;->rewriteUrl" in body:
            return True

        rewrite_call = (
            f"    invoke-static {{{param_reg}}}, "
            f"Lmoe/neki/arc/DomainUrlRewriter;->rewriteUrl(Ljava/lang/String;)Ljava/lang/String;\n"
            f"    move-result-object {param_reg}\n"
        )
        reg_match = re.search(r"(\s*\.(?:locals|registers)\s+\d+\r?\n)", body)
        if reg_match:
            new_body = body.replace(reg_match.group(1), reg_match.group(1) + rewrite_call, 1)
        else:
            new_body = rewrite_call + body

        content = content.replace(match.group(0), f"{header}{new_body}{footer}", 1)
        path.write_text(content, encoding="utf-8")
        return True

    def _inject_redirect_location_rewrite(self, path: Path) -> bool:
        """Rewrites HTTP 301/302/307 Location header inside MyRedirectHandler.getLocationURI."""
        content = path.read_text(encoding="utf-8")
        if "Lmoe/neki/arc/DomainUrlRewriter;->rewriteUrl" in content:
            return True

        target_pattern = re.compile(
            r"(invoke-interface\s+\{v0\},\s+Lcz/msebera/android/httpclient/Header;->getValue\(\)Ljava/lang/String;\s*\r?\n"
            r"\s*move-result-object\s+v0\r?\n)"
        )
        match = target_pattern.search(content)
        if not match:
            return False

        hook_snippet = (
            match.group(1)
            + "\n    invoke-static {v0}, Lmoe/neki/arc/DomainUrlRewriter;->rewriteUrl(Ljava/lang/String;)Ljava/lang/String;\n"
            + "    move-result-object v0\n"
        )
        content = content.replace(match.group(1), hook_snippet, 1)
        path.write_text(content, encoding="utf-8")
        return True

    def inject_domain_hook_loader(self) -> bool:
        """Injects NekiLoader.init() into primary Activity onCreate()."""
        hook_call = "    invoke-static/range {p0 .. p0}, Lmoe/neki/arc/NekiLoader;->init(Landroid/content/Context;)V\n"
        candidates = ["**/AppActivity.smali", "**/MainActivity.smali", "**/Cocos2dxActivity.smali"]

        for pattern in candidates:
            for path in self.decoded_dir.glob(pattern):
                content = path.read_text(encoding="utf-8")
                if "Lmoe/neki/arc/NekiLoader;->init" in content:
                    logger.detail(f"NekiLoader already present in {path.name}")
                    return True

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
                    new_body = body.replace(super_match.group(1), super_match.group(1) + hook_call, 1)
                else:
                    reg_match = re.search(r"(\s*\.(?:locals|registers)\s+\d+\r?\n)", body)
                    if reg_match:
                        new_body = body.replace(reg_match.group(1), reg_match.group(1) + hook_call, 1)
                    else:
                        new_body = hook_call + body

                content = content.replace(method_match.group(0), f"{header}{new_body}{footer}", 1)
                path.write_text(content, encoding="utf-8")
                logger.success(f"Injected NekiLoader into {path.relative_to(self.decoded_dir)}")
                return True

        logger.warn("No suitable Activity found to inject NekiLoader")
        return False