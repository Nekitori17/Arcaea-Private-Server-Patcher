#include "DomainMatcher.h"

#include "NetStringUtils.h"

namespace Ext::Config {

namespace {

bool is_lowiro_domain(const char *host) {
  return Ext::Utils::host_ends_with(host, ".lowiro.com") ||
         Ext::Utils::host_equals(host, "lowiro.com");
}

} // namespace

size_t find_matching_rule_index(const char *hostname) {
  if (!hostname || !hostname[0])
    return kRuleNotFound;

  const auto &table = DomainRuleTable::instance();
  const size_t total = table.count();

  for (size_t i = 0; i < total; i++) {
    const DomainRule *rule = table.get(i);
    if (rule && Ext::Utils::host_equals(rule->original, hostname))
      return i;
  }

  if (is_lowiro_domain(hostname)) {
    for (size_t i = 0; i < total; i++) {
      const DomainRule *rule = table.get(i);
      if (rule && is_lowiro_domain(rule->original))
        return i;
    }
  }

  return kRuleNotFound;
}

const DomainRule *find_matching_rule(const char *hostname) {
  size_t idx = find_matching_rule_index(hostname);
  return (idx != kRuleNotFound) ? DomainRuleTable::instance().get(idx) : nullptr;
}

} // namespace Ext::Config
