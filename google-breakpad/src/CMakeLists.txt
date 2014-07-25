# -*- cmake -*-
cmake_minimum_required(VERSION 2.8)

project(google_breakpad)

IF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(CMAKE_OSX_SYSROOT macosx10.9)
    set(CMAKE_OSX_DEPLOYMENT_TARGET 10.7)
    set(CMAKE_XCODE_ATTRIBUTE_GCC_VERSION "com.apple.compilers.llvm.clang.1_0")
    set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++")
    set(CMAKE_OSX_ARCHITECTURES i386;x86_64)
    add_subdirectory("client/mac/handler")
ENDIF(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
