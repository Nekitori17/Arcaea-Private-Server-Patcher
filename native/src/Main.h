#pragma once

#include <jni.h>

namespace Ext {

void set_java_vm(JavaVM *vm);
JavaVM *get_java_vm();
JNIEnv *get_jni_env();

} // namespace Ext
