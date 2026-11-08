#pragma once

#include <cstddef>

namespace Ext::Core {

/**
 * Installs an inline detour hook on the target function.
 * Allocates an executable trampoline so the original function can still be called.
 *
 * Supports:
 * - AArch64 (ARM64): 16-byte absolute detour (LDR X16, #8; BR X16; target)
 * - ARM32 (A32): 8-byte PC-relative detour (LDR PC, [PC, #-4]; target)
 *
 * @param target Pointer to the target function to hook.
 * @param hook_func Pointer to the replacement hook function.
 * @param orig_func Output pointer receiving the callable trampoline to the original function (can be nullptr).
 * @return true if hook was successfully installed; false otherwise.
 */
bool inline_hook(void *target, void *hook_func, void **orig_func);

} // namespace Ext::Core

