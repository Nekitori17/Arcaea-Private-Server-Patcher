#pragma once

#include <cstddef>

namespace Ext::Config {

constexpr size_t kMaxConfigPath = 512;

bool resolve_config_path(const char *filename, char *out_path, size_t out_size);

} // namespace Ext::Config
