#include "NetworkRedirectHook.h"

#include <cstdarg>
#include <cstdio>
#include <cstring>

#include "CurlPattern.h"
#include "DomainRuleTable.h"
#include "InlineHook.h"
#include "NetStringUtils.h"
#include "PatternScan.h"

#define LOG_MODULE_TAG "NetRedirect"
#include "Logger.h"

namespace Ext::Hooks {

namespace {

bool rewrite_url(const char *input_url, char *out_url, size_t out_sz) {
  if (!input_url || !out_url || out_sz == 0)
    return false;

  const char *scheme_end = strstr(input_url, "://");
  if (!scheme_end) {
    strncpy(out_url, input_url, out_sz - 1);
    out_url[out_sz - 1] = '\0';
    return false;
  }

  const char *host_start = scheme_end + 3;
  const char *path_start = strpbrk(host_start, "/?#");
  size_t host_port_len = path_start
                             ? static_cast<size_t>(path_start - host_start)
                             : strlen(host_start);

  char host_port_buf[256];
  if (host_port_len >= sizeof(host_port_buf)) {
    strncpy(out_url, input_url, out_sz - 1);
    out_url[out_sz - 1] = '\0';
    return false;
  }
  memcpy(host_port_buf, host_start, host_port_len);
  host_port_buf[host_port_len] = '\0';

  char host[Ext::Config::kMaxHostLength];
  int orig_port = 0;
  Ext::Utils::parse_host_port(host_port_buf, host, sizeof(host), &orig_port);

  const auto *rule = Ext::Config::find_matching_rule(host);
  if (!rule) {
    strncpy(out_url, input_url, out_sz - 1);
    out_url[out_sz - 1] = '\0';
    return false;
  }

  char new_host_port[256];
  if (rule->repl_port != 0) {
    snprintf(new_host_port, sizeof(new_host_port), "%s:%d", rule->replacement,
             rule->repl_port);
  } else if (orig_port != 0) {
    snprintf(new_host_port, sizeof(new_host_port), "%s:%d", rule->replacement,
             orig_port);
  } else {
    snprintf(new_host_port, sizeof(new_host_port), "%s", rule->replacement);
  }

  size_t scheme_len = static_cast<size_t>(scheme_end - input_url + 3);
  const char *tail = path_start ? path_start : "";
  snprintf(out_url, out_sz, "%.*s%s%s", static_cast<int>(scheme_len),
           input_url, new_host_port, tail);
  return true;
}

using curl_easy_setopt_t = int (*)(void *curl, int opt, ...);
curl_easy_setopt_t orig_curl_easy_setopt = nullptr;

int hook_curl_easy_setopt(void *curl, int opt, ...) {
  va_list args;
  va_start(args, opt);

  switch (opt) {
    case Ext::Patterns::kCurlOptUrl: {
      const char *orig_url = va_arg(args, const char *);
      va_end(args);

      if (!orig_url) {
        return orig_curl_easy_setopt(curl, opt, orig_url);
      }

      char rewritten[1024];
      if (rewrite_url(orig_url, rewritten, sizeof(rewritten))) {
        LOGI("curl_easy_setopt(CURLOPT_URL): %s -> %s", orig_url, rewritten);
        return orig_curl_easy_setopt(curl, opt, rewritten);
      }

      return orig_curl_easy_setopt(curl, opt, orig_url);
    }

    case Ext::Patterns::kCurlOptPinnedPublicKey: {
      va_end(args);
      LOGI("curl_easy_setopt(CURLOPT_PINNEDPUBLICKEY) suppressed");
      return Ext::Patterns::kCurleOk;
    }

    case Ext::Patterns::kCurlOptSslVerifyHost: {
      va_end(args);
      LOGI("curl_easy_setopt(CURLOPT_SSL_VERIFYHOST) set to 0");
      return orig_curl_easy_setopt(curl, opt, 0L);
    }

    case Ext::Patterns::kCurlOptSslVerifyPeer: {
      va_end(args);
      LOGI("curl_easy_setopt(CURLOPT_SSL_VERIFYPEER) set to 0");
      return orig_curl_easy_setopt(curl, opt, 0L);
    }

    default: {
      void *arg = va_arg(args, void *);
      va_end(args);
      return orig_curl_easy_setopt(curl, opt, arg);
    }
  }
}

void install_network_redirect_hooks(void * /*module_base*/) {
  LOGI("Installing Network Redirect (URL Rewrite via curl_easy_setopt)...");

  void *setopt_addr = Ext::Utils::scan_module_pattern(
      "libcocos2dcpp.so", Ext::Patterns::kCurlEasySetoptPattern);
  if (!setopt_addr) {
    LOGE("Failed to find curl_easy_setopt via pattern scan in libcocos2dcpp.so");
    return;
  }

  LOGI("Found curl_easy_setopt @ %p", setopt_addr);

  if (Ext::Core::inline_hook(
          setopt_addr, reinterpret_cast<void *>(hook_curl_easy_setopt),
          reinterpret_cast<void **>(&orig_curl_easy_setopt))) {
    LOGI("Successfully installed inline hook on curl_easy_setopt");
  } else {
    LOGE("Failed to install inline hook on curl_easy_setopt @ %p", setopt_addr);
  }
}

const Ext::Core::HookModule kNetworkRedirectModule = {
    "NetworkRedirect",
    install_network_redirect_hooks,
};

} // namespace

const Ext::Core::HookModule *get_network_redirect_module() {
  return &kNetworkRedirectModule;
}

} // namespace Ext::Hooks
