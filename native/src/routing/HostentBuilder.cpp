#include "HostentBuilder.h"

#include <cstring>
#include <sys/socket.h>

namespace Ext::Routing {

namespace {

thread_local struct hostent s_he;
thread_local struct in_addr s_he_addrs[1];
thread_local char *s_he_list[2];
thread_local char *s_he_aliases[1];
thread_local char s_he_name[Ext::Config::kMaxHostLength];

} // namespace

struct hostent *build_ipv4_hostent(const Ext::Config::DomainRule *rule) {
  if (!rule || !rule->has_v4)
    return nullptr;

  memset(&s_he, 0, sizeof(s_he));
  strncpy(s_he_name, rule->original, sizeof(s_he_name) - 1);
  s_he_name[sizeof(s_he_name) - 1] = '\0';

  s_he_addrs[0] = rule->repl_v4;
  s_he_list[0] = reinterpret_cast<char *>(&s_he_addrs[0]);
  s_he_list[1] = nullptr;
  s_he_aliases[0] = nullptr;

  s_he.h_name = s_he_name;
  s_he.h_aliases = s_he_aliases;
  s_he.h_addrtype = AF_INET;
  s_he.h_length = static_cast<int>(sizeof(struct in_addr));
  s_he.h_addr_list = s_he_list;
  return &s_he;
}

} // namespace Ext::Routing
