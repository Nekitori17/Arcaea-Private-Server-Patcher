cmake_minimum_required(VERSION 3.22.1)

project("ext" LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_C_STANDARD 11)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

file(GLOB_RECURSE EXT_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
)

add_library(ext SHARED ${EXT_SOURCES})

target_include_directories(ext PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/core"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/config"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/hooks"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/utils"
)

target_compile_definitions(ext PRIVATE
  ANDROID
  NDEBUG
)

target_compile_options(ext PRIVATE
  -Wall
  -Wextra
  -Wno-unused-parameter
  -Oz
  -flto=thin
  -ffunction-sections
  -fdata-sections
  -fvisibility=hidden
  -fvisibility-inlines-hidden
  -fno-exceptions
  -fno-rtti
)

set_target_properties(ext PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  C_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
)

target_link_options(ext PRIVATE
  -flto=thin
  -Wl,--gc-sections
  -Wl,--icf=all
  -Wl,--exclude-libs,ALL
  -Wl,-s
)

if(ANDROID)
  target_link_libraries(ext PRIVATE
    log
    dl
  )
endif()
