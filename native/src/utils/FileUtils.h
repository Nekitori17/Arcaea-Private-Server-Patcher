#pragma once

#include <cstddef>
#include <cstdio>

namespace Ext::Utils {

constexpr size_t kMaxPathLength = 512;

bool file_exists(const char *path);

bool read_proc_cmdline(char *buf, size_t max_len);

int read_line(FILE *fp, char *buf, size_t max_len);

bool resolve_app_file_path(const char *filename, char *out_path, size_t out_size);

} // namespace Ext::Utils
