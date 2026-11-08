#include "InlineHook.h"

#include <cstdint>
#include <cstring>
#include <sys/mman.h>

#include "MemoryUtils.h"

#define LOG_MODULE_TAG "InlineHook"
#include "Logger.h"

namespace Ext::Core {

namespace {

void *allocate_trampoline(size_t size) {
  static uint8_t *s_pool = nullptr;
  static size_t s_offset = 0;
  constexpr size_t kPageSize = 4096;

  size = (size + 15) & ~15;

  if (!s_pool || (s_offset + size) > kPageSize) {
    void *ptr = mmap(nullptr, kPageSize, PROT_READ | PROT_WRITE | PROT_EXEC,
                     MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (ptr == MAP_FAILED) {
      LOGE("Failed to allocate trampoline memory via mmap");
      return nullptr;
    }
    s_pool = static_cast<uint8_t *>(ptr);
    s_offset = 0;
  }

  void *result = s_pool + s_offset;
  s_offset += size;
  return result;
}

} // namespace

bool inline_hook(void *target, void *hook_func, void **orig_func) {
  if (!target || !hook_func)
    return false;

#if defined(__aarch64__)
  constexpr size_t kHookSize = 16;
  constexpr size_t kTrampolineSize = 32;

  uint8_t *tramp = static_cast<uint8_t *>(allocate_trampoline(kTrampolineSize));
  if (!tramp)
    return false;

  // 1. Copy first 16 bytes of original instructions to trampoline
  memcpy(tramp, target, kHookSize);

  // 2. Append jump back to (target + 16):
  //    LDR X16, #8   -> 0x58000050
  //    BR  X16       -> 0xD61F0200
  //    .quad (target + 16)
  uint32_t *tramp_code = reinterpret_cast<uint32_t *>(tramp + kHookSize);
  tramp_code[0] = 0x58000050; // ldr x16, #8
  tramp_code[1] = 0xD61F0200; // br x16
  uint64_t *tramp_target = reinterpret_cast<uint64_t *>(tramp + kHookSize + 8);
  *tramp_target = reinterpret_cast<uint64_t>(target) + kHookSize;

  Ext::Utils::flush_instruction_cache(tramp, kTrampolineSize);

  if (orig_func) {
    *orig_func = reinterpret_cast<void *>(tramp);
  }

  // 3. Overwrite target function prologue with jump to hook_func
  if (!Ext::Utils::make_pages_writable(target, kHookSize)) {
    LOGE("Failed to make target pages writable at %p", target);
    return false;
  }

  auto *hook_code = static_cast<uint32_t *>(target);
  hook_code[0] = 0x58000050; // ldr x16, #8
  hook_code[1] = 0xD61F0200; // br x16
  auto *hook_target = reinterpret_cast<uint64_t *>(static_cast<uint8_t *>(target) + 8);
  *hook_target = reinterpret_cast<uint64_t>(hook_func);

  Ext::Utils::flush_instruction_cache(target, kHookSize);
  return true;

#elif defined(__arm__)
  constexpr size_t kHookSize = 8;
  constexpr size_t kTrampolineSize = 16;

  uint8_t *tramp = static_cast<uint8_t *>(allocate_trampoline(kTrampolineSize));
  if (!tramp)
    return false;

  // 1. Copy first 8 bytes of original ARM instructions to trampoline
  memcpy(tramp, target, kHookSize);

  // 2. Append jump back to (target + 8):
  //    ldr pc, [pc, #-4] -> 0xE51FF004
  //    .word (target + 8)
  uint32_t *tramp_code = reinterpret_cast<uint32_t *>(tramp + kHookSize);
  tramp_code[0] = 0xE51FF004;
  tramp_code[1] = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(target) + kHookSize);

  Ext::Utils::flush_instruction_cache(tramp, kTrampolineSize);

  if (orig_func) {
    *orig_func = reinterpret_cast<void *>(tramp);
  }

  // 3. Overwrite target with jump to hook_func
  if (!Ext::Utils::make_pages_writable(target, kHookSize)) {
    LOGE("Failed to make target pages writable at %p", target);
    return false;
  }

  auto *hook_code = static_cast<uint32_t *>(target);
  hook_code[0] = 0xE51FF004; // ldr pc, [pc, #-4]
  hook_code[1] = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(hook_func));

  Ext::Utils::flush_instruction_cache(target, kHookSize);
  return true;

#else
  LOGE("Unsupported CPU architecture for inline_hook");
  return false;
#endif
}

} // namespace Ext::Core

