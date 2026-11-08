"""End-to-end APK Patch Engine orchestrating binary, smali, manifest, and resource stages."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import shutil
import tempfile
from typing import Optional

from arcaea_patcher.binary import ElfBinary, all_binary_specs
from arcaea_patcher.config import PatchConfig
from arcaea_patcher.core.toolchain import ApkToolchain
from arcaea_patcher.manifest import (
    inject_network_security_config,
    inject_saf_documents_provider,
    rename_apk_package,
    rename_app_label,
)
from arcaea_patcher.resources import (
    build_domain_rules,
    merge_baked_templates,
    write_domain_config_asset,
)
from arcaea_patcher.smali import (
    EntryLoaderHookTransform,
    UrlRewriterHookTransform,
    ssl_bypass_transforms,
)
from arcaea_patcher.utils.logger import logger


@dataclass
class PatchContext:
    """Runtime context for an APK patching session."""
    config: PatchConfig
    temp_root: Path
    templates_dir: Path

    @property
    def decoded_dir(self) -> Path:
        return self.temp_root / "decoded"

    @property
    def unaligned_apk(self) -> Path:
        return self.temp_root / "unaligned.apk"


class PatchEngine:
    """Executes the modular APK patching pipeline."""

    def __init__(
        self,
        config: PatchConfig,
        toolchain: ApkToolchain,
        templates_dir: Optional[Path] = None,
    ):
        self.config = config
        self.toolchain = toolchain
        self.templates_dir = templates_dir or (Path(__file__).parent.parent / "templates")

    def execute(self) -> bool:
        logger.header("Starting Arcaea APK Patch Engine")

        if not self.config.input_apk.is_file():
            raise FileNotFoundError(f"Input APK not found: {self.config.input_apk}")

        temp_root = Path(tempfile.mkdtemp(prefix="arc_ext_patcher_"))
        ctx = PatchContext(
            config=self.config,
            temp_root=temp_root,
            templates_dir=self.templates_dir,
        )

        try:
            logger.header("[1/9] Decompiling APK")
            self.toolchain.decompile(ctx.config.input_apk, ctx.decoded_dir)
            logger.success("APK decoded successfully.")

            logger.header("[2/9] Merging Baked Templates")
            merged_files = merge_baked_templates(ctx.templates_dir, ctx.decoded_dir)
            if merged_files:
                logger.success(f"Merged {len(merged_files)} template artifact(s).")
            else:
                logger.warn("No template files found (run scripts/build_templates.py).")

            if ctx.config.package_name or ctx.config.app_name:
                logger.header("[3/9] Updating Package & App Identity")
                if ctx.config.package_name:
                    ok, detail = rename_apk_package(ctx.decoded_dir, ctx.config.package_name)
                    if ok:
                        logger.success(f"Package rename: {detail}")
                    else:
                        logger.warn(f"Package rename failed: {detail}")

                if ctx.config.app_name:
                    ok, detail = rename_app_label(ctx.decoded_dir, ctx.config.app_name)
                    if ok:
                        logger.success(f"App name: {detail}")
                    else:
                        logger.warn(f"App name update failed: {detail}")

            if ctx.config.inject_nsc:
                logger.header("[4/9] Injecting Network Security Config")
                ok = inject_network_security_config(ctx.decoded_dir)
                if ok:
                    logger.success("Bound @xml/network_security_config in AndroidManifest.xml")
                else:
                    logger.warn("Failed to inject Network Security Config")

            if ctx.config.feature_config.expose_internal_data:
                logger.header("[5/9] Injecting SAF InternalStorageProvider")
                ok = inject_saf_documents_provider(ctx.decoded_dir)
                if ok:
                    logger.success("Injected moe.ext.arc.InternalStorageProvider")
                else:
                    logger.warn("Failed to inject SAF DocumentsProvider")

            if ctx.config.server.has_routing:
                logger.header("[6/9] Configuring Dynamic Domain Routing")
                rules = build_domain_rules(ctx.config.server)
                if rules:
                    write_domain_config_asset(ctx.decoded_dir, rules)
                    logger.success(f"Wrote assets/domain.cfg ({len(rules)} rule(s))")

                    for transform in (EntryLoaderHookTransform(), UrlRewriterHookTransform()):
                        for res in transform.apply(ctx.decoded_dir):
                            if res.ok:
                                logger.success(f"{res.name} -> {res.target} ({res.detail})")
                            else:
                                logger.warn(f"{res.name} -> {res.target} ({res.detail})")

            if ctx.config.patch_native_ssl:
                logger.header("[7/9] Patching Native ELF Binaries (.so)")
                self._patch_native_binaries(ctx.decoded_dir)

            if ctx.config.patch_java_ssl:
                logger.header("[8/9] Patching Smali SSL Pinning")
                for transform in ssl_bypass_transforms():
                    for res in transform.apply(ctx.decoded_dir):
                        if res.ok:
                            logger.success(f"{res.name} -> {res.target} ({res.detail})")
                        else:
                            logger.warn(f"{res.name} -> {res.target} ({res.detail})")

            logger.header("[9/9] Rebuilding, Aligning & Signing APK")
            self.toolchain.build(ctx.decoded_dir, ctx.unaligned_apk)
            ctx.config.output_apk.parent.mkdir(parents=True, exist_ok=True)
            self.toolchain.zipalign(ctx.unaligned_apk, ctx.config.output_apk)
            self.toolchain.sign(ctx.config.output_apk, ctx.config.signing)

            logger.header("Done")
            logger.success(f"Patched APK ready: {ctx.config.output_apk.resolve()}")
            return True
        finally:
            shutil.rmtree(temp_root, ignore_errors=True)

    def _patch_native_binaries(self, decoded_dir: Path) -> None:
        so_files = sorted(decoded_dir.glob("lib/**/libcocos2dcpp.so"))
        if not so_files:
            logger.warn("No libcocos2dcpp.so found in decoded APK")
            return

        specs = all_binary_specs()
        for so_path in so_files:
            abi = so_path.parent.name
            data = bytearray(so_path.read_bytes())
            elf = ElfBinary(data)

            modified = 0
            for spec in specs:
                res = spec.apply(data, elf)
                if res.ok:
                    modified += 1
                    logger.success(f"[{abi}] {res.name} @ 0x{res.offset:X} ({res.detail})")
                elif not res.optional:
                    logger.warn(f"[{abi}] {res.name} failed ({res.detail})")

            if modified > 0:
                so_path.write_bytes(data)
