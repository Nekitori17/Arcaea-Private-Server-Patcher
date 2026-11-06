"""Registry of Smali bytecode transformations."""

from __future__ import annotations

from typing import List

from arcaea_patcher.smali.base import SmaliTransform
from arcaea_patcher.smali.transforms.entry_loader_hook import EntryLoaderHookTransform
from arcaea_patcher.smali.transforms.ssl_pinning_bypass import (
    AsyncHttpSslBypassTransform,
    CocosHttpSslBypassTransform,
)
from arcaea_patcher.smali.transforms.url_rewriter_hook import UrlRewriterHookTransform


def ssl_bypass_transforms() -> List[SmaliTransform]:
    return [
        CocosHttpSslBypassTransform(),
        AsyncHttpSslBypassTransform(),
    ]


__all__ = [
    "EntryLoaderHookTransform",
    "UrlRewriterHookTransform",
    "CocosHttpSslBypassTransform",
    "AsyncHttpSslBypassTransform",
    "ssl_bypass_transforms",
]
