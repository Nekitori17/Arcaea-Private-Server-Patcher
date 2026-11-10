#pragma once

#include "PatternDefine.h"

namespace Ext::Patterns {

// libcurl option constants (CURLoption)
constexpr int kCurlOptUrl = 10002;
constexpr int kCurlOptPinnedPublicKey = 10230;
constexpr int kCurlOptSslVerifyPeer = 64;
constexpr int kCurlOptSslVerifyHost = 81;

// libcurl return code (CURLcode)
constexpr int kCurleOk = 0;

// Unique pattern signatures for curl_easy_setopt in libcocos2dcpp.so:
// - AArch64 (ARM64): 32 bytes (100% unique 1-hit in 7.0.255_64 & 7.1.0_64)
// - ARM32 (A32 mode): 32 bytes (100% unique 1-hit in 7.0.255_32 & 7.1.0_32)
inline constexpr ArchPattern kCurlEasySetoptPattern = {
    "curl_easy_setopt",
    "FF 03 04 D1 FD 7B 0F A9 FD C3 03 91 A2 0F 39 A9 A4 17 3A A9 A6 1F 3B A9 E1 8B 00 AD E3 93 01 AD",
    "08 D0 4D E2 00 48 2D E9 08 D0 4D E2 00 00 50 E3 10 20 8D E5 14 30 8D E5 06 00 00 0A 10 20 8D E2",
};

} // namespace Ext::Patterns