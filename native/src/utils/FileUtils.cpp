#include "FileUtils.h"

#include <cstdio>
#include <cstring>
#include <unistd.h>

namespace Ext::Utils {

namespace {

constexpr const char *kDefaultPackages[] = {
    "moe.ext.arc",
    "moe.low.arc",
};

bool try_package_file(const char *pkg, const char *filename, char *out_path,
                      size_t out_size) {
  char candidate[kMaxPathLength];

  snprintf(candidate, sizeof(candidate), "/data/user/0/%s/files/%s", pkg,
           filename);
  if (file_exists(candidate)) {
    strncpy(out_path, candidate, out_size - 1);
    out_path[out_size - 1] = '\0';
    return true;
  }

  snprintf(candidate, sizeof(candidate), "/data/data/%s/files/%s", pkg,
           filename);
  if (file_exists(candidate)) {
    strncpy(out_path, candidate, out_size - 1);
    out_path[out_size - 1] = '\0';
    return true;
  }

  return false;
}

} // namespace

bool file_exists(const char *path) {
  if (!path || !path[0])
    return false;
  return access(path, R_OK) == 0;
}

bool read_proc_cmdline(char *buf, size_t max_len) {
  if (!buf || max_len == 0)
    return false;
  buf[0] = '\0';

  FILE *fp = fopen("/proc/self/cmdline", "r");
  if (!fp)
    return false;

  size_t n = fread(buf, 1, max_len - 1, fp);
  fclose(fp);

  if (n > 0) {
    buf[n] = '\0';
    return true;
  }
  return false;
}

int read_line(FILE *fp, char *buf, size_t max_len) {
  if (!fp || !buf || max_len == 0)
    return -1;
  if (!fgets(buf, static_cast<int>(max_len), fp))
    return -1;
  buf[strcspn(buf, "\r\n")] = '\0';
  return static_cast<int>(strlen(buf));
}

bool resolve_app_file_path(const char *filename, char *out_path, size_t out_size) {
  if (!filename || !filename[0] || !out_path || out_size == 0)
    return false;

  char pkg[128] = {0};
  if (read_proc_cmdline(pkg, sizeof(pkg)) && pkg[0]) {
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

} // namespace Ext::Utils
