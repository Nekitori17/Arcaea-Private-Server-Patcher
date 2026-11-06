#pragma once

namespace Ext::Core {

using ModuleLoadedCallback = void (*)(void *module_base);

int watch_module_load(const char *module_name, ModuleLoadedCallback callback);

} // namespace Ext::Core
