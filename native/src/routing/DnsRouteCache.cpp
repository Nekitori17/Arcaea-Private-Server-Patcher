#include "DnsRouteCache.h"

#include <cstring>
#include <pthread.h>
#include <sys/socket.h>

#include "DomainRuleTable.h"

#define LOG_MODULE_TAG "RouteCache"
#include "Logger.h"

namespace Ext::Routing {

namespace {

constexpr size_t kMaxOrigV4PerRule = 4;
constexpr size_t kMaxOrigV6PerRule = 2;

struct in_addr s_orig_v4[Ext::Config::kMaxDomainRules][kMaxOrigV4PerRule];
size_t s_orig_v4_count[Ext::Config::kMaxDomainRules];
struct in6_addr s_orig_v6[Ext::Config::kMaxDomainRules][kMaxOrigV6PerRule];
size_t s_orig_v6_count[Ext::Config::kMaxDomainRules];
bool s_snap_tried[Ext::Config::kMaxDomainRules];

AddrInfoResolverFn s_resolver = nullptr;
pthread_mutex_t s_lock = PTHREAD_MUTEX_INITIALIZER;

void remember_v4(size_t rule_idx, struct in_addr ip) {
  for (size_t i = 0; i < s_orig_v4_count[rule_idx]; i++) {
    if (s_orig_v4[rule_idx][i].s_addr == ip.s_addr)
      return;
  }
  if (s_orig_v4_count[rule_idx] < kMaxOrigV4PerRule)
    s_orig_v4[rule_idx][s_orig_v4_count[rule_idx]++] = ip;
}

void remember_v6(size_t rule_idx, const struct in6_addr *ip) {
  for (size_t i = 0; i < s_orig_v6_count[rule_idx]; i++) {
    if (memcmp(&s_orig_v6[rule_idx][i], ip, sizeof(struct in6_addr)) == 0)
      return;
  }
  if (s_orig_v6_count[rule_idx] < kMaxOrigV6PerRule)
    s_orig_v6[rule_idx][s_orig_v6_count[rule_idx]++] = *ip;
}

void *warm_cache_worker(void * /*arg*/) {
  size_t total = Ext::Config::DomainRuleTable::instance().count();
  for (size_t i = 0; i < total; i++) {
    DnsRouteCache::instance().snapshot_rule(i);
  }
  return nullptr;
}

} // namespace

DnsRouteCache &DnsRouteCache::instance() {
  static DnsRouteCache s_instance;
  return s_instance;
}

void DnsRouteCache::set_resolver(AddrInfoResolverFn resolver) {
  pthread_mutex_lock(&s_lock);
  s_resolver = resolver;
  pthread_mutex_unlock(&s_lock);
}

void DnsRouteCache::snapshot_rule(size_t rule_idx) {
  if (rule_idx >= Ext::Config::kMaxDomainRules)
    return;

  const Ext::Config::DomainRule *rule =
      Ext::Config::DomainRuleTable::instance().get(rule_idx);
  if (!rule || !rule->original[0])
    return;

  pthread_mutex_lock(&s_lock);
  AddrInfoResolverFn resolver = s_resolver;
  if (!resolver || s_snap_tried[rule_idx]) {
    pthread_mutex_unlock(&s_lock);
    return;
  }
  s_snap_tried[rule_idx] = true;
  pthread_mutex_unlock(&s_lock);

  struct addrinfo hints {};
  struct addrinfo *res = nullptr;
  hints.ai_socktype = SOCK_STREAM;

  int rc = resolver(rule->original, nullptr, &hints, &res);
  if (rc != 0 || !res) {
    pthread_mutex_lock(&s_lock);
    s_snap_tried[rule_idx] = false;
    pthread_mutex_unlock(&s_lock);
    return;
  }

  pthread_mutex_lock(&s_lock);
  for (struct addrinfo *p = res; p; p = p->ai_next) {
    if (p->ai_family == AF_INET &&
        p->ai_addrlen >= static_cast<socklen_t>(sizeof(struct sockaddr_in))) {
      const auto *sin = reinterpret_cast<const struct sockaddr_in *>(p->ai_addr);
      remember_v4(rule_idx, sin->sin_addr);
    } else if (p->ai_family == AF_INET6 &&
               p->ai_addrlen >=
                   static_cast<socklen_t>(sizeof(struct sockaddr_in6))) {
      const auto *sin6 =
          reinterpret_cast<const struct sockaddr_in6 *>(p->ai_addr);
      remember_v6(rule_idx, &sin6->sin6_addr);
    }
  }
  size_t n4 = s_orig_v4_count[rule_idx];
  size_t n6 = s_orig_v6_count[rule_idx];
  pthread_mutex_unlock(&s_lock);

  freeaddrinfo(res);
  LOGI("Rule[%zu] %s baseline DNS snapshot: v4=%zu v6=%zu", rule_idx,
       rule->original, n4, n6);
}

void DnsRouteCache::snapshot_all_async() {
  pthread_t tid;
  if (pthread_create(&tid, nullptr, warm_cache_worker, nullptr) == 0)
    pthread_detach(tid);
  else
    LOGW("Snapshot worker thread creation failed; will snapshot on demand");
}

bool DnsRouteCache::is_original_v4(size_t rule_idx,
                                   const struct in_addr *ip) const {
  if (rule_idx >= Ext::Config::kMaxDomainRules || !ip)
    return false;

  bool found = false;
  pthread_mutex_lock(&s_lock);
  size_t n = s_orig_v4_count[rule_idx];
  for (size_t i = 0; i < n; i++) {
    if (s_orig_v4[rule_idx][i].s_addr == ip->s_addr) {
      found = true;
      break;
    }
  }
  pthread_mutex_unlock(&s_lock);
  return found;
}

bool DnsRouteCache::is_original_v6(size_t rule_idx,
                                   const struct in6_addr *ip) const {
  if (rule_idx >= Ext::Config::kMaxDomainRules || !ip)
    return false;

  bool found = false;
  pthread_mutex_lock(&s_lock);
  size_t n = s_orig_v6_count[rule_idx];
  for (size_t i = 0; i < n; i++) {
    if (memcmp(&s_orig_v6[rule_idx][i], ip, sizeof(struct in6_addr)) == 0) {
      found = true;
      break;
    }
  }
  pthread_mutex_unlock(&s_lock);
  return found;
}

} // namespace Ext::Routing
