"""Modular APK Security and Routing Patcher."""

from arcaea_patcher.config import FeaturesConfig, PatchConfig, ServerRoutingConfig, SigningConfig
from arcaea_patcher.core.engine import PatchEngine
from arcaea_patcher.core.toolchain import ApkToolchain
from arcaea_patcher.utils.logger import logger

PatchPipeline = PatchEngine

__version__ = "3.0.0"

__all__ = [
    "PatchConfig",
    "ServerRoutingConfig",
    "FeaturesConfig",
    "SigningConfig",
    "PatchEngine",
    "PatchPipeline",
    "ApkToolchain",
    "logger",
]
