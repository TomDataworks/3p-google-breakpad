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

BREAKPAD_VERSION="1474"

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

echo "${BREAKPAD_VERSION}" > "${stage}/VERSION.txt"

pushd "google-breakpad"
case "$AUTOBUILD_PLATFORM" in
    "windows")
    pushd "src"
        tools/gyp/gyp --no-circular-check -f msvs -G msvs_version=2015 client/windows/breakpad_client.gyp
        tools/gyp/gyp --no-circular-check -f msvs -G msvs_version=2015 tools/windows/dump_syms/dump_syms.gyp
        
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
    popd
    ;;
    "windows64")
    pushd "src"
        tools/gyp/gyp --no-circular-check -f msvs -G msvs_version=2015 client/windows/breakpad_client.gyp
        tools/gyp/gyp --no-circular-check -f msvs -G msvs_version=2015 tools/windows/dump_syms/dump_syms.gyp
        
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
    popd
    ;;
    darwin)
    pushd "src"
        (
            cmake -G Xcode CMakeLists.txt
            xcodebuild -project google_breakpad.xcodeproj \
            MACOSX_DEPLOYMENT_TARGET=10.8 \
            GCC_VERSION=com.apple.compilers.llvm.clang.1_0 \
            CMAKE_OSX_ARCHITECTURES="i386;x86_64" \
            CLANG_CXX_LIBRARY="libc++" \
            CLANG_CXX_LANGUAGE_STANDARD="c++11" \
            -sdk macosx10.10 -configuration Release
        )
        xcodebuild -project tools/mac/dump_syms/dump_syms.xcodeproj \
            MACOSX_DEPLOYMENT_TARGET=10.8 \
            GCC_VERSION=com.apple.compilers.llvm.clang.1_0 \
            CMAKE_OSX_ARCHITECTURES="i386;x86_64" \
            CLANG_CXX_LIBRARY="libc++" \
            CLANG_CXX_LANGUAGE_STANDARD="c++11" \
            -sdk macosx10.10 -configuration Release
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
    popd
    ;;
    linux64)
        # Linux build environment at Linden comes pre-polluted with stuff that can
        # seriously damage 3rd-party builds.  Environmental garbage you can expect
        # includes:
        #
        #    DISTCC_POTENTIAL_HOSTS     arch           root        CXXFLAGS
        #    DISTCC_LOCATION            top            branch      CC
        #    DISTCC_HOSTS               build_name     suffix      CXX
        #    LSDISTCC_ARGS              repo           prefix      CFLAGS
        #    cxx_version                AUTOBUILD      SIGN        CPPFLAGS
        #
        # So, clear out bits that shouldn't affect our configure-directed build
        # but which do nonetheless.
        #
        # unset DISTCC_HOSTS CC CXX CFLAGS CPPFLAGS CXXFLAGS

        # Default target to 64-bit
        opts="${TARGET_OPTS:--m64}"
        # Hardened toolchain flags
        HARDENED="-fstack-protector-strong -D_FORTIFY_SOURCE=2"
        # Number of cpu cores for build
        JOBS=`cat /proc/cpuinfo | grep processor | wc -l`

        # Handle any deliberate platform targeting
        if [ -z "$TARGET_CPPFLAGS" ]; then
            # Remove sysroot contamination from build environment
            unset CPPFLAGS
        else
            # Incorporate special pre-processing flags
            export CPPFLAGS="$TARGET_CPPFLAGS"
        fi

        # Debug first
        CFLAGS="$opts -Og -g -fPIC -DPIC" CXXFLAGS="$opts -Og -g -std=c++11 -fPIC -DPIC" \
             ./configure --prefix="$stage" --libdir="$stage/lib/debug"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check -j$JOBS
        fi

        # clean the build artifacts
        make distclean

        # Release last
        CFLAGS="$opts -O3 -g $HARDENED -fPIC -DPIC" CXXFLAGS="$opts -O3 -g -std=c++11 $HARDENED -fPIC -DPIC" \
             ./configure --prefix="$stage" --libdir="$stage/lib/release"
        make -j$JOBS
        make install

        # conditionally run unit tests
        if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
            make check -j$JOBS
        fi

        # clean the build artifacts
        make distclean

        # strip binaries
        strip -S $BINARY_DIRECTORY/dump_syms

        # include directories
        mkdir -p "$INCLUDE_DIRECTORY/processor"
        mkdir -p "$INCLUDE_DIRECTORY/common"
        mkdir -p "$INCLUDE_DIRECTORY/google_breakpad/common"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/handler"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/crash_generation"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/dump_writer_common"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/minidump_writer"
        mkdir -p "$INCLUDE_DIRECTORY/client/linux/log"
        mkdir -p "$INCLUDE_DIRECTORY/third_party/lss"

        # replicate breakpad headers
        cp src/common/*.h "$INCLUDE_DIRECTORY/common"
        cp src/google_breakpad/common/*.h "$INCLUDE_DIRECTORY/google_breakpad/common"

        # no really all of them
        cp src/client/linux/crash_generation/*.h "$INCLUDE_DIRECTORY/client/linux/crash_generation/"
        cp src/client/linux/handler/*.h "$INCLUDE_DIRECTORY/client/linux/handler/"
        cp src/client/linux/dump_writer_common/*.h "$INCLUDE_DIRECTORY/client/linux/dump_writer_common/"
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
    ;;
esac

mkdir -p $stage/LICENSES
cp LICENSE $stage/LICENSES/google_breakpad.txt
pass
