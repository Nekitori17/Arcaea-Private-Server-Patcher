#include "Main.h"

#include <pthread.h>

#include "HookEntry.h"

#define LOG_MODULE_TAG "Init"
#include "Logger.h"

namespace Ext {

namespace {

JavaVM *s_jvm = nullptr;
pthread_key_t s_thread_key;
pthread_once_t s_key_once = PTHREAD_ONCE_INIT;

void jni_thread_destructor(void *value) {
  if (s_jvm && value != nullptr) {
    s_jvm->DetachCurrentThread();
  }
}

void make_thread_key() {
  pthread_key_create(&s_thread_key, jni_thread_destructor);
}

} // namespace

void set_java_vm(JavaVM *vm) { s_jvm = vm; }

JavaVM *get_java_vm() { return s_jvm; }

JNIEnv *get_jni_env() {
  if (!s_jvm)
    return nullptr;

  JNIEnv *env = nullptr;
  jint res = s_jvm->GetEnv(reinterpret_cast<void **>(&env), JNI_VERSION_1_6);
  if (res == JNI_EDETACHED) {
    if (s_jvm->AttachCurrentThread(&env, nullptr) != 0) {
      LOGE("Failed to attach current thread to JVM");
      return nullptr;
    }
    pthread_once(&s_key_once, make_thread_key);
    pthread_setspecific(s_thread_key, reinterpret_cast<void *>(1));
  } else if (res != JNI_OK) {
    LOGE("Failed to obtain JNIEnv (code=%d)", res);
    return nullptr;
  }
  return env;
}

} // namespace Ext

extern "C" {

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void * /*reserved*/) {
  LOGI("libext.so loaded by JVM");
  Ext::set_java_vm(vm);
  return JNI_VERSION_1_6;
}

JNIEXPORT void JNICALL
Java_moe_ext_arc_core_NativeBridge_nativeInit(JNIEnv * /*env*/,
                                              jclass /*clazz*/) {
  Ext::init_hook_subsystem();
}

} // extern "C"
