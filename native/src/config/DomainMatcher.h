#pragma once

#include <cstddef>

#include "DomainRuleTable.h"

namespace Ext::Config {

size_t find_matching_rule_index(const char *hostname);

const DomainRule *find_matching_rule(const char *hostname);

} // namespace Ext::Config
