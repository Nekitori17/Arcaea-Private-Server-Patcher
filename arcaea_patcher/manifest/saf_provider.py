"""Injects InternalStorageProvider into AndroidManifest.xml for SAF access."""

from __future__ import annotations

from pathlib import Path
import xml.etree.ElementTree as ET

from arcaea_patcher.manifest.xml_editor import ManifestXmlEditor, android_attr

PROVIDER_CLASS = "moe.ext.arc.storage.InternalStorageProvider"
DOCUMENTS_ACTION = "android.content.action.DOCUMENTS_PROVIDER"


def inject_saf_documents_provider(decoded_dir: Path) -> bool:
    """Adds InternalStorageProvider to <application> if not already present."""
    manifest_path = decoded_dir / "AndroidManifest.xml"
    if not manifest_path.is_file():
        return False

    editor = ManifestXmlEditor(manifest_path)
    app = editor.application
    pkg = editor.package_name
    if app is None or not pkg:
        return False

    name_attr = android_attr("name")
    for prov in app.findall("provider"):
        if prov.attrib.get(name_attr) == PROVIDER_CLASS:
            return True
        for action in prov.findall("./intent-filter/action"):
            if action.attrib.get(name_attr) == DOCUMENTS_ACTION:
                return True

    provider = ET.SubElement(app, "provider", {
        android_attr("name"): PROVIDER_CLASS,
        android_attr("authorities"): f"{pkg}.documents",
        android_attr("exported"): "true",
        android_attr("grantUriPermissions"): "true",
        android_attr("permission"): "android.permission.MANAGE_DOCUMENTS",
    })
    intent_filter = ET.SubElement(provider, "intent-filter")
    ET.SubElement(intent_filter, "action", {
        android_attr("name"): DOCUMENTS_ACTION,
    })
    ET.SubElement(provider, "grant-uri-permission", {
        android_attr("pathPattern"): ".*",
    })

    editor.save()
    return True
