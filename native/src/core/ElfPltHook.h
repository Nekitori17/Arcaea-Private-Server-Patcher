#pragma once

namespace Ext::Core {

int plt_hook_symbol(void *module_base, const char *symbol_name, void *hook_func,
                    void **orig_func);

} // namespace Ext::Core
