#include "NetStringUtils.h"

#include <arpa/inet.h>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <netinet/in.h>

namespace Ext::Utils {

char *trim(char *s) {
  if (!s)
    return nullptr;
  while (*s == ' ' || *s == '\t' || *s == '\r' || *s == '\n')
    s++;
  char *end = s + strlen(s);
  while (end > s &&
         (end[-1] == ' ' || end[-1] == '\t' || end[-1] == '\r' || end[-1] == '\n'))
    end--;
  *end = '\0';
  return s;
}

int sanitize_host(char *s) {
  if (!s)
    return 0;
  char *dst = s;
  int removed = 0;
  for (; *s; s++) {
    auto c = static_cast<unsigned char>(*s);
    if (c < 0x20 || c == '"') {
      removed++;
      continue;
    }
    *dst++ = *s;
  }
  *dst = '\0';
  return removed;
}

bool host_equals(const char *a, const char *b) {
  if (!a || !b)
    return false;
  size_t la = strlen(a);
  size_t lb = strlen(b);
  while (la > 0 && a[la - 1] == '.')
    la--;
  while (lb > 0 && b[lb - 1] == '.')
    lb--;
  if (la != lb)
    return false;
  for (size_t i = 0; i < la; i++) {
    if (tolower(static_cast<unsigned char>(a[i])) !=
        tolower(static_cast<unsigned char>(b[i])))
      return false;
  }
  return true;
}

bool host_ends_with(const char *host, const char *suffix) {
  if (!host || !suffix)
    return false;
  size_t lh = strlen(host);
  size_t ls = strlen(suffix);
  while (lh > 0 && host[lh - 1] == '.')
    lh--;
  while (ls > 0 && suffix[ls - 1] == '.')
    ls--;
  if (ls == 0 || lh < ls)
    return false;
  const char *start = host + (lh - ls);
  for (size_t i = 0; i < ls; i++) {
    if (tolower(static_cast<unsigned char>(start[i])) !=
        tolower(static_cast<unsigned char>(suffix[i])))
      return false;
  }
  return true;
}

void parse_host_port(const char *input, char *out_host, size_t host_size,
                     int *out_port) {
  if (out_port)
    *out_port = 0;
  if (!out_host || host_size == 0)
    return;
  out_host[0] = '\0';
  if (!input || !input[0])
    return;

  char buf[256];
  strncpy(buf, input, sizeof(buf) - 1);
  buf[sizeof(buf) - 1] = '\0';

  if (buf[0] == '[') {
    char *rb = strchr(buf, ']');
    if (rb) {
      size_t len = static_cast<size_t>(rb - buf - 1);
      if (len >= host_size)
        len = host_size - 1;
      memcpy(out_host, buf + 1, len);
      out_host[len] = '\0';
      if (rb[1] == ':' && rb[2] != '\0' && out_port) {
        long port_val = strtol(rb + 2, nullptr, 10);
        if (port_val > 0 && port_val <= 65535)
          *out_port = static_cast<int>(port_val);
      }
      return;
    }
  }

  if (strchr(buf, ':') != nullptr) {
    struct in6_addr tmp6 {};
    if (inet_pton(AF_INET6, buf, &tmp6) == 1) {
      strncpy(out_host, buf, host_size - 1);
      out_host[host_size - 1] = '\0';
      return;
    }
  }

  char *colon = strrchr(buf, ':');
  if (colon && strchr(colon + 1, ':') == nullptr && colon[1] != '\0') {
    char *end = nullptr;
    long port_val = strtol(colon + 1, &end, 10);
    if (end && *end == '\0' && port_val > 0 && port_val <= 65535) {
      if (out_port)
        *out_port = static_cast<int>(port_val);
      *colon = '\0';
    }
  }

  strncpy(out_host, buf, host_size - 1);
  out_host[host_size - 1] = '\0';
}

bool format_sockaddr(const struct sockaddr *addr, socklen_t addrlen,
                     char *out_buf, size_t out_size) {
  if (!addr || !out_buf || out_size == 0)
    return false;
  out_buf[0] = '\0';

  char ip_str[INET6_ADDRSTRLEN] = {0};
  if (addr->sa_family == AF_INET &&
      addrlen >= static_cast<socklen_t>(sizeof(struct sockaddr_in))) {
    const auto *sin = reinterpret_cast<const struct sockaddr_in *>(addr);
    inet_ntop(AF_INET, &sin->sin_addr, ip_str, sizeof(ip_str));
    snprintf(out_buf, out_size, "%s:%d", ip_str, ntohs(sin->sin_port));
    return true;
  }
  if (addr->sa_family == AF_INET6 &&
      addrlen >= static_cast<socklen_t>(sizeof(struct sockaddr_in6))) {
    const auto *sin6 = reinterpret_cast<const struct sockaddr_in6 *>(addr);
    inet_ntop(AF_INET6, &sin6->sin6_addr, ip_str, sizeof(ip_str));
    snprintf(out_buf, out_size, "[%s]:%d", ip_str, ntohs(sin6->sin6_port));
    return true;
  }
  return false;
}

void format_ascii_preview(const void *buf, int len, char *out, size_t out_sz) {
  if (!buf || len <= 0 || out_sz == 0) {
    if (out_sz > 0)
      out[0] = '\0';
    return;
  }

  const auto *p = static_cast<const unsigned char *>(buf);
  size_t max_len = (static_cast<size_t>(len) < out_sz - 1)
                       ? static_cast<size_t>(len)
                       : (out_sz - 1);
  if (max_len > 120)
    max_len = 120;

  for (size_t i = 0; i < max_len; i++) {
    unsigned char c = p[i];
    if (c == '\r' || c == '\n')
      out[i] = ' ';
    else if (c >= 0x20 && c <= 0x7E)
      out[i] = static_cast<char>(c);
    else
      out[i] = '.';
  }
  out[max_len] = '\0';
}

} // namespace Ext::Utils
