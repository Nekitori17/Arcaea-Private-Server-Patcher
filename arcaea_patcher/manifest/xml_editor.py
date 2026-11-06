"""ElementTree-based AndroidManifest.xml parser and writer."""

from __future__ import annotations

from pathlib import Path
from typing import Optional
import xml.etree.ElementTree as ET

ANDROID_NS = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", ANDROID_NS)


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
