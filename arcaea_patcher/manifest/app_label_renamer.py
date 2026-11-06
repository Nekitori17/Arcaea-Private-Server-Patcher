"""Renames the application display label in AndroidManifest.xml and res/values*/strings.xml."""

from __future__ import annotations

from pathlib import Path
from typing import Set, Tuple
import xml.etree.ElementTree as ET

from arcaea_patcher.manifest.xml_editor import ManifestXmlEditor, android_attr

LAUNCHER_CATEGORY = "android.intent.category.LAUNCHER"


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

    return (
        True,
        f"'{clean_name}' ({updated_activities} activity label(s), {updated_strings} strings.xml entry(s))",
    )
