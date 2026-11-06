#pragma once

#include <cstddef>
#include <cstdint>

namespace Ext::Utils {

void *find_module_base(const char *module_name);

size_t find_module_size(const char *module_name);

bool make_pages_writable(void *addr, size_t size);

void flush_instruction_cache(void *addr, size_t size);

} // namespace Ext::Utils
