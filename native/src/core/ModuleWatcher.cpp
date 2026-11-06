#include "ModuleWatcher.h"

#include <cstdlib>
#include <pthread.h>
#include <unistd.h>

#include "MemoryUtils.h"

#define LOG_MODULE_TAG "Watcher"
#include "Logger.h"

namespace Ext::Core {

namespace {

constexpr int kRetryAttempts = 50;
constexpr useconds_t kRetryDelayUs = 200 * 1000;

pthread_mutex_t s_lock = PTHREAD_MUTEX_INITIALIZER;
bool s_claimed = false;

struct WatchContext {
  const char *module_name;
  ModuleLoadedCallback callback;
};

bool try_claim() {
  pthread_mutex_lock(&s_lock);
  bool ok = !s_claimed;
  if (ok)
    s_claimed = true;
  pthread_mutex_unlock(&s_lock);
  return ok;
}

void execute_callback(const char *module_name, ModuleLoadedCallback callback,
                      void *base) {
  LOGI("Module %s mapped @ %p -> executing hook installer", module_name, base);
  callback(base);
}

void *retry_worker(void *arg) {
  auto *ctx = static_cast<WatchContext *>(arg);
  for (int i = 0; i < kRetryAttempts; i++) {
    void *base = Ext::Utils::find_module_base(ctx->module_name);
    if (base) {
      if (try_claim())
        execute_callback(ctx->module_name, ctx->callback, base);
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

} // namespace

int watch_module_load(const char *module_name, ModuleLoadedCallback callback) {
  if (!module_name || !callback)
    return -1;

  void *base = Ext::Utils::find_module_base(module_name);
  if (base) {
    if (try_claim())
      execute_callback(module_name, callback, base);
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
  ctx->callback = callback;

  pthread_t tid;
  if (pthread_create(&tid, nullptr, retry_worker, ctx) != 0) {
    LOGE("Failed to spawn module watcher thread");
    free(ctx);
    return -1;
  }
  pthread_detach(tid);
  return 0;
}

} // namespace Ext::Core
