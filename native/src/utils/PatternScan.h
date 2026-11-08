#pragma once

#include <cstddef>

#include "PatternDefine.h"

namespace Ext::Utils {

/**
 * Scans a memory buffer for a byte pattern with optional wildcards (e.g., "AA BB ?? CC").
 *
 * @param base Starting address in memory.
 * @param size Number of bytes to scan.
 * @param pattern_str IDA-style hex pattern with spaces and optional '?' or '??' wildcards.
 * @return Pointer to first match or nullptr if not found.
 */
void *scan_pattern(const void *base, size_t size, const char *pattern_str);

/**
 * Scans an entire loaded module in memory using a multi-arch pattern definition.
 * Automatically detects the current compiled CPU architecture (ARM64 vs ARM32).
 *
 * @param module_name Name of the loaded library (e.g., "libcocos2dcpp.so").
 * @param pattern ArchPattern struct defining patterns for both 32-bit and 64-bit.
 * @return Address of first match or nullptr if not found or unsupported architecture.
 */
void *scan_module_pattern(const char *module_name, const Ext::Patterns::ArchPattern &pattern);

} // namespace Ext::Utils
