#pragma once

#include <cstddef>
#include <netdb.h>
#include <netinet/in.h>

namespace Ext::Routing {

using AddrInfoResolverFn = int (*)(const char *, const char *,
                                   const struct addrinfo *,
                                   struct addrinfo **);

class DnsRouteCache {
public:
  static DnsRouteCache &instance();

  void set_resolver(AddrInfoResolverFn resolver);
  void snapshot_rule(size_t rule_idx);
  void snapshot_all_async();

  bool is_original_v4(size_t rule_idx, const struct in_addr *ip) const;
  bool is_original_v6(size_t rule_idx, const struct in6_addr *ip) const;

private:
  DnsRouteCache() = default;
};

} // namespace Ext::Routing
