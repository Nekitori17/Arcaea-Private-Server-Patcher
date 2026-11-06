#pragma once

#include <cstddef>
#include <cstdio>

namespace Ext::Utils {

bool file_exists(const char *path);

bool read_proc_cmdline(char *buf, size_t max_len);

int read_line(FILE *fp, char *buf, size_t max_len);

} // namespace Ext::Utils
