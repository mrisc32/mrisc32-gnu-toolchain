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

function help {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --help     Show this text"
    echo "  --clean    Clean all the output folders"
    echo "  --update   Update the Git submodules"
    echo "  all        Build all components (default)"
    echo "  binutils   Build only binutils"
    echo "  bootstrap  Build only the bootstrap version of GCC (requires binutils)"
    echo "  newlib     Build only newlib (requires bootstrap)"
    echo "  gcc        Build only GCC (requires newlib)"
}

# Parse arguments.
DO_CLEAN=no
DO_UPDATE=no
BUILD_BINUTILS=yes
BUILD_BOOTSTRAP=yes
BUILD_NEWLIB=yes
BUILD_GCC=yes
for arg in "$@" ; do
    if [ "$arg" == "--help" ] ; then
        help
        exit 0
    elif [ "$arg" == "--clean" ] ; then
        DO_CLEAN=yes
    elif [ "$arg" == "--update" ] ; then
        DO_UPDATE=yes
    elif [ "$arg" == "all" ] ; then
        BUILD_BINUTILS=yes
        BUILD_BOOTSTRAP=yes
        BUILD_NEWLIB=yes
        BUILD_GCC=yes
    elif [ "$arg" == "binutils" ] ; then
        BUILD_BINUTILS=yes
        BUILD_BOOTSTRAP=no
        BUILD_NEWLIB=no
        BUILD_GCC=no
    elif [ "$arg" == "bootstrap" ] ; then
        BUILD_BINUTILS=no
        BUILD_BOOTSTRAP=yes
        BUILD_NEWLIB=no
        BUILD_GCC=no
    elif [ "$arg" == "newlib" ] ; then
        BUILD_BINUTILS=no
        BUILD_BOOTSTRAP=no
        BUILD_NEWLIB=yes
        BUILD_GCC=no
    elif [ "$arg" == "gcc" ] ; then
        BUILD_BINUTILS=no
        BUILD_BOOTSTRAP=no
        BUILD_NEWLIB=no
        BUILD_GCC=yes
    else
        echo "*** Invalid argument: $arg"
        help
        exit 1
    fi
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

# Check dependencies.
# TODO(m): Implement me!

# Update the git submodules.
if [ "$DO_UPDATE" == "yes" ] ; then
    git submodule update --init --recursive
fi

# Clean all the build results.
mkdir -p out
if [ "$DO_CLEAN" == "yes" ] ; then
    rm -rf out/*
fi

# Create the install root.
INSTALL_ROOT="$PWD/out/install"
mkdir -p "$INSTALL_ROOT"
PATH="$INSTALL_ROOT/bin:$PATH"

# Toolchain configuration.
TARGET=mrisc32-elf

#
# This is inspired by http://www.ifp.illinois.edu/~nakazato/tips/xgcc.html
#

set -e

# Build binutils.
if [ "$BUILD_BINUTILS" == "yes" ] ; then
    echo "====> Building binutils"
    mkdir -p out/binutils
    cd out/binutils
    ../../ext/binutils-mrisc32/configure \
        --prefix="$INSTALL_ROOT" \
        --target="$TARGET" \
        --with-system-zlib \
        --disable-gdb \
        --disable-sim \
        > configure.log 2>&1
    make all > build.log 2>&1
    make install > install.log 2>&1
    cd ../..
fi

# Build bootstrap gcc.
if [ "$BUILD_BOOTSTRAP" == "yes" ] ; then
    echo "====> Building bootstrap GCC"
    mkdir -p out/gcc-bootstrap
    cd out/gcc-bootstrap
    ../../ext/gcc-mrisc32/configure \
      --prefix="$INSTALL_ROOT" \
      --target="$TARGET" \
      --enable-languages=c \
      --without-headers \
      --with-newlib \
      --with-gnu-as \
      --with-gnu-ld \
      > configure.log 2>&1
    make -j20 all-gcc > build.log 2>&1
    make install-gcc > install.log 2>&1
    cd ../..
fi

# Build newlib.
if [ "$BUILD_NEWLIB" == "yes" ] ; then
    echo "====> Building newlib"
    mkdir -p out/newlib
    cd out/newlib
    ../../ext/newlib-mrisc32/configure \
      --prefix="$INSTALL_ROOT" \
      --target="$TARGET" \
      > configure.log 2>&1
    make -j20 all > build.log 2>&1
    make install > install.log 2>&1
    cd ../..
fi

# Build gcc with newlib.
if [ "$BUILD_GCC" == "yes" ] ; then
    echo "====> Building GCC"
    mkdir -p out/gcc
    cd out/gcc
    ../../ext/gcc-mrisc32/configure \
      --prefix="$INSTALL_ROOT" \
      --target="$TARGET" \
      --enable-languages=c \
      --with-newlib \
      --with-gnu-as \
      --with-gnu-ld \
      --disable-shared \
      --disable-libssp \
      > configure.log 2>&1
    make -j20 all > build.log 2>&1
    make install > install.log 2>&1
    cd ../..
fi

# Pack it all into a tar file.
echo "====> Creating tarball"
cd out/install
tar -caf ../mrisc32-gnu-toolchain.tar.gz ./*
cd ../..

