#pragma once

#include <cstddef>

namespace Ext::Core {

constexpr size_t kMaxHookModules = 16;
constexpr size_t kMaxHookRecords = 64;

using HookInstallCallback = void (*)(void *module_base);

struct HookModule {
  const char *name;
  HookInstallCallback install;
};

struct HookRecord {
  const char *module_name;
  const char *symbol_name;
  void *orig_func;
  void *hook_func;
  bool success;
  bool optional;
};

class HookManager {
public:
  static HookManager &instance();

  bool register_module(const HookModule *mod);

  bool hook_plt_symbol(void *module_base, const char *group_name,
                       const char *symbol_name, void *hook_func,
                       void **orig_func, bool optional = false);

  int start(const char *target_library);

  void install_all(void *module_base);

  void print_summary() const;

private:
  HookManager() = default;

  const HookModule *m_modules[kMaxHookModules]{};
  size_t m_module_count{0};

  HookRecord m_records[kMaxHookRecords]{};
  size_t m_record_count{0};
};

} // namespace Ext::Core
