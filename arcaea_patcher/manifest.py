"""Unified AndroidManifest.xml and application resources editor."""

from __future__ import annotations

from pathlib import Path
import re
from typing import Optional, Set, Tuple
import xml.etree.ElementTree as ET

ANDROID_NS = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", ANDROID_NS)

LAUNCHER_CATEGORY = "android.intent.category.LAUNCHER"
COMPONENT_TAGS = ("activity", "activity-alias", "service", "receiver", "provider")
SAF_PROVIDER_CLASS = "moe.ext.arc.storage.InternalStorageProvider"
SAF_DOCUMENTS_ACTION = "android.content.action.DOCUMENTS_PROVIDER"

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


def android_attr(local_name: str) -> str:
    return f"{{{ANDROID_NS}}}{local_name}"


class ManifestXmlEditor:
    """Safely parses, inspects, and writes AndroidManifest.xml using ElementTree."""

    def __init__(self, manifest_path: Path):
        self.manifest_path = manifest_path
        self.tree = ET.parse(manifest_path)
        self.root = self.tree.getroot()

    @property
    def package_name(self) -> str:
        return self.root.attrib.get("package", "")

    @property
    def application(self) -> Optional[ET.Element]:
        return self.root.find("application")

    def save(self) -> None:
        self.tree.write(self.manifest_path, encoding="utf-8", xml_declaration=True)


def _scoped_rename(val: str, old_pkg: str, new_pkg: str) -> str:
    if val == old_pkg:
        return new_pkg
    if val.startswith(old_pkg + "."):
        return new_pkg + val[len(old_pkg):]
    return val


def rename_apk_package(decoded_dir: Path, new_pkg: str) -> Tuple[bool, str]:
    """Renames package in AndroidManifest.xml and apktool.yml. Returns (ok, detail)."""
    manifest_path = decoded_dir / "AndroidManifest.xml"
    if not manifest_path.is_file():
        return False, "AndroidManifest.xml not found"

    editor = ManifestXmlEditor(manifest_path)
    old_pkg = editor.package_name
    if not old_pkg:
        return False, "package attribute missing"
    if old_pkg == new_pkg:
        return True, f"already {new_pkg}"

    editor.root.attrib["package"] = new_pkg
    name_attr = android_attr("name")
    auth_attr = android_attr("authorities")
    perm_attr = android_attr("permission")
    target_act_attr = android_attr("targetActivity")

    app = editor.application
    if app is not None:
        for tag in COMPONENT_TAGS:
            for comp in app.findall(tag):
                cname = comp.attrib.get(name_attr, "")
                if cname.startswith("."):
                    comp.attrib[name_attr] = old_pkg + cname
                elif cname and "." not in cname:
                    comp.attrib[name_attr] = f"{old_pkg}.{cname}"

                t_act = comp.attrib.get(target_act_attr, "")
                if t_act.startswith("."):
                    comp.attrib[target_act_attr] = old_pkg + t_act

    renamed_refs = 0
    for elem in editor.root.iter():
        if elem.tag in ("permission", "uses-permission", "uses-permission-sdk-23", "action", "category"):
            val = elem.attrib.get(name_attr, "")
            new_val = _scoped_rename(val, old_pkg, new_pkg)
            if new_val != val:
                elem.attrib[name_attr] = new_val
                renamed_refs += 1

        if perm_attr in elem.attrib:
            val = elem.attrib[perm_attr]
            new_val = _scoped_rename(val, old_pkg, new_pkg)
            if new_val != val:
                elem.attrib[perm_attr] = new_val
                renamed_refs += 1

        if auth_attr in elem.attrib:
            parts = elem.attrib[auth_attr].split(";")
            new_parts = [_scoped_rename(p.strip(), old_pkg, new_pkg) for p in parts]
            joined = ";".join(new_parts)
            if joined != elem.attrib[auth_attr]:
                elem.attrib[auth_attr] = joined
                renamed_refs += 1

    editor.save()

    apktool_yml = decoded_dir / "apktool.yml"
    if apktool_yml.is_file():
        yml_text = apktool_yml.read_text(encoding="utf-8")
        if "renameManifestPackage:" in yml_text:
            yml_text = re.sub(r"renameManifestPackage:\s*.*", f"renameManifestPackage: {new_pkg}", yml_text)
        else:
            yml_text += f"\nrenameManifestPackage: {new_pkg}\n"
        apktool_yml.write_text(yml_text, encoding="utf-8")

    return True, f"{old_pkg} -> {new_pkg} ({renamed_refs} scoped refs updated)"


def _is_launcher_activity(activity_elem: ET.Element, name_attr: str) -> bool:
    for cat in activity_elem.findall("./intent-filter/category"):
        if cat.attrib.get(name_attr) == LAUNCHER_CATEGORY:
            return True
    return False


def rename_app_label(decoded_dir: Path, new_app_name: str) -> Tuple[bool, str]:
    """Updates app display name in AndroidManifest.xml and strings.xml resources."""
    clean_name = new_app_name.strip()
    if not clean_name:
        return False, "empty app_name"

    manifest_path = decoded_dir / "AndroidManifest.xml"
    if not manifest_path.is_file():
        return False, "AndroidManifest.xml not found"

    editor = ManifestXmlEditor(manifest_path)
    app = editor.application
    if app is None:
        return False, "<application> tag missing"

    label_attr = android_attr("label")
    name_attr = android_attr("name")
    string_keys: Set[str] = {"app_name"}

    old_app_label = app.attrib.get(label_attr, "")
    if old_app_label.startswith("@string/"):
        string_keys.add(old_app_label.split("/", 1)[1])
    app.attrib[label_attr] = clean_name

    updated_activities = 0
    for act in app.findall("activity"):
        act_label = act.attrib.get(label_attr, "")
        if act_label.startswith("@string/"):
            string_keys.add(act_label.split("/", 1)[1])
        if _is_launcher_activity(act, name_attr) or act_label:
            act.attrib[label_attr] = clean_name
            updated_activities += 1

    editor.save()

    updated_strings = 0
    for strings_xml in sorted(decoded_dir.glob("res/values*/strings.xml")):
        try:
            tree = ET.parse(strings_xml)
            root = tree.getroot()
            changed = False
            for str_elem in root.findall("string"):
                if str_elem.attrib.get("name") in string_keys:
                    if str_elem.text != clean_name:
                        str_elem.text = clean_name
                        changed = True
                        updated_strings += 1
            if changed:
                tree.write(strings_xml, encoding="utf-8", xml_declaration=True)
        except Exception:
            continue

    return True, f"'{clean_name}' ({updated_activities} activity label(s), {updated_strings} strings.xml entry(s))"


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
        if prov.attrib.get(name_attr) == SAF_PROVIDER_CLASS:
            return True
        for action in prov.findall("./intent-filter/action"):
            if action.attrib.get(name_attr) == SAF_DOCUMENTS_ACTION:
                return True

    provider = ET.SubElement(app, "provider", {
        android_attr("name"): SAF_PROVIDER_CLASS,
        android_attr("authorities"): f"{pkg}.documents",
        android_attr("exported"): "true",
        android_attr("grantUriPermissions"): "true",
        android_attr("permission"): "android.permission.MANAGE_DOCUMENTS",
    })
    intent_filter = ET.SubElement(provider, "intent-filter")
    ET.SubElement(intent_filter, "action", {
        android_attr("name"): SAF_DOCUMENTS_ACTION,
    })
    ET.SubElement(provider, "grant-uri-permission", {
        android_attr("pathPattern"): ".*",
    })

    editor.save()
    return True

