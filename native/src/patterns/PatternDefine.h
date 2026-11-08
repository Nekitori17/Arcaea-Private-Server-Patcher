#pragma once

#include <cstddef>
#include <cstdint>

namespace Ext::Patterns {

/**
 * Definition of a byte pattern across multiple CPU architectures (ARM64 & ARM32).
 */
struct ArchPattern {
  const char *name;
  const char *arm64;
  const char *arm32;

  // Returns the pattern string for the currently compiled architecture.
  // Returns nullptr if the current architecture is unsupported.
  constexpr const char *current() const {
#if defined(__aarch64__)
    return arm64;
#elif defined(__arm__)
    return arm32;
#else
    return nullptr;
#endif
  }

  // Returns the architecture name string for logging.
  static constexpr const char *current_arch_name() {
#if defined(__aarch64__)
    return "arm64";
#elif defined(__arm__)
    return "arm32";
#else
    return "unknown";
#endif
  }
};

using PatternDef = ArchPattern;

} // namespace Ext::Patterns

