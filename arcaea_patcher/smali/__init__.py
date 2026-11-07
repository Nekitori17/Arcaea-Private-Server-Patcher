"""Modular Smali bytecode transformation subsystem."""

from arcaea_patcher.smali.specs import (
    AsyncHttpSslBypassTransform,
    CocosHttpSslBypassTransform,
    EntryLoaderHookTransform,
    UrlRewriterHookTransform,
    ssl_bypass_transforms,
)
from arcaea_patcher.smali.transformer import (
    NEUTRAL_RETURN_BODIES,
    SmaliTransform,
    SmaliTransformResult,
    inject_param_static_filter,
    replace_method_with_neutral_return,
)

__all__ = [
    "NEUTRAL_RETURN_BODIES",
    "SmaliTransform",
    "SmaliTransformResult",
    "replace_method_with_neutral_return",
    "inject_param_static_filter",
    "EntryLoaderHookTransform",
    "CocosHttpSslBypassTransform",
    "AsyncHttpSslBypassTransform",
    "UrlRewriterHookTransform",
    "ssl_bypass_transforms",
]

