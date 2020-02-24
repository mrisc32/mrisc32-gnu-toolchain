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

# Check dependencies.
# TODO(m): Implement me!

# Update the git submodules.
git submodule update --init --recursive

# Start clean.
mkdir -p out
rm -rf out/*

# Create the install root.
INSTALL_ROOT="$PWD/out/install"
mkdir -p "$INSTALL_ROOT"
PATH="$INSTALL_ROOT/bin:$PATH"

# Build binutils.
mkdir -p out/binutils
cd out/binutils
../../ext/binutils-mrisc32/configure \
  --prefix="$INSTALL_ROOT" \
  --target=mrisc32 \
  --program-prefix=mrisc32-elf- \
  --with-system-zlib \
  --disable-gdb \
  --disable-sim
make && make install
cd ../..

# Build a minimal gcc.
mkdir -p out/gcc
cd out/gcc
../../ext/gcc-mrisc32/configure \
  --prefix="$INSTALL_ROOT" \
  --target=mrisc32-elf \
  --program-prefix=mrisc32-elf- \
  --enable-languages=c \
  --disable-libssp \
  --disable-libquadmath \
  --without-newlib
make -j20 && make install
cd ../..

