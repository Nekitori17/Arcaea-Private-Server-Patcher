#include "NetworkRedirectHook.h"

#include <cctype>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <netdb.h>
#include <string>
#include <sys/socket.h>

#include "DomainRuleTable.h"
#include "NetStringUtils.h"

#define LOG_MODULE_TAG "NetRedirect"
#include "Logger.h"

namespace Ext::Hooks {

namespace {

int (*orig_getaddrinfo)(const char *, const char *, const struct addrinfo *,
                        struct addrinfo **) = nullptr;
struct hostent *(*orig_gethostbyname)(const char *) = nullptr;
struct hostent *(*orig_gethostbyname2)(const char *, int) = nullptr;
long (*orig_SSL_ctrl)(void *, int, long, void *) = nullptr;
int (*orig_SSL_write)(void *, const void *, int) = nullptr;
int (*orig_SSL_read)(void *, void *, int) = nullptr;

constexpr int kSslCtrlSetTlsextHostname = 55;

// ============================================================================
// 1. DNS Resolution Hook (Domain & Port Redirect)
// ============================================================================

int hook_getaddrinfo(const char *node, const char *service,
                     const struct addrinfo *hints, struct addrinfo **res) {
  if (!orig_getaddrinfo)
    return EAI_FAIL;
  if (!node)
    return orig_getaddrinfo(node, service, hints, res);

  const Ext::Config::DomainRule *rule = Ext::Config::find_matching_rule(node);
  if (!rule)
    return orig_getaddrinfo(node, service, hints, res);

  char port_buf[16];
  const char *target_service = service;
  if (rule->repl_port != 0) {
    snprintf(port_buf, sizeof(port_buf), "%d", rule->repl_port);
    target_service = port_buf;
  }

  LOGI("getaddrinfo: %s:%s -> %s:%s", node,
       (service && service[0]) ? service : "-", rule->replacement,
       (target_service && target_service[0]) ? target_service : "-");

  return orig_getaddrinfo(rule->replacement, target_service, hints, res);
}

struct hostent *hook_gethostbyname(const char *name) {
  if (!orig_gethostbyname)
    return nullptr;
  if (!name)
    return orig_gethostbyname(name);

  const Ext::Config::DomainRule *rule = Ext::Config::find_matching_rule(name);
  if (!rule)
    return orig_gethostbyname(name);

  LOGI("gethostbyname: %s -> %s", name, rule->replacement);
  return orig_gethostbyname(rule->replacement);
}

struct hostent *hook_gethostbyname2(const char *name, int af) {
  if (!orig_gethostbyname2)
    return nullptr;
  if (!name)
    return orig_gethostbyname2(name, af);

  const Ext::Config::DomainRule *rule = Ext::Config::find_matching_rule(name);
  if (!rule)
    return orig_gethostbyname2(name, af);

  LOGI("gethostbyname2: %s -> %s", name, rule->replacement);
  return orig_gethostbyname2(rule->replacement, af);
}

// ============================================================================
// 2. TLS SNI Extension Hook (SSL_set_tlsext_host_name / SSL_ctrl)
// ============================================================================

long hook_SSL_ctrl(void *ssl, int cmd, long larg, void *parg) {
  if (cmd == kSslCtrlSetTlsextHostname && parg != nullptr) {
    const char *orig_sni = static_cast<const char *>(parg);
    const Ext::Config::DomainRule *rule =
        Ext::Config::find_matching_rule(orig_sni);
    if (rule) {
      LOGI("SSL_ctrl SNI: %s -> %s", orig_sni, rule->replacement);
      parg = const_cast<char *>(rule->replacement);
    }
  }
  if (!orig_SSL_ctrl)
    return 0;
  return orig_SSL_ctrl(ssl, cmd, larg, parg);
}

// ============================================================================
// 3. HTTP Host Header Rewrite & Traffic Logging (SSL_write & SSL_read)
// ============================================================================

bool is_http_request(const char *data, int len) {
  if (len < 10)
    return false;
  return (memcmp(data, "GET ", 4) == 0 || memcmp(data, "POST ", 5) == 0 ||
          memcmp(data, "PUT ", 4) == 0 || memcmp(data, "DELETE ", 7) == 0 ||
          memcmp(data, "HEAD ", 5) == 0 || memcmp(data, "PATCH ", 6) == 0 ||
          memcmp(data, "OPTIONS ", 8) == 0);
}

std::string rewrite_http_host(const char *data, int len) {
  std::string payload(data, len);
  const char *p = payload.c_str();
  const char *found_pos = nullptr;

  for (size_t i = 0; i + 6 < payload.size(); i++) {
    if (p[i] == '\n' && (p[i + 1] == 'H' || p[i + 1] == 'h') &&
        (p[i + 2] == 'o' || p[i + 2] == 'O') &&
        (p[i + 3] == 's' || p[i + 3] == 'S') &&
        (p[i + 4] == 't' || p[i + 4] == 'T') && p[i + 5] == ':') {
      found_pos = p + i + 1;
      break;
    }
  }
  if (!found_pos)
    return payload;

  const char *val_start = found_pos + 5;
  while (*val_start == ' ' || *val_start == '\t')
    val_start++;

  const char *val_end = val_start;
  while (*val_end && *val_end != '\r' && *val_end != '\n')
    val_end++;

  const char *port_colon = nullptr;
  for (const char *c = val_start; c < val_end; c++) {
    if (*c == ':') {
      port_colon = c;
      break;
    }
  }

  size_t host_len =
      port_colon ? (port_colon - val_start) : (val_end - val_start);
  char host_buf[128];
  if (host_len >= sizeof(host_buf))
    return payload;
  memcpy(host_buf, val_start, host_len);
  host_buf[host_len] = '\0';

  const auto *rule = Ext::Config::find_matching_rule(host_buf);
  if (!rule)
    return payload;

  char new_host_val[256];
  if (rule->repl_port != 0) {
    snprintf(new_host_val, sizeof(new_host_val), "%s:%d", rule->replacement,
             rule->repl_port);
  } else if (port_colon) {
    std::string orig_port_str(port_colon, val_end - port_colon);
    snprintf(new_host_val, sizeof(new_host_val), "%s%s", rule->replacement,
             orig_port_str.c_str());
  } else {
    snprintf(new_host_val, sizeof(new_host_val), "%s", rule->replacement);
  }

  size_t replace_offset = val_start - payload.c_str();
  size_t replace_len = val_end - val_start;
  payload.replace(replace_offset, replace_len, new_host_val);
  LOGI("SSL_write Host: %s -> %s", host_buf, new_host_val);
  return payload;
}

int hook_SSL_write(void *ssl, const void *buf, int num) {
  if (!orig_SSL_write)
    return -1;
  if (!buf || num <= 0)
    return orig_SSL_write(ssl, buf, num);

  const char *char_buf = static_cast<const char *>(buf);
  if (is_http_request(char_buf, num)) {
    std::string modified = rewrite_http_host(char_buf, num);
    char preview[128];
    Ext::Utils::format_ascii_preview(modified.data(), modified.size(), preview,
                                    sizeof(preview));
    LOGI("SSL_write(ssl=%p, len=%zu): %s", ssl, modified.size(), preview);

    int rc = orig_SSL_write(ssl, modified.data(),
                            static_cast<int>(modified.size()));
    return (rc > 0) ? num : rc;
  }

  char preview[128];
  Ext::Utils::format_ascii_preview(buf, num, preview, sizeof(preview));
  LOGI("SSL_write(ssl=%p, len=%d): %s", ssl, num, preview);
  return orig_SSL_write(ssl, buf, num);
}

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

void install_network_redirect_hooks(void *module_base) {
  auto &hm = Ext::Core::HookManager::instance();
  hm.hook_plt_symbol(module_base, "NetworkRedirect", "getaddrinfo",
                     reinterpret_cast<void *>(hook_getaddrinfo),
                     reinterpret_cast<void **>(&orig_getaddrinfo), false);
  hm.hook_plt_symbol(module_base, "NetworkRedirect", "gethostbyname",
                     reinterpret_cast<void *>(hook_gethostbyname),
                     reinterpret_cast<void **>(&orig_gethostbyname), true);
  hm.hook_plt_symbol(module_base, "NetworkRedirect", "gethostbyname2",
                     reinterpret_cast<void *>(hook_gethostbyname2),
                     reinterpret_cast<void **>(&orig_gethostbyname2), true);
  hm.hook_plt_symbol(module_base, "NetworkRedirect", "SSL_ctrl",
                     reinterpret_cast<void *>(hook_SSL_ctrl),
                     reinterpret_cast<void **>(&orig_SSL_ctrl), true);
  hm.hook_plt_symbol(module_base, "NetworkRedirect", "SSL_write",
                     reinterpret_cast<void *>(hook_SSL_write),
                     reinterpret_cast<void **>(&orig_SSL_write), true);
  hm.hook_plt_symbol(module_base, "NetworkRedirect", "SSL_read",
                     reinterpret_cast<void *>(hook_SSL_read),
                     reinterpret_cast<void **>(&orig_SSL_read), true);
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

