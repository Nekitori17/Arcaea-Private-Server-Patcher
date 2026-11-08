
#include "NetworkRedirectHook.h"

#include <cctype>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <netdb.h>
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

bool is_http_request(const char *data, int len) {
  if (len < 10)
    return false;
  return (memcmp(data, "GET ", 4) == 0 || memcmp(data, "POST ", 5) == 0 ||
          memcmp(data, "PUT ", 4) == 0 || memcmp(data, "DELETE ", 7) == 0 ||
          memcmp(data, "HEAD ", 5) == 0 || memcmp(data, "PATCH ", 6) == 0 ||
          memcmp(data, "OPTIONS ", 8) == 0);
}

char *rewrite_http_host(const char *data, int len, int *out_len) {
  *out_len = len;
  const char *found_pos = nullptr;
  for (int i = 0; i + 6 < len; i++) {
    if (data[i] == '\n' && (data[i + 1] == 'H' || data[i + 1] == 'h') &&
        (data[i + 2] == 'o' || data[i + 2] == 'O') &&
        (data[i + 3] == 's' || data[i + 3] == 'S') &&
        (data[i + 4] == 't' || data[i + 4] == 'T') && data[i + 5] == ':') {
      found_pos = data + i + 1;
      break;
    }
  }
  if (!found_pos)
    return nullptr;

  const char *val_start = found_pos + 5;
  while (*val_start == ' ' || *val_start == '\t')
    val_start++;

  const char *val_end = val_start;
  while (val_end < (data + len) && *val_end != '\r' && *val_end != '\n')
    val_end++;

  const char *port_colon = nullptr;
  for (const char *c = val_start; c < val_end; c++) {
    if (*c == ':') {
      port_colon = c;
      break;
    }
  }

  size_t host_len = port_colon ? (port_colon - val_start) : (val_end - val_start);
  char host_buf[128];
  if (host_len >= sizeof(host_buf))
    return nullptr;
  memcpy(host_buf, val_start, host_len);
  host_buf[host_len] = '\0';

  const auto *rule = Ext::Config::find_matching_rule(host_buf);
  if (!rule)
    return nullptr;

  char new_host_val[256];
  if (rule->repl_port != 0) {
    snprintf(new_host_val, sizeof(new_host_val), "%s:%d", rule->replacement,
             rule->repl_port);
  } else if (port_colon) {
    size_t port_len = val_end - port_colon;
    char orig_port[16];
    if (port_len < sizeof(orig_port)) {
      memcpy(orig_port, port_colon, port_len);
      orig_port[port_len] = '\0';
      snprintf(new_host_val, sizeof(new_host_val), "%s%s", rule->replacement, orig_port);
    } else {
      snprintf(new_host_val, sizeof(new_host_val), "%s", rule->replacement);
    }
  } else {
    snprintf(new_host_val, sizeof(new_host_val), "%s", rule->replacement);
  }

  size_t prefix_len = val_start - data;
  size_t suffix_len = (data + len) - val_end;
  size_t new_host_len = strlen(new_host_val);
  size_t total_len = prefix_len + new_host_len + suffix_len;

  char *out = static_cast<char *>(malloc(total_len + 1));
  if (!out)
    return nullptr;

  memcpy(out, data, prefix_len);
  memcpy(out + prefix_len, new_host_val, new_host_len);
  memcpy(out + prefix_len + new_host_len, val_end, suffix_len);
  out[total_len] = '\0';

  *out_len = static_cast<int>(total_len);
  LOGI("SSL_write Host: %s -> %s", host_buf, new_host_val);
  return out;
}

int hook_SSL_write(void *ssl, const void *buf, int num) {
  if (!orig_SSL_write)
    return -1;
  if (!buf || num <= 0)
    return orig_SSL_write(ssl, buf, num);

  const char *char_buf = static_cast<const char *>(buf);
  if (is_http_request(char_buf, num)) {
    int new_len = num;
    char *modified = rewrite_http_host(char_buf, num, &new_len);
    if (modified) {
      char preview[128];
      Ext::Utils::format_ascii_preview(modified, new_len, preview, sizeof(preview));
      LOGI("SSL_write(ssl=%p, len=%d): %s", ssl, new_len, preview);

      int rc = orig_SSL_write(ssl, modified, new_len);
      free(modified);
      return (rc > 0) ? num : rc;
    }
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
