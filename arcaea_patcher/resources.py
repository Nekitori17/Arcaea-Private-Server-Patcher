"""Manages static resources, domain configuration assets, and template merging."""

from __future__ import annotations

import ipaddress
from pathlib import Path
import re
import shutil
from typing import List, Optional

from arcaea_patcher.config import API_DOMAINS, AUTH_DOMAINS, ServerRoutingConfig
from arcaea_patcher.utils.logger import logger

_CONTROL_OR_QUOTE_RE = re.compile(r'[\x00-\x1f\x7f"]')
_HOSTNAME_RE = re.compile(r"^[A-Za-z0-9._-]+$")


def sanitize_host(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    cleaned = _CONTROL_OR_QUOTE_RE.sub("", value).strip()
    if cleaned != value:
        logger.warn(f"Sanitized host: {value!r} -> {cleaned!r}")
    return cleaned


def is_plausible_host(value: Optional[str]) -> bool:
    if not value:
        return False
    host = value
    if value.startswith("[") and "]" in value:
        host = value[1:value.index("]")]
    elif ":" in value:
        host = value.rsplit(":", 1)[0]
    if not host:
        return False
    try:
        ipaddress.ip_address(host)
        return True
    except ValueError:
        return bool(_HOSTNAME_RE.match(host))


def build_domain_rules(server_cfg: ServerRoutingConfig) -> List[str]:
    lines: List[str] = []
    api_host = sanitize_host(server_cfg.api_host)
    auth_host = sanitize_host(server_cfg.auth_host)

    if api_host and not is_plausible_host(api_host):
        logger.warn(f"api_host '{api_host}' may be malformed")
    if auth_host and not is_plausible_host(auth_host):
        logger.warn(f"auth_host '{auth_host}' may be malformed")

    if api_host:
        for domain in API_DOMAINS:
            lines.append(f"{domain}={api_host}")

    if auth_host:
        for domain in AUTH_DOMAINS:
            lines.append(f"{domain}={auth_host}")

    for orig, target in server_cfg.custom_mappings.items():
        clean_orig = sanitize_host(orig)
        clean_target = sanitize_host(target)
        if clean_orig and clean_target:
            lines.append(f"{clean_orig}={clean_target}")

    return lines


def write_domain_config_asset(decoded_dir: Path, rules: List[str]) -> Path:
    assets_dir = decoded_dir / "assets"
    assets_dir.mkdir(parents=True, exist_ok=True)
    cfg_path = assets_dir / "domain.cfg"
    with open(cfg_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(rules) + "\n")
    return cfg_path


def _resolve_next_smali_dir(decoded_dir: Path) -> Path:
    """Determines the next sequential smali_classes{N} folder in decoded_dir."""
    has_base_smali = (decoded_dir / "smali").is_dir()
    existing_indices = [
        int(m.group(1))
        for d in decoded_dir.iterdir()
        if d.is_dir() and (m := re.match(r"^smali_classes(\d+)$", d.name))
    ]
    if existing_indices:
        next_idx = max(existing_indices) + 1
        return decoded_dir / f"smali_classes{next_idx}"
    if has_base_smali:
        return decoded_dir / "smali_classes2"
    return decoded_dir / "smali"


def merge_baked_templates(templates_dir: Path, decoded_dir: Path) -> List[str]:
    """Copies template libraries and places template Smali into a dedicated DEX folder."""
    if not templates_dir.is_dir():
        return []

    target_smali_dir = _resolve_next_smali_dir(decoded_dir)
    merged: List[str] = []

    for src in sorted(templates_dir.rglob("*")):
        if not src.is_file():
            continue
        rel = src.relative_to(templates_dir)
        parts = rel.parts
        if parts and parts[0].startswith("smali"):
            sub_rel = Path(*parts[1:])
            dst = target_smali_dir / sub_rel
        else:
            dst = decoded_dir / rel

        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        merged.append(dst.relative_to(decoded_dir).as_posix())

    return merged

