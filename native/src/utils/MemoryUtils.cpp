#include "MemoryUtils.h"

#include <cerrno>
#include <cstdio>
#include <cstring>
#include <sys/mman.h>
#include <unistd.h>

#define LOG_MODULE_TAG "Memory"
#include "Logger.h"

namespace Ext::Utils {

namespace {

bool line_matches_module(const char *line, const char *module_name) {
  if (!line || !module_name || module_name[0] == '\0')
    return false;

  const size_t name_len = strlen(module_name);
  const char *p = strstr(line, module_name);

  while (p != nullptr) {
    const bool left_ok = (p == line) || (p[-1] == '/');
    const char *after = p + name_len;
    const bool right_ok = (*after == '\0' || *after == ' ' || *after == '\t' ||
                           *after == '\n' || *after == '-' || *after == ':');
    if (left_ok && right_ok)
      return true;
    if (left_ok && *after == '.' && strncmp(after, ".so", 3) == 0 &&
        (after[3] == '\0' || after[3] == ' ' || after[3] == '\t' ||
         after[3] == '\n'))
      return true;
    p = strstr(p + 1, module_name);
  }
  return false;
}

} // namespace

void *find_module_base(const char *module_name) {
  if (!module_name || module_name[0] == '\0')
    return nullptr;

  FILE *fp = fopen("/proc/self/maps", "r");
  if (!fp) {
    LOGE("Failed to open /proc/self/maps (errno=%d)", errno);
    return nullptr;
  }

  char line[640];
  void *base = nullptr;

  while (fgets(line, sizeof(line), fp)) {
    if (line_matches_module(line, module_name)) {
      unsigned long long start = 0;
      unsigned long long offset = 0;
      char perms[5] = {0};
      if (sscanf(line, "%llx-%*llx %4s %llx", &start, perms, &offset) == 3) {
        if (offset == 0 && start != 0) {
          base = reinterpret_cast<void *>(static_cast<uintptr_t>(start));
          break;
        }
      }
    }
  }

  fclose(fp);
  return base;
}

size_t find_module_size(const char *module_name) {
  if (!module_name || !module_name[0])
    return 0;

  FILE *fp = fopen("/proc/self/maps", "r");
  if (!fp)
    return 0;

  char line[640];
  uintptr_t lo = 0;
  uintptr_t hi = 0;

  while (fgets(line, sizeof(line), fp)) {
    if (line_matches_module(line, module_name)) {
      unsigned long long s = 0;
      unsigned long long e = 0;
      if (sscanf(line, "%llx-%llx", &s, &e) == 2) {
        if (lo == 0 || static_cast<uintptr_t>(s) < lo)
          lo = static_cast<uintptr_t>(s);
        if (static_cast<uintptr_t>(e) > hi)
          hi = static_cast<uintptr_t>(e);
      }
    }
  }

  fclose(fp);
  return (hi > lo) ? static_cast<size_t>(hi - lo) : 0;
}

bool make_pages_writable(void *addr, size_t size) {
  if (!addr || size == 0)
    return false;

  long page_size = sysconf(_SC_PAGESIZE);
  if (page_size <= 0)
    page_size = 4096;

  const auto page_mask = static_cast<uintptr_t>(page_size - 1);
  const uintptr_t page_start = reinterpret_cast<uintptr_t>(addr) & ~page_mask;
  const size_t total =
      (((reinterpret_cast<uintptr_t>(addr) + size - page_start + page_mask) /
        static_cast<size_t>(page_size)) *
       static_cast<size_t>(page_size));

  int ret = mprotect(reinterpret_cast<void *>(page_start), total,
                     PROT_READ | PROT_WRITE);
  if (ret != 0) {
    ret = mprotect(reinterpret_cast<void *>(page_start), total,
                   PROT_READ | PROT_WRITE | PROT_EXEC);
    if (ret != 0) {
      LOGE("mprotect failed at %p (size=%zu, errno=%d)", addr, size, errno);
      return false;
    }
  }
  return true;
}

void flush_instruction_cache(void *addr, size_t size) {
  if (!addr || size == 0)
    return;
  auto *begin = reinterpret_cast<char *>(addr);
  __builtin___clear_cache(begin, begin + size);
}

} // namespace Ext::Utils
