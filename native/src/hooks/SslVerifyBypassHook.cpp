#include "SslVerifyBypassHook.h"

#include <cstddef>

#define LOG_MODULE_TAG "SslBypass"
#include "Logger.h"

namespace Ext::Hooks {

namespace {

void (*orig_CTX_set_verify)(void *, int, void *) = nullptr;
void (*orig_set_verify)(void *, int, void *) = nullptr;
void (*orig_CTX_custom_verify)(void *, int, void *) = nullptr;
int (*orig_X509_verify)(void *) = nullptr;
long (*orig_get_verify_result)(const void *) = nullptr;
void (*orig_CTX_cert_verify_cb)(void *, void *, void *) = nullptr;
int (*orig_set1_host)(void *, const char *) = nullptr;
int (*orig_X509_check_host)(void *, const char *, size_t, unsigned,
                            void **) = nullptr;

void hook_CTX_set_verify(void *ctx, int /*mode*/, void * /*cb*/) {
  LOGI("SSL_CTX_set_verify -> VERIFY_NONE");
  if (orig_CTX_set_verify)
    orig_CTX_set_verify(ctx, 0, nullptr);
}

void hook_set_verify(void *ssl, int /*mode*/, void * /*cb*/) {
  LOGI("SSL_set_verify -> VERIFY_NONE");
  if (orig_set_verify)
    orig_set_verify(ssl, 0, nullptr);
}

void hook_CTX_custom_verify(void *ctx, int /*mode*/, void * /*cb*/) {
  LOGI("SSL_CTX_set_custom_verify -> VERIFY_NONE");
  if (orig_CTX_custom_verify)
    orig_CTX_custom_verify(ctx, 0, nullptr);
}

int hook_X509_verify(void * /*ctx*/) {
  LOGI("X509_verify_cert -> 1 (bypass)");
  return 1;
}

long hook_get_verify_result(const void * /*ssl*/) {
  return 0; // X509_V_OK
}

void hook_CTX_cert_verify_cb(void *ctx, void * /*cb*/, void * /*arg*/) {
  LOGI("SSL_CTX_set_cert_verify_callback -> NULL");
  if (orig_CTX_cert_verify_cb)
    orig_CTX_cert_verify_cb(ctx, nullptr, nullptr);
}

int hook_set1_host(void * /*ssl*/, const char *host) {
  LOGI("SSL_set1_host(%s) -> bypassed", host ? host : "(null)");
  return 1;
}

int hook_X509_check_host(void * /*cert*/, const char * /*host*/, size_t /*len*/,
                         unsigned /*flags*/, void ** /*peer*/) {
  LOGI("X509_check_host -> 1 (bypass)");
  return 1;
}

void install_ssl_verify_bypass_hooks(void *module_base) {
  auto &hm = Ext::Core::HookManager::instance();
  hm.hook_plt_symbol(module_base, "SslBypass", "SSL_CTX_set_verify",
                     reinterpret_cast<void *>(hook_CTX_set_verify),
                     reinterpret_cast<void **>(&orig_CTX_set_verify), true);
  hm.hook_plt_symbol(module_base, "SslBypass", "SSL_set_verify",
                     reinterpret_cast<void *>(hook_set_verify),
                     reinterpret_cast<void **>(&orig_set_verify), true);
  hm.hook_plt_symbol(module_base, "SslBypass", "SSL_CTX_set_custom_verify",
                     reinterpret_cast<void *>(hook_CTX_custom_verify),
                     reinterpret_cast<void **>(&orig_CTX_custom_verify), true);
  hm.hook_plt_symbol(module_base, "SslBypass", "X509_verify_cert",
                     reinterpret_cast<void *>(hook_X509_verify),
                     reinterpret_cast<void **>(&orig_X509_verify), true);
  hm.hook_plt_symbol(module_base, "SslBypass", "SSL_get_verify_result",
                     reinterpret_cast<void *>(hook_get_verify_result),
                     reinterpret_cast<void **>(&orig_get_verify_result), true);
  hm.hook_plt_symbol(
      module_base, "SslBypass", "SSL_CTX_set_cert_verify_callback",
      reinterpret_cast<void *>(hook_CTX_cert_verify_cb),
      reinterpret_cast<void **>(&orig_CTX_cert_verify_cb), true);
  hm.hook_plt_symbol(module_base, "SslBypass", "SSL_set1_host",
                     reinterpret_cast<void *>(hook_set1_host),
                     reinterpret_cast<void **>(&orig_set1_host), true);
  hm.hook_plt_symbol(module_base, "SslBypass", "X509_check_host",
                     reinterpret_cast<void *>(hook_X509_check_host),
                     reinterpret_cast<void **>(&orig_X509_check_host), true);
}

const Ext::Core::HookModule kSslVerifyBypassModule = {
    "SslBypass",
    install_ssl_verify_bypass_hooks,
};

} // namespace

const Ext::Core::HookModule *get_ssl_verify_bypass_module() {
  return &kSslVerifyBypassModule;
}

} // namespace Ext::Hooks
