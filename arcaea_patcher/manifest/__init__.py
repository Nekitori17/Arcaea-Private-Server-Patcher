"""AndroidManifest.xml and Network Security Config manipulation subsystem."""

from arcaea_patcher.manifest.app_label_renamer import rename_app_label
from arcaea_patcher.manifest.network_security import inject_network_security_config
from arcaea_patcher.manifest.package_renamer import rename_apk_package
from arcaea_patcher.manifest.saf_provider import inject_saf_documents_provider
from arcaea_patcher.manifest.xml_editor import ANDROID_NS, ManifestXmlEditor, android_attr

__all__ = [
    "ANDROID_NS",
    "ManifestXmlEditor",
    "android_attr",
    "inject_network_security_config",
    "inject_saf_documents_provider",
    "rename_apk_package",
    "rename_app_label",
]

