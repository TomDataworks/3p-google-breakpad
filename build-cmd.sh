#!/bin/sh

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

# load autobuild provided shell functions and variables
# first remap the autobuild env to fix the path for sickwin
if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage="$(pwd)/stage"
LIBRARY_DIRECTORY_DEBUG=$stage/lib/debug
LIBRARY_DIRECTORY_RELEASE=$stage/lib/release
BINARY_DIRECTORY=$stage/bin
INCLUDE_DIRECTORY=$stage/include/google_breakpad
mkdir -p "$LIBRARY_DIRECTORY_DEBUG"
mkdir -p "$LIBRARY_DIRECTORY_RELEASE"
mkdir -p "$BINARY_DIRECTORY"
mkdir -p "$INCLUDE_DIRECTORY"
mkdir -p "$INCLUDE_DIRECTORY/common"
pushd "google-breakpad/src"
case "$AUTOBUILD_PLATFORM" in
    "windows")
        tools/gyp/gyp --no-circular-check -f msvs -G msvs_version=2013 client/windows/breakpad_client.gyp
        tools/gyp/gyp --no-circular-check -f msvs -G msvs_version=2013 tools/windows/dump_syms/dump_syms.gyp
        
        load_vsvars

        build_sln "client/windows/breakpad_client.sln" "Debug|Win32"
        build_sln "client/windows/breakpad_client.sln" "Release|Win32"

        build_sln "tools/windows/dump_syms/dump_syms.sln" "Release|Win32"

        mkdir -p "$INCLUDE_DIRECTORY/client/windows/"{common,crash_generation}
        mkdir -p "$INCLUDE_DIRECTORY/common/windows"
        mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
        mkdir -p "$INCLUDE_DIRECTORY/processor"

        cp client/windows/Debug/lib/common.lib "$LIBRARY_DIRECTORY_DEBUG"
        cp client/windows/Debug/lib/crash_generation_client.lib "$LIBRARY_DIRECTORY_DEBUG"
        cp client/windows/Debug/lib/crash_generation_server.lib "$LIBRARY_DIRECTORY_DEBUG"
        cp client/windows/Debug/lib/exception_handler.lib "$LIBRARY_DIRECTORY_DEBUG"

        cp client/windows/Release/lib/common.lib "$LIBRARY_DIRECTORY_RELEASE"
        cp client/windows/Release/lib/crash_generation_client.lib "$LIBRARY_DIRECTORY_RELEASE"
        cp client/windows/Release/lib/crash_generation_server.lib "$LIBRARY_DIRECTORY_RELEASE"
        cp client/windows/Release/lib/exception_handler.lib "$LIBRARY_DIRECTORY_RELEASE"

        cp client/windows/handler/exception_handler.h "$INCLUDE_DIRECTORY"
        cp client/windows/common/*.h "$INCLUDE_DIRECTORY/client/windows/common"
        cp common/windows/*.h "$INCLUDE_DIRECTORY/common/windows"
        cp client/windows/crash_generation/*.h "$INCLUDE_DIRECTORY/client/windows/crash_generation"
        cp google_breakpad/common/*.h "$INCLUDE_DIRECTORY/google_breakpad/common"
        cp tools/windows/dump_syms/Release/dump_syms.exe "$BINARY_DIRECTORY"
        cp common/scoped_ptr.h "$INCLUDE_DIRECTORY/common/scoped_ptr.h"
    ;;
    "windows64")
        tools/gyp/gyp --no-circular-check -f msvs -G msvs_version=2010 client/windows/breakpad_client.gyp
        tools/gyp/gyp --no-circular-check -f msvs -G msvs_version=2010 tools/windows/dump_syms/dump_syms.gyp
        
        load_vsvars

        build_sln "client/windows/breakpad_client.sln" "Debug|x64"
        build_sln "client/windows/breakpad_client.sln" "Release|x64"

        build_sln "tools/windows/dump_syms/dump_syms.sln" "Release|x64"

        mkdir -p "$INCLUDE_DIRECTORY/client/windows/"{common,crash_generation}
        mkdir -p "$INCLUDE_DIRECTORY/common/windows"
        mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
        mkdir -p "$INCLUDE_DIRECTORY/processor"

        cp client/windows/Debug/lib/common.lib "$LIBRARY_DIRECTORY_DEBUG"
        cp client/windows/Debug/lib/crash_generation_client.lib "$LIBRARY_DIRECTORY_DEBUG"
        cp client/windows/Debug/lib/crash_generation_server.lib "$LIBRARY_DIRECTORY_DEBUG"
        cp client/windows/Debug/lib/exception_handler.lib "$LIBRARY_DIRECTORY_DEBUG"

        cp client/windows/Release/lib/common.lib "$LIBRARY_DIRECTORY_RELEASE"
        cp client/windows/Release/lib/crash_generation_client.lib "$LIBRARY_DIRECTORY_RELEASE"
        cp client/windows/Release/lib/crash_generation_server.lib "$LIBRARY_DIRECTORY_RELEASE"
        cp client/windows/Release/lib/exception_handler.lib "$LIBRARY_DIRECTORY_RELEASE"

        cp client/windows/handler/exception_handler.h "$INCLUDE_DIRECTORY"
        cp client/windows/common/*.h "$INCLUDE_DIRECTORY/client/windows/common"
        cp common/windows/*.h "$INCLUDE_DIRECTORY/common/windows"
        cp client/windows/crash_generation/*.h "$INCLUDE_DIRECTORY/client/windows/crash_generation"
        cp google_breakpad/common/*.h "$INCLUDE_DIRECTORY/google_breakpad/common"
        cp tools/windows/dump_syms/Release/dump_syms.exe "$BINARY_DIRECTORY"
        cp common/scoped_ptr.h "$INCLUDE_DIRECTORY/common/scoped_ptr.h"
    ;;
    darwin)
        (
            cmake -G Xcode CMakeLists.txt
            xcodebuild -project google_breakpad.xcodeproj -configuration Release
        )
        xcodebuild -project tools/mac/dump_syms/dump_syms.xcodeproj MACOSX_DEPLOYMENT_TARGET=10.7 GCC_VERSION=com.apple.compilers.llvm.clang.1_0 -sdk macosx10.8 -configuration Release
        mkdir -p "$INCLUDE_DIRECTORY/processor"
        mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
        mkdir -p "$INCLUDE_DIRECTORY/client/mac/crash_generation"
        mkdir -p "$INCLUDE_DIRECTORY/client/mac/crash_generation/common/mac"
        mkdir -p "$INCLUDE_DIRECTORY/client/mac/handler"
        cp client/mac/handler/exception_handler.h "$INCLUDE_DIRECTORY"
        cp client/mac/handler/ucontext_compat.h "$INCLUDE_DIRECTORY/client/mac/handler"
        cp client/mac/crash_generation/crash_generation_client.h "$INCLUDE_DIRECTORY/client/mac/crash_generation"
        cp common/mac/MachIPC.h "$INCLUDE_DIRECTORY/client/mac/crash_generation/common/mac"
        cp client/mac/handler/Release/libexception_handler.dylib "$LIBRARY_DIRECTORY_RELEASE"
        cp tools/mac/dump_syms/build/Release/dump_syms "$BINARY_DIRECTORY"
        cp common/scoped_ptr.h "$INCLUDE_DIRECTORY/common/scoped_ptr.h"
    ;;
    linux)
        VIEWER_FLAGS="-m32 -fno-stack-protector"

        if [ -f /usr/bin/gcc-4.1 ] ; then
            export CC=gcc-4.1
        else
            export CC=gcc
        fi

        if [ -f /usr/bin/g++-4.1 ] ; then
            export CXX=g++-4.1
        else
            export CXX=g++
        fi

        ./configure --prefix="$(pwd)/stage" CFLAGS="$VIEWER_FLAGS" CXXFLAGS="$VIEWER_FLAGS" LDFLAGS=-m32
        make
        make -C src/tools/linux/dump_syms/ dump_syms
        make install

        mkdir -p "$INCLUDE_DIRECTORY/processor"
        mkdir -p "$INCLUDE_DIRECTORY/common"
        mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/handler"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/crash_generation"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/minidump_writer"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/log"
        mkdir -p "$INCLUDE_DIRECTORY/third_party/lss"

        # replicate breakpad headers
        cp src/common/*.h "$INCLUDE_DIRECTORY/common"
        cp src/google_breakpad/common/*.h "$INCLUDE_DIRECTORY/google_breakpad/common"

        # no really all of them
        cp src/client/linux/crash_generation/*.h "$INCLUDE_DIRECTORY/client/linux/crash_generation/"
        cp src/client/linux/handler/*.h "$INCLUDE_DIRECTORY/client/linux/handler/"
        cp src/client/linux/minidump_writer/*.h "$INCLUDE_DIRECTORY/client/linux/minidump_writer/"
        cp src/client/linux/log/*.h "$INCLUDE_DIRECTORY/client/linux/log/"
        cp src/third_party/lss/* "$INCLUDE_DIRECTORY/third_party/lss/"

        # and then cherry-pick some so they are found as used by linden
        cp src/client/linux/handler/*.h "$INCLUDE_DIRECTORY"
        cp src/common/using_std_string.h "$INCLUDE_DIRECTORY"
        cp src/client/linux/handler/exception_handler.h "$INCLUDE_DIRECTORY"
        cp src/client/linux/handler/exception_handler.h "$INCLUDE_DIRECTORY/google_breakpad/"
        cp src/client/linux/handler/minidump_descriptor.h "$INCLUDE_DIRECTORY"
        cp src/client/linux/handler/minidump_descriptor.h "$INCLUDE_DIRECTORY/google_breakpad/"

        cp src/processor/scoped_ptr.h "$INCLUDE_DIRECTORY/processor/scoped_ptr.h"
        cp src/common/scoped_ptr.h "$INCLUDE_DIRECTORY/common/scoped_ptr.h"

        # libs and binaries
        cp -P stage/lib/libbreakpad*.a* "$LIBRARY_DIRECTORY_RELEASE"
        cp src/tools/linux/dump_syms/dump_syms "$BINARY_DIRECTORY"
    ;;
esac

mkdir -p $stage/LICENSES
cp ../LICENSE $stage/LICENSES/google_breakpad.txt
popd
pass
