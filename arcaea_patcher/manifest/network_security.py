"""Network Security Config generation and AndroidManifest.xml binding."""

from __future__ import annotations

from pathlib import Path

from arcaea_patcher.manifest.xml_editor import ManifestXmlEditor, android_attr

NSC_XML_CONTENT = """<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
</network-security-config>
"""


def inject_network_security_config(decoded_dir: Path) -> bool:
    """Writes res/xml/network_security_config.xml and binds it on <application>."""
    xml_dir = decoded_dir / "res" / "xml"
    xml_dir.mkdir(parents=True, exist_ok=True)
    nsc_path = xml_dir / "network_security_config.xml"
    nsc_path.write_text(NSC_XML_CONTENT, encoding="utf-8")

    manifest_path = decoded_dir / "AndroidManifest.xml"
    if not manifest_path.is_file():
        return False

    editor = ManifestXmlEditor(manifest_path)
    app = editor.application
    if app is None:
        return False

    attr_key = android_attr("networkSecurityConfig")
    if app.attrib.get(attr_key) != "@xml/network_security_config":
        app.attrib[attr_key] = "@xml/network_security_config"
        editor.save()
    return True
