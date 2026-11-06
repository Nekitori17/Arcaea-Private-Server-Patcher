#include "DnsRedirectHook.h"

#include <cstdio>
#include <netdb.h>
#include <sys/socket.h>

#include "DnsRouteCache.h"
#include "DomainMatcher.h"
#include "DomainRuleTable.h"
#include "HostentBuilder.h"

#define LOG_MODULE_TAG "DnsRedirect"
#include "Logger.h"

namespace Ext::Hooks {

namespace {

int (*orig_getaddrinfo)(const char *, const char *, const struct addrinfo *,
                        struct addrinfo **) = nullptr;
struct hostent *(*orig_gethostbyname)(const char *) = nullptr;
struct hostent *(*orig_gethostbyname2)(const char *, int) = nullptr;

int hook_getaddrinfo(const char *node, const char *service,
                     const struct addrinfo *hints, struct addrinfo **res) {
  if (!orig_getaddrinfo)
    return EAI_FAIL;
  if (!node)
    return orig_getaddrinfo(node, service, hints, res);

  size_t rule_idx = Ext::Config::find_matching_rule_index(node);
  if (rule_idx == Ext::Config::kRuleNotFound)
    return orig_getaddrinfo(node, service, hints, res);

  const Ext::Config::DomainRule *rule =
      Ext::Config::DomainRuleTable::instance().get(rule_idx);
  if (!rule)
    return orig_getaddrinfo(node, service, hints, res);

  Ext::Routing::DnsRouteCache::instance().snapshot_rule(rule_idx);

  int want_family =
      (hints && hints->ai_family != AF_UNSPEC) ? hints->ai_family : AF_UNSPEC;
  if (want_family != AF_UNSPEC && (rule->has_v4 || rule->has_v6)) {
    bool family_ok = (want_family == AF_INET && rule->has_v4) ||
                     (want_family == AF_INET6 && rule->has_v6);
    if (!family_ok) {
      LOGW("getaddrinfo: %s family %d mismatch with replacement '%s'", node,
           want_family, rule->replacement);
      return orig_getaddrinfo(node, service, hints, res);
    }
  }

  if (rule->repl_port != 0) {
    char port_buf[8];
    snprintf(port_buf, sizeof(port_buf), "%d", rule->repl_port);
    LOGI("getaddrinfo: %s:%s -> %s:%s", node,
         (service && service[0]) ? service : "-", rule->replacement, port_buf);
    return orig_getaddrinfo(rule->replacement, port_buf, hints, res);
  }

  LOGI("getaddrinfo: %s -> %s", node, rule->replacement);
  return orig_getaddrinfo(rule->replacement, service, hints, res);
}

struct hostent *hook_gethostbyname(const char *name) {
  if (!name)
    return orig_gethostbyname ? orig_gethostbyname(name) : nullptr;

  size_t rule_idx = Ext::Config::find_matching_rule_index(name);
  if (rule_idx == Ext::Config::kRuleNotFound)
    return orig_gethostbyname ? orig_gethostbyname(name) : nullptr;

  const Ext::Config::DomainRule *rule =
      Ext::Config::DomainRuleTable::instance().get(rule_idx);
  if (!rule || !rule->has_v4)
    return orig_gethostbyname ? orig_gethostbyname(name) : nullptr;

  Ext::Routing::DnsRouteCache::instance().snapshot_rule(rule_idx);
  LOGI("gethostbyname: %s -> %s", name, rule->replacement);
  return Ext::Routing::build_ipv4_hostent(rule);
}

struct hostent *hook_gethostbyname2(const char *name, int af) {
  if (!name)
    return orig_gethostbyname2 ? orig_gethostbyname2(name, af) : nullptr;

  size_t rule_idx = Ext::Config::find_matching_rule_index(name);
  if (rule_idx == Ext::Config::kRuleNotFound)
    return orig_gethostbyname2 ? orig_gethostbyname2(name, af) : nullptr;

  const Ext::Config::DomainRule *rule =
      Ext::Config::DomainRuleTable::instance().get(rule_idx);
  if (!rule || af != AF_INET || !rule->has_v4)
    return orig_gethostbyname2 ? orig_gethostbyname2(name, af) : nullptr;

  Ext::Routing::DnsRouteCache::instance().snapshot_rule(rule_idx);
  LOGI("gethostbyname2: %s -> %s", name, rule->replacement);
  return Ext::Routing::build_ipv4_hostent(rule);
}

void install_dns_hooks(void *module_base) {
  auto &hm = Ext::Core::HookManager::instance();
  hm.hook_plt_symbol(module_base, "DnsRedirect", "getaddrinfo",
                     reinterpret_cast<void *>(hook_getaddrinfo),
                     reinterpret_cast<void **>(&orig_getaddrinfo), false);
  hm.hook_plt_symbol(module_base, "DnsRedirect", "gethostbyname",
                     reinterpret_cast<void *>(hook_gethostbyname),
                     reinterpret_cast<void **>(&orig_gethostbyname), true);
  hm.hook_plt_symbol(module_base, "DnsRedirect", "gethostbyname2",
                     reinterpret_cast<void *>(hook_gethostbyname2),
                     reinterpret_cast<void **>(&orig_gethostbyname2), true);

  Ext::Routing::DnsRouteCache::instance().set_resolver(orig_getaddrinfo);
  if (Ext::Config::DomainRuleTable::instance().count() > 0 && orig_getaddrinfo) {
    Ext::Routing::DnsRouteCache::instance().snapshot_all_async();
  }
}

const Ext::Core::HookModule kDnsRedirectModule = {
    "DnsRedirect",
    install_dns_hooks,
};

} // namespace

const Ext::Core::HookModule *get_dns_redirect_module() {
  return &kDnsRedirectModule;
}

} // namespace Ext::Hooks
