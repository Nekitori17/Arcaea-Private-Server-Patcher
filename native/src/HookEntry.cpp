#include "HookEntry.h"

#include <pthread.h>

#include "DomainRuleTable.h"
#include "FileUtils.h"
#include "HookManager.h"
#include "NetworkRedirectHook.h"
#include "SslVerifyBypassHook.h"

#define LOG_MODULE_TAG "HookEntry"
#include "Logger.h"

namespace Ext {

namespace {

constexpr const char *kTargetLibrary = "libcocos2dcpp.so";
constexpr const char *kConfigFilename = "domain.cfg";

pthread_once_t s_init_once = PTHREAD_ONCE_INIT;
bool s_init_ok = false;

void perform_init() {
  LOGI("========================================");
  LOGI("      Initializing ArcExt Native        ");
  LOGI("========================================");

  char cfg_path[Ext::Utils::kMaxPathLength] = {0};
  bool exists = Ext::Utils::resolve_app_file_path(kConfigFilename, cfg_path,
                                                  sizeof(cfg_path));
  LOGI("Domain config path: %s (exists=%d)", cfg_path, exists ? 1 : 0);

  auto &rule_table = Ext::Config::DomainRuleTable::instance();
  rule_table.load_file(cfg_path);
  if (rule_table.count() == 0) {
    LOGW("No redirect rules loaded; running in SSL-bypass-only mode");
  }

  auto &hm = Ext::Core::HookManager::instance();
  hm.register_module(Ext::Hooks::get_network_redirect_module());
  hm.register_module(Ext::Hooks::get_ssl_verify_bypass_module());

  s_init_ok = (hm.start(kTargetLibrary) >= 0);
}

} // namespace

bool init_hook_subsystem() {
  pthread_once(&s_init_once, perform_init);
  return s_init_ok;
}

} // namespace Ext
