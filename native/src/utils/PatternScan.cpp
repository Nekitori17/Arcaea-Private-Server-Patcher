#include "PatternScan.h"

#include <cctype>
#include <cstdlib>
#include <cstring>

#include "MemoryUtils.h"

#define LOG_MODULE_TAG "PatternScan"
#include "Logger.h"

namespace Ext::Utils {

namespace {

constexpr size_t kMaxPatternLength = 128;

int parse_pattern(const char *pattern_str, uint8_t *out_pat, uint8_t *out_mask,
                  size_t max_len) {
  if (!pattern_str || !out_pat || !out_mask || max_len == 0)
    return 0;

  size_t count = 0;
  const char *p = pattern_str;

  while (*p && count < max_len) {
    while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n')
      p++;
    if (!*p)
      break;

    if (*p == '?') {
      out_pat[count] = 0x00;
      out_mask[count] = 0x00;
      count++;
      p++;
      if (*p == '?')
        p++;
    } else if (isxdigit(static_cast<unsigned char>(p[0])) &&
               isxdigit(static_cast<unsigned char>(p[1]))) {
      char hex[3] = {p[0], p[1], '\0'};
      out_pat[count] = static_cast<uint8_t>(strtoul(hex, nullptr, 16));
      out_mask[count] = 0xFF;
      count++;
      p += 2;
    } else {
      p++;
    }
  }

  return static_cast<int>(count);
}

} // namespace

void *scan_pattern(const void *base, size_t size, const char *pattern_str) {
  if (!base || size == 0 || !pattern_str)
    return nullptr;

  uint8_t pat[kMaxPatternLength];
  uint8_t mask[kMaxPatternLength];
  int pat_len = parse_pattern(pattern_str, pat, mask, sizeof(pat));
  if (pat_len <= 0 || size < static_cast<size_t>(pat_len))
    return nullptr;

  const auto *start = static_cast<const uint8_t *>(base);
  const auto *end = start + size - pat_len;

  const uint8_t first_byte = pat[0];
  const uint8_t first_mask = mask[0];

  for (const uint8_t *curr = start; curr <= end; curr++) {
    if (first_mask && *curr != first_byte)
      continue;

    bool match = true;
    for (int i = 1; i < pat_len; i++) {
      if (mask[i] && curr[i] != pat[i]) {
        match = false;
        break;
      }
    }

    if (match) {
      return const_cast<void *>(static_cast<const void *>(curr));
    }
  }

  return nullptr;
}

void *scan_module_pattern(const char *module_name,
                          const Ext::Patterns::ArchPattern &pattern) {
  if (!module_name)
    return nullptr;

  const char *arch_pattern = pattern.current();
  const char *arch_name = Ext::Patterns::ArchPattern::current_arch_name();
  const char *pat_name = pattern.name ? pattern.name : "unnamed";

  if (!arch_pattern) {
    LOGE("Unsupported CPU architecture (%s) for pattern '%s'", arch_name, pat_name);
    return nullptr;
  }

  void *base = find_module_base(module_name);
  if (!base) {
    LOGE("Module %s not found in memory map", module_name);
    return nullptr;
  }

  size_t size = find_module_size(module_name);
  if (size == 0) {
    LOGW("Could not determine size of %s; falling back to 32MB scan", module_name);
    size = 32 * 1024 * 1024;
  }

  LOGI("Scanning %s for '%s' (%s, base=%p, size=0x%zx)...", module_name, pat_name,
       arch_name, base, size);

  void *match = scan_pattern(base, size, arch_pattern);
  if (match) {
    auto off = reinterpret_cast<uintptr_t>(match) - reinterpret_cast<uintptr_t>(base);
    LOGI("Pattern '%s' matched at %p (offset +0x%zx)", pat_name, match, off);
  } else {
    LOGW("Pattern '%s' yielded no matches in %s", pat_name, module_name);
  }

  return match;
}

} // namespace Ext::Utils
