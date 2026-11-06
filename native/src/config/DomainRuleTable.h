#pragma once

#include <cstddef>
#include <cstdio>
#include <netinet/in.h>

namespace Ext::Config {

constexpr size_t kMaxDomainRules = 64;
constexpr size_t kMaxHostLength = 128;
constexpr size_t kRuleNotFound = static_cast<size_t>(-1);

struct DomainRule {
  char original[kMaxHostLength];
  char replacement[kMaxHostLength];
  int orig_port;
  int repl_port;
  struct in_addr repl_v4;
  bool has_v4;
  struct in6_addr repl_v6;
  bool has_v6;
};

class DomainRuleTable {
public:
  static DomainRuleTable &instance();

  void clear();
  int load_file(const char *path);
  int load_stream(FILE *fp);

  size_t count() const;
  const DomainRule *get(size_t index) const;

private:
  DomainRuleTable() = default;

  DomainRule m_rules[kMaxDomainRules]{};
  size_t m_count{0};
};

} // namespace Ext::Config
