#include "SslTrafficLoggerHook.h"

#include "NetStringUtils.h"

#define LOG_MODULE_TAG "SslTraffic"
#include "Logger.h"

namespace Ext::Hooks {

namespace {

int (*orig_SSL_read)(void *, void *, int) = nullptr;
int (*orig_SSL_write)(void *, const void *, int) = nullptr;

int hook_SSL_read(void *ssl, void *buf, int num) {
  if (!orig_SSL_read)
    return -1;
  int rc = orig_SSL_read(ssl, buf, num);
  if (rc > 0 && buf) {
    char preview[128];
    Ext::Utils::format_ascii_preview(buf, rc, preview, sizeof(preview));
    LOGI("SSL_read(ssl=%p, req=%d, ret=%d): %s", ssl, num, rc, preview);
  }
  return rc;
}

int hook_SSL_write(void *ssl, const void *buf, int num) {
  if (num > 0 && buf) {
    char preview[128];
    Ext::Utils::format_ascii_preview(buf, num, preview, sizeof(preview));
    LOGI("SSL_write(ssl=%p, len=%d): %s", ssl, num, preview);
  }
  if (!orig_SSL_write)
    return -1;
  return orig_SSL_write(ssl, buf, num);
}

void install_ssl_traffic_logger_hooks(void *module_base) {
  auto &hm = Ext::Core::HookManager::instance();
  hm.hook_plt_symbol(module_base, "SslTraffic", "SSL_read",
                     reinterpret_cast<void *>(hook_SSL_read),
                     reinterpret_cast<void **>(&orig_SSL_read), true);
  hm.hook_plt_symbol(module_base, "SslTraffic", "SSL_write",
                     reinterpret_cast<void *>(hook_SSL_write),
                     reinterpret_cast<void **>(&orig_SSL_write), true);
}

const Ext::Core::HookModule kSslTrafficLoggerModule = {
    "SslTraffic",
    install_ssl_traffic_logger_hooks,
};

} // namespace

const Ext::Core::HookModule *get_ssl_traffic_logger_module() {
  return &kSslTrafficLoggerModule;
}

} // namespace Ext::Hooks
