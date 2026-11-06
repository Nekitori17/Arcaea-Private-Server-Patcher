#!/usr/bin/env python3
"""Generate self-signed RSA-2048 X.509 certificate and private key with SANs for private server TLS."""

from __future__ import annotations

import datetime
import ipaddress
from pathlib import Path
from typing import Optional

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
import yaml


def _strip_port(host_or_ip: str) -> str:
    val = host_or_ip.strip()
    if val.startswith("[") and "]" in val:
        return val[1:val.index("]")]
    if val.count(":") == 1:
        return val.rsplit(":", 1)[0]
    return val


def load_server_hosts_from_config(config_path: str = "config.yml") -> list[str]:
    path = Path(config_path)
    if not path.is_file():
        return []

    with open(path, "r", encoding="utf-8") as f:
        raw_cfg = yaml.safe_load(f) or {}

    server_data = raw_cfg.get("server") or {}
    hosts: list[str] = []
    for key in ("api_host", "auth_host"):
        raw = server_data.get(key)
        if raw:
            clean = _strip_port(str(raw))
            if clean and clean not in hosts:
                hosts.append(clean)

    for _, target in (server_data.get("custom_mappings") or {}).items():
        if target:
            clean = _strip_port(str(target))
            if clean and clean not in hosts:
                hosts.append(clean)

    return hosts


def generate_ssl_certificate(
    cert_path: str = "server.pem",
    key_path: str = "server.key",
    server_ip: Optional[str] = None,
    config_path: str = "config.yml",
    days_valid: int = 3650,
) -> None:
    config_hosts = load_server_hosts_from_config(config_path)
    if config_hosts:
        print(f"[*] Loaded hosts from {config_path}: {', '.join(config_hosts)}")

    primary_host = server_ip or (config_hosts[0] if config_hosts else "127.0.0.1")

    print("[*] Generating 2048-bit RSA Private Key...")
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)

    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Arcaea Private Server"),
        x509.NameAttribute(NameOID.COMMON_NAME, primary_host),
    ])

    domains = [
        "localhost",
        "auth-v2.lowiro.com",
        "auth.lowiro.com",
        "arcapi-v4.lowiro.com",
        "arcapi-v3.lowiro.com",
        "arcaea.lowiro.com",
    ]
    ips: list[str] = ["127.0.0.1"]

    for candidate in [primary_host] + config_hosts:
        try:
            ipaddress.ip_address(candidate)
            if candidate not in ips:
                ips.append(candidate)
        except ValueError:
            if candidate not in domains:
                domains.append(candidate)

    alt_names: list[x509.GeneralName] = [x509.DNSName(d) for d in domains]
    for ip_str in ips:
        alt_names.append(x509.IPAddress(ipaddress.ip_address(ip_str)))

    now = datetime.datetime.now(datetime.timezone.utc)
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - datetime.timedelta(days=1))
        .not_valid_after(now + datetime.timedelta(days=days_valid))
        .add_extension(x509.SubjectAlternativeName(alt_names), critical=False)
        .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
        .sign(private_key, hashes.SHA256())
    )

    Path(key_path).write_bytes(
        private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption(),
        )
    )
    Path(cert_path).write_bytes(cert.public_bytes(serialization.Encoding.PEM))

    print(f"[+] Saved Private Key : {Path(key_path).resolve()}")
    print(f"[+] Saved Certificate : {Path(cert_path).resolve()}")
    print(f"    - Valid Domains   : {', '.join(domains)}")
    print(f"    - Valid IPs       : {', '.join(ips)}")


if __name__ == "__main__":
    generate_ssl_certificate()
