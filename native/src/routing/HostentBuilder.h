#pragma once

#include <netdb.h>

#include "DomainRuleTable.h"

namespace Ext::Routing {

struct hostent *build_ipv4_hostent(const Ext::Config::DomainRule *rule);

} // namespace Ext::Routing
