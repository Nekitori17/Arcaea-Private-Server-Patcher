#include "HookManager.h"

#include <cstdlib>
#include <pthread.h>
#include <unistd.h>

#include "ElfPltHook.h"
#include "MemoryUtils.h"

#define LOG_MODULE_TAG "HookManager"
#include "Logger.h"

namespace Ext::Core {

namespace {

constexpr int kRetryAttempts = 50;
constexpr useconds_t kRetryDelayUs = 200 * 1000;

pthread_mutex_t s_lock = PTHREAD_MUTEX_INITIALIZER;
bool s_claimed = false;

struct WatchContext {
  const char *module_name;
};

bool try_claim() {
  pthread_mutex_lock(&s_lock);
  bool ok = !s_claimed;
  if (ok)
    s_claimed = true;
  pthread_mutex_unlock(&s_lock);
  return ok;
}

void on_target_module_loaded(void *module_base) {
  HookManager::instance().install_all(module_base);
  HookManager::instance().print_summary();
}

void execute_callback(const char *module_name, void *base) {
  LOGI("Module %s mapped @ %p -> executing hook installer", module_name, base);
  on_target_module_loaded(base);
}

void *retry_worker(void *arg) {
  auto *ctx = static_cast<WatchContext *>(arg);
  for (int i = 0; i < kRetryAttempts; i++) {
    void *base = Ext::Utils::find_module_base(ctx->module_name);
    if (base) {
      if (try_claim())
        execute_callback(ctx->module_name, base);
      free(ctx);
      return nullptr;
    }
    usleep(kRetryDelayUs);
  }
  LOGE("Timed out waiting for %s after ~%ds", ctx->module_name,
       (kRetryAttempts * kRetryDelayUs) / 1000000);
  free(ctx);
  return nullptr;
}

int watch_and_install(const char *module_name) {
  if (!module_name || !module_name[0])
    return -1;

  void *base = Ext::Utils::find_module_base(module_name);
  if (base) {
    if (try_claim())
      execute_callback(module_name, base);
    else
      LOGI("Module watcher already triggered; skipping");
    return 1;
  }

  LOGW("%s not loaded yet; polling in background (~10s)", module_name);
  auto *ctx = static_cast<WatchContext *>(malloc(sizeof(WatchContext)));
  if (!ctx) {
    LOGE("Out of memory allocating WatchContext");
    return -1;
  }
  ctx->module_name = module_name;

  pthread_t tid;
  if (pthread_create(&tid, nullptr, retry_worker, ctx) != 0) {
    LOGE("Failed to spawn module watcher thread");
    free(ctx);
    return -1;
  }
  pthread_detach(tid);
  return 0;
}

} // namespace

HookManager &HookManager::instance() {
  static HookManager s_instance;
  return s_instance;
}

bool HookManager::register_module(const HookModule *mod) {
  if (!mod || !mod->install || m_module_count >= kMaxHookModules) {
    LOGE("Failed to register hook module '%s'",
         (mod && mod->name) ? mod->name : "(null)");
    return false;
  }
  m_modules[m_module_count++] = mod;
  return true;
}

bool HookManager::hook_plt_symbol(void *module_base, const char *group_name,
                                  const char *symbol_name, void *hook_func,
                                  void **orig_func, bool optional) {
  int rc = plt_hook_symbol(module_base, symbol_name, hook_func, orig_func);
  bool ok = (rc == 0);

  if (m_record_count < kMaxHookRecords) {
    HookRecord &rec = m_records[m_record_count++];
    rec.module_name = group_name ? group_name : "General";
    rec.symbol_name = symbol_name;
    rec.orig_func = orig_func ? *orig_func : nullptr;
    rec.hook_func = hook_func;
    rec.success = ok;
    rec.optional = optional;
  }

  return ok;
}

void HookManager::install_all(void *module_base) {
  if (!module_base)
    return;

  m_record_count = 0;
  for (size_t i = 0; i < m_module_count; i++) {
    const HookModule *m = m_modules[i];
    if (m && m->install) {
      m->install(module_base);
    }
  }
}

int HookManager::start(const char *target_library) {
  if (!target_library || !target_library[0])
    return -1;
  return watch_and_install(target_library);
}

void HookManager::print_summary() const {
  size_t installed = 0;
  size_t skipped_opt = 0;
  size_t failed_req = 0;

  for (size_t i = 0; i < m_record_count; i++) {
    if (m_records[i].success)
      installed++;
    else if (m_records[i].optional)
      skipped_opt++;
    else
      failed_req++;
  }

  LOGI("==========================================================");
  LOGI("              ArcExt Hook Manager Summary                 ");
  LOGI("==========================================================");
  LOGI("Total: %zu | Installed: %zu | Optional-Skipped: %zu | Failed: %zu",
       m_record_count, installed, skipped_opt, failed_req);
  LOGI("----------------------------------------------------------");

  for (size_t i = 0; i < m_record_count; i++) {
    const HookRecord &r = m_records[i];
    if (r.success) {
      LOGI("  [OK]   %-14s :: %-34s (%p -> %p)", r.module_name, r.symbol_name,
           r.orig_func, r.hook_func);
    } else if (r.optional) {
      LOGW("  [SKIP] %-14s :: %-34s (not in PLT / static)", r.module_name,
           r.symbol_name);
    } else {
      LOGE("  [FAIL] %-14s :: %-34s", r.module_name, r.symbol_name);
    }
  }
  LOGI("==========================================================");
}

} // namespace Ext::Core
