#!/bin/bash
##############################################################################
# Copyright (c) 2020 Marcus Geelnard
#
# This software is provided 'as-is', without any express or implied warranty.
# In no event will the authors be held liable for any damages arising from the
# use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
#  1. The origin of this software must not be misrepresented; you must not
#     claim that you wrote the original software. If you use this software in
#     a product, an acknowledgment in the product documentation would be
#     appreciated but is not required.
#
#  2. Altered source versions must be plainly marked as such, and must not be
#     misrepresented as being the original software.
#
#  3. This notice may not be removed or altered from any source distribution.
##############################################################################

err_report() {
    echo "*** Failed to build: Stopped on line $1"
    if [ -n "${LATEST_LOG}" ] ; then
        echo ""
        echo "Latest log:"
        cat "${LATEST_LOG}"
    fi
}
trap 'err_report $LINENO' ERR
set -e

function help {
    echo "Usage: $0 [options] [component]"
    echo ""
    echo "Build and install the MRISC32 GNU toolchain."
    echo ""
    echo "Options:"
    echo "  --prefix=PATH  Set installation path (default: $HOME/.local)"
    echo "  -c, --clean    Clean the build directories before building"
    echo "  -u, --update   Update the Git submodules"
    echo "  -jN            Use N parallel processes (note: no space)"
    echo "  -h, --help     Show this text"
    echo ""
    echo "Component:"
    echo "  all            Build all components (default)"
    echo "  binutils       Build only binutils"
    echo "  bootstrap      Build only the bootstrap version of GCC"
    echo "                   (requires binutils)"
    echo "  newlib         Build only newlib"
    echo "                   (requires bootstrap)"
    echo "  gcc            Build only GCC"
    echo "                   (requires newlib)"
}

# Parse arguments.
DO_CLEAN=no
DO_UPDATE=no
PREFIX="$HOME/.local"
BUILD_BINUTILS=yes
BUILD_BOOTSTRAP=yes
BUILD_NEWLIB=yes
BUILD_GCC=yes
NUM_PROCESSES=""
for arg in "$@" ; do
    case $arg in
        -h|--help)
            help
            exit 0
            ;;
        -c|--clean)
            DO_CLEAN=yes
            ;;
        -u|--update)
            DO_UPDATE=yes
            ;;
        -j*)
            NUM_PROCESSES="${arg:2}"
            ;;
        --prefix=*)
            PREFIX="${arg#*=}"
            ;;
        all)
            BUILD_BINUTILS=yes
            BUILD_BOOTSTRAP=yes
            BUILD_NEWLIB=yes
            BUILD_GCC=yes
            ;;
        binutils)
            BUILD_BINUTILS=yes
            BUILD_BOOTSTRAP=no
            BUILD_NEWLIB=no
            BUILD_GCC=no
            ;;
        bootstrap)
            BUILD_BINUTILS=no
            BUILD_BOOTSTRAP=yes
            BUILD_NEWLIB=no
            BUILD_GCC=no
            ;;
        newlib)
            BUILD_BINUTILS=no
            BUILD_BOOTSTRAP=no
            BUILD_NEWLIB=yes
            BUILD_GCC=no
            ;;
        gcc)
            BUILD_BINUTILS=no
            BUILD_BOOTSTRAP=no
            BUILD_NEWLIB=no
            BUILD_GCC=yes
            ;;
        *)
            echo "*** Invalid argument: $arg"
            help
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

# Determine number of parallel processes.
if [ -z "${NUM_PROCESSES}" ] ; then
    NUM_PROCESSES=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 8)
    if [ -z "${NUM_PROCESSES}" ]; then
        NUM_PROCESSES = 8
    fi
    ((NUM_PROCESSES=$NUM_PROCESSES+1))
fi
echo "INFO: Using ${NUM_PROCESSES} parallel processes where possible"
echo ""

# Check dependencies.
# TODO(m): Implement me!

# Update the git submodules.
if [ "$DO_UPDATE" == "yes" ] ; then
    git submodule update --init --recursive
fi

# Make sure that we have an output folder.
mkdir -p out

# Create the install root ($PREFIX), and make sure that it's the first in our
# PATH during installation.
mkdir -p "$PREFIX"
PATH="$PREFIX/bin:$PATH"

# Toolchain configuration.
TARGET=mrisc32-elf

#
# This is inspired by http://www.ifp.illinois.edu/~nakazato/tips/xgcc.html
#

# Build binutils.
if [ "$BUILD_BINUTILS" == "yes" ] ; then
    echo "==[ binutils - $TARGET ]=="
    if [ "$DO_CLEAN" == "yes" ] ; then
        echo "  Cleaning..."
        rm -rf out/binutils
    fi
    mkdir -p out/binutils

    echo "  Configuring..."
    cd out/binutils
    LATEST_LOG=${PWD}/configure.log
    ../../ext/binutils-mrisc32/configure \
        --prefix="$PREFIX" \
        --target="$TARGET" \
        --disable-gdb \
        --disable-sim \
        --without-zstd \
        > "${LATEST_LOG}" 2>&1

    echo "  Building..."
    LATEST_LOG=${PWD}/build.log
    MAKE_FLAGS=""
    if [ "$DO_CLEAN" == "yes" ] ; then
        # We only allow parallel make for clean builds, as it seems to cause problems for
        # incremental builds.
        MAKE_FLAGS=-j${NUM_PROCESSES}
    fi
    make ${MAKE_FLAGS} all > "${LATEST_LOG}" 2>&1

    echo "  Installing..."
    LATEST_LOG=${PWD}/install.log
    make install > "${LATEST_LOG}" 2>&1
    cd ../..
    echo ""
fi

# Build bootstrap gcc.
if [ "$BUILD_BOOTSTRAP" == "yes" ] ; then
    echo "==[ Bootstrap (minimal) GCC - $TARGET ]=="
    if [ "$DO_CLEAN" == "yes" ] ; then
        echo "  Cleaning..."
        rm -rf out/gcc-bootstrap
    fi
    mkdir -p out/gcc-bootstrap
    echo "  Downloading prerequisites..."
    cd ext/gcc-mrisc32
    LATEST_LOG=../../out/gcc-bootstrap/prerequisites.log
    ./contrib/download_prerequisites > "${LATEST_LOG}" 2>&1
    cd ../..

    echo "  Configuring..."
    cd out/gcc-bootstrap
    LATEST_LOG=${PWD}/configure.log
    ../../ext/gcc-mrisc32/configure \
      --prefix="$PREFIX" \
      --target="$TARGET" \
      --enable-languages=c \
      --without-headers \
      --with-newlib \
      --with-gnu-as \
      --with-gnu-ld \
      --without-zstd \
      > "${LATEST_LOG}" 2>&1

    echo "  Building..."
    LATEST_LOG=${PWD}/build.log
    make -j"${NUM_PROCESSES}" all-gcc > "${LATEST_LOG}" 2>&1

    echo "  Installing (temporary)..."
    LATEST_LOG=${PWD}/install.log
    make install-gcc > "${LATEST_LOG}" 2>&1
    cd ../..
    echo ""
fi

# Build newlib.
if [ "$BUILD_NEWLIB" == "yes" ] ; then
    echo "==[ newlib - $TARGET ]=="
    if [ "$DO_CLEAN" == "yes" ] ; then
        echo "  Cleaning..."
        rm -rf out/newlib
    fi
    mkdir -p out/newlib

    echo "  Configuring..."
    cd out/newlib
    LATEST_LOG=${PWD}/configure.log
    ../../ext/newlib-mrisc32/configure \
      --prefix="$PREFIX" \
      --target="$TARGET" \
      > "${LATEST_LOG}" 2>&1

    echo "  Building..."
    LATEST_LOG=${PWD}/build.log
    make -j"${NUM_PROCESSES}" all > "${LATEST_LOG}" 2>&1

    echo "  Installing..."
    LATEST_LOG=${PWD}/install.log
    make install > "${LATEST_LOG}" 2>&1
    cd ../..
    echo ""
fi

# Build gcc with newlib.
if [ "$BUILD_GCC" == "yes" ] ; then
    echo "==[ GCC - $TARGET ]=="
    if [ "$DO_CLEAN" == "yes" ] ; then
        echo "  Cleaning..."
        rm -rf out/gcc
    fi
    mkdir -p out/gcc
    echo "  Downloading prerequisites..."
    cd ext/gcc-mrisc32
    LATEST_LOG=../../out/gcc/prerequisites.log
    ./contrib/download_prerequisites > "${LATEST_LOG}" 2>&1
    cd ../..

    echo "  Configuring..."
    cd out/gcc
    LATEST_LOG=${PWD}/configure.log
    ../../ext/gcc-mrisc32/configure \
      --prefix="$PREFIX" \
      --target="$TARGET" \
      --enable-languages=c,c++ \
      --with-newlib \
      --with-gnu-as \
      --with-gnu-ld \
      --disable-shared \
      --disable-libssp \
      --disable-libstdcxx-pch \
      --without-zstd \
      > "${LATEST_LOG}" 2>&1

    echo "  Building..."
    LATEST_LOG=${PWD}/build.log
    make -j"${NUM_PROCESSES}" all > "${LATEST_LOG}" 2>&1

    echo "  Installing..."
    LATEST_LOG=${PWD}/install.log
    make install > "${LATEST_LOG}" 2>&1
    cd ../..
    echo ""
fi

# Strip binaries.
echo "Stripping binaries..."
find "${PREFIX}/bin" -executable -type f -exec strip {} \; 2>/dev/null || true
find "${PREFIX}/libexec/gcc" -name 'cc1*' -executable -type f -exec strip {} \; 2>/dev/null || true
find "${PREFIX}/libexec/gcc" -name 'lto-wrapper*' -executable -type f -exec strip {} \; 2>/dev/null || true
find "${PREFIX}/libexec/gcc" -name 'collect2*' -executable -type f -exec strip {} \; 2>/dev/null || true
find "${PREFIX}/libexec/gcc" -name 'd21*' -executable -type f -exec strip {} \; 2>/dev/null || true
find "${PREFIX}/libexec/gcc" -name 'lto1*' -executable -type f -exec strip {} \; 2>/dev/null || true
find "${PREFIX}/${TARGET}/bin" -executable -type f -exec strip {} \; 2>/dev/null || true
echo ""

echo "Build and installation finished succesfully!"

