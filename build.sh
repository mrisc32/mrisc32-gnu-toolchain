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

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

# Parse arguments.
DO_CLEAN=no
DO_UPDATE=no
for arg in "$@" ; do
    if [ "$arg" == "--clean" ] ; then
        DO_CLEAN=yes
    fi
    if [ "$arg" == "--update" ] ; then
        DO_UPDATE=yes
    fi
done

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

# Build bootstrap gcc.
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

# Build newlib.
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

# Build gcc with newlib.
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

