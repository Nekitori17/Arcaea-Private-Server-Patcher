#include "AppPaths.h"

#include <cstdio>
#include <cstring>

#include "FileUtils.h"

namespace Ext::Config {

namespace {

constexpr const char *kDefaultPackages[] = {
    "moe.ext.arc",
    "moe.low.arc",
};

bool try_package_file(const char *pkg, const char *filename, char *out_path,
                      size_t out_size) {
  char candidate[kMaxConfigPath];

  snprintf(candidate, sizeof(candidate), "/data/user/0/%s/files/%s", pkg,
           filename);
  if (Ext::Utils::file_exists(candidate)) {
    strncpy(out_path, candidate, out_size - 1);
    out_path[out_size - 1] = '\0';
    return true;
  }

  snprintf(candidate, sizeof(candidate), "/data/data/%s/files/%s", pkg,
           filename);
  if (Ext::Utils::file_exists(candidate)) {
    strncpy(out_path, candidate, out_size - 1);
    out_path[out_size - 1] = '\0';
    return true;
  }

  return false;
}

} // namespace

bool resolve_config_path(const char *filename, char *out_path,
                         size_t out_size) {
  if (!filename || !filename[0] || !out_path || out_size == 0)
    return false;

  char pkg[128] = {0};
  if (Ext::Utils::read_proc_cmdline(pkg, sizeof(pkg)) && pkg[0]) {
    if (try_package_file(pkg, filename, out_path, out_size))
      return true;
  }

  for (const char *fallback_pkg : kDefaultPackages) {
    if (try_package_file(fallback_pkg, filename, out_path, out_size))
      return true;
  }

  if (pkg[0]) {
    snprintf(out_path, out_size, "/data/user/0/%s/files/%s", pkg, filename);
  } else {
    snprintf(out_path, out_size, "/data/user/0/%s/files/%s",
             kDefaultPackages[0], filename);
  }
  return false;
}

} // namespace Ext::Config
