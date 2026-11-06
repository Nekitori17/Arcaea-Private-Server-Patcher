#include "SocketConnectHook.h"

#include <arpa/inet.h>
#include <cerrno>
#include <cstdint>
#include <cstring>
#include <netinet/in.h>
#include <sys/socket.h>

#include "DnsRouteCache.h"
#include "DomainRuleTable.h"
#include "NetStringUtils.h"

#define LOG_MODULE_TAG "SocketConnect"
#include "Logger.h"

namespace Ext::Hooks {

namespace {

int (*orig_connect)(int, const struct sockaddr *, socklen_t) = nullptr;

int invoke_connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
  int rc = orig_connect(sockfd, addr, addrlen);
  if (rc != 0 && errno != EINPROGRESS && errno != EINTR && errno != EALREADY &&
      errno != EISCONN) {
    LOGW("connect failed (fd=%d): errno=%d (%s)", sockfd, errno,
         strerror(errno));
  }
  return rc;
}

int hook_connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
  if (!orig_connect) {
    errno = ENOTCONN;
    return -1;
  }

  char target_str[96];
  if (Ext::Utils::format_sockaddr(addr, addrlen, target_str,
                                  sizeof(target_str))) {
    LOGI("connect(fd=%d) target: %s", sockfd, target_str);
  }

  const auto &table = Ext::Config::DomainRuleTable::instance();
  const auto &cache = Ext::Routing::DnsRouteCache::instance();
  const size_t total = table.count();

  if (addr && total > 0) {
    if (addr->sa_family == AF_INET &&
        addrlen >= static_cast<socklen_t>(sizeof(struct sockaddr_in))) {
      const auto *sin = reinterpret_cast<const struct sockaddr_in *>(addr);
      int port = ntohs(sin->sin_port);

      for (size_t i = 0; i < total; i++) {
        const Ext::Config::DomainRule *r = table.get(i);
        if (!r || !r->has_v4)
          continue;

        bool is_orig = cache.is_original_v4(i, &sin->sin_addr);
        bool is_repl = (r->repl_v4.s_addr == sin->sin_addr.s_addr);
        if (!is_orig && !is_repl)
          continue;

        if (is_orig) {
          if (r->orig_port != 0 && r->orig_port != port)
            continue;
          struct sockaddr_in dst {};
          memcpy(&dst, sin, sizeof(dst));
          dst.sin_addr = r->repl_v4;
          if (r->repl_port != 0)
            dst.sin_port = htons(static_cast<uint16_t>(r->repl_port));
          LOGI("redirect IPv4: :%d -> %s:%d (%s)", port, r->replacement,
               r->repl_port ? r->repl_port : port, r->original);
          return invoke_connect(
              sockfd, reinterpret_cast<const struct sockaddr *>(&dst), addrlen);
        }

        if (r->repl_port == 0 || port == r->repl_port)
          continue;
        struct sockaddr_in dst {};
        memcpy(&dst, sin, sizeof(dst));
        dst.sin_port = htons(static_cast<uint16_t>(r->repl_port));
        LOGI("redirect IPv4 port: %s:%d -> %s:%d (%s)", r->replacement, port,
             r->replacement, r->repl_port, r->original);
        return invoke_connect(
            sockfd, reinterpret_cast<const struct sockaddr *>(&dst), addrlen);
      }
    } else if (addr->sa_family == AF_INET6 &&
               addrlen >= static_cast<socklen_t>(sizeof(struct sockaddr_in6))) {
      const auto *sin6 = reinterpret_cast<const struct sockaddr_in6 *>(addr);
      int port = ntohs(sin6->sin6_port);

      for (size_t i = 0; i < total; i++) {
        const Ext::Config::DomainRule *r = table.get(i);
        if (!r || !r->has_v6)
          continue;

        bool is_orig = cache.is_original_v6(i, &sin6->sin6_addr);
        bool is_repl = (memcmp(&r->repl_v6, &sin6->sin6_addr,
                               sizeof(struct in6_addr)) == 0);
        if (!is_orig && !is_repl)
          continue;

        if (is_orig) {
          if (r->orig_port != 0 && r->orig_port != port)
            continue;
          struct sockaddr_in6 dst6 {};
          memcpy(&dst6, sin6, sizeof(dst6));
          dst6.sin6_addr = r->repl_v6;
          if (r->repl_port != 0)
            dst6.sin6_port = htons(static_cast<uint16_t>(r->repl_port));
          LOGI("redirect IPv6: -> [%s]:%d (%s)", r->replacement,
               r->repl_port ? r->repl_port : port, r->original);
          return invoke_connect(
              sockfd, reinterpret_cast<const struct sockaddr *>(&dst6),
              addrlen);
        }

        if (r->repl_port == 0 || port == r->repl_port)
          continue;
        struct sockaddr_in6 dst6 {};
        memcpy(&dst6, sin6, sizeof(dst6));
        dst6.sin6_port = htons(static_cast<uint16_t>(r->repl_port));
        LOGI("redirect IPv6 port: [%s]:%d -> :%d (%s)", r->replacement, port,
             r->repl_port, r->original);
        return invoke_connect(
            sockfd, reinterpret_cast<const struct sockaddr *>(&dst6), addrlen);
      }
    }
  }

  return invoke_connect(sockfd, addr, addrlen);
}

void install_socket_connect_hook(void *module_base) {
  Ext::Core::HookManager::instance().hook_plt_symbol(
      module_base, "SocketConnect", "connect",
      reinterpret_cast<void *>(hook_connect),
      reinterpret_cast<void **>(&orig_connect), false);
}

const Ext::Core::HookModule kSocketConnectModule = {
    "SocketConnect",
    install_socket_connect_hook,
};

} // namespace

const Ext::Core::HookModule *get_socket_connect_module() {
  return &kSocketConnectModule;
}

} // namespace Ext::Hooks
