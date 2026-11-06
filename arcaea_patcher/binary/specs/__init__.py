"""Registry of all binary patch specifications."""

from __future__ import annotations

from typing import List

from arcaea_patcher.binary.base import BinaryPatchSpec
from arcaea_patcher.binary.specs.curl_pin_bypass import specs as curl_pin_specs
from arcaea_patcher.binary.specs.openssl_verify_bypass import specs as openssl_specs


def all_binary_specs() -> List[BinaryPatchSpec]:
    return [
        *openssl_specs(),
        *curl_pin_specs(),
    ]
