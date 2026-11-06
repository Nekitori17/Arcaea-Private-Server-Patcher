#pragma once

#include <cstddef>
#include <sys/socket.h>

namespace Ext::Utils {

char *trim(char *s);

int sanitize_host(char *s);

bool host_equals(const char *a, const char *b);

bool host_ends_with(const char *host, const char *suffix);

void parse_host_port(const char *input, char *out_host, size_t host_size,
                     int *out_port);

bool format_sockaddr(const struct sockaddr *addr, socklen_t addrlen,
                     char *out_buf, size_t out_size);

void format_ascii_preview(const void *buf, int len, char *out, size_t out_sz);

} // namespace Ext::Utils
