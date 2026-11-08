#include "DomainRuleTable.h"

#include <cerrno>
#include <cstring>

#include "FileUtils.h"
#include "NetStringUtils.h"

#define LOG_MODULE_TAG "Config"
#include "Logger.h"

namespace Ext::Config {

namespace {

bool is_lowiro_domain(const char *host) {
  return Ext::Utils::host_ends_with(host, ".lowiro.com") ||
         Ext::Utils::host_equals(host, "lowiro.com");
}

} // namespace

DomainRuleTable &DomainRuleTable::instance() {
  static DomainRuleTable s_instance;
  return s_instance;
}

void DomainRuleTable::clear() {
  memset(m_rules, 0, sizeof(m_rules));
  m_count = 0;
}

size_t DomainRuleTable::count() const { return m_count; }

const DomainRule *DomainRuleTable::get(size_t index) const {
  return (index < m_count) ? &m_rules[index] : nullptr;
}

int DomainRuleTable::load_stream(FILE *fp) {
  if (!fp)
    return 0;

  clear();
  char line[512];

  while (Ext::Utils::read_line(fp, line, sizeof(line)) >= 0 &&
         m_count < kMaxDomainRules) {
    char *left = Ext::Utils::trim(line);
    if (!left || left[0] == '#' || left[0] == '\0')
      continue;

    char *delim = strchr(left, '=');
    if (!delim)
      continue;
    *delim = '\0';
    char *right = delim + 1;

    Ext::Utils::sanitize_host(left);
    Ext::Utils::sanitize_host(right);

    left = Ext::Utils::trim(left);
    right = Ext::Utils::trim(right);
    if (!left[0] || !right[0])
      continue;

    DomainRule &rule = m_rules[m_count];
    memset(&rule, 0, sizeof(rule));

    char orig_host[kMaxHostLength];
    char repl_host[kMaxHostLength];
    Ext::Utils::parse_host_port(left, orig_host, sizeof(orig_host),
                                &rule.orig_port);
    Ext::Utils::parse_host_port(right, repl_host, sizeof(repl_host),
                                &rule.repl_port);

    strncpy(rule.original, orig_host, sizeof(rule.original) - 1);
    strncpy(rule.replacement, repl_host, sizeof(rule.replacement) - 1);

    LOGI("Rule[%zu]: %s%s -> %s%s", m_count, rule.original,
         rule.orig_port ? " (port-filtered)" : "", rule.replacement,
         rule.repl_port ? " (port-redirect)" : "");
    m_count++;
  }

  return static_cast<int>(m_count);
}

int DomainRuleTable::load_file(const char *path) {
  if (!path || !path[0]) {
    LOGW("Empty domain config path");
    return 0;
  }

  FILE *fp = fopen(path, "r");
  if (!fp) {
    LOGW("Cannot open config at %s (errno=%d)", path, errno);
    return 0;
  }

  int loaded = load_stream(fp);
  fclose(fp);

  LOGI("Loaded %d domain rule(s) from %s", loaded, path);
  return loaded;
}

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
