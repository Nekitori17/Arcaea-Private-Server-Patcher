"""Renames APK package name, owned permissions/authorities, and apktool.yml metadata."""

from __future__ import annotations

from pathlib import Path
import re
from typing import Tuple

from arcaea_patcher.manifest.xml_editor import ManifestXmlEditor, android_attr

COMPONENT_TAGS = ("activity", "activity-alias", "service", "receiver", "provider")


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
        # Normalize relative component names to old_pkg before renaming package
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
