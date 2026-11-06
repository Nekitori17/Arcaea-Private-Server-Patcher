#include "FileUtils.h"

#include <cstring>
#include <unistd.h>

namespace Ext::Utils {

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

} // namespace Ext::Utils
