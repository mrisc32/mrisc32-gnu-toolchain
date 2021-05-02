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
    echo "  Building..."
    mkdir -p out/binutils
    cd out/binutils
    ../../ext/binutils-mrisc32/configure \
        --prefix="$PREFIX" \
        --target="$TARGET" \
        --with-system-zlib \
        --disable-gdb \
        --disable-sim \
        > configure.log 2>&1
    make all > build.log 2>&1
    echo "  Installing..."
    make install > install.log 2>&1
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
    echo "  Building..."
    mkdir -p out/gcc-bootstrap
    cd out/gcc-bootstrap
    ../../ext/gcc-mrisc32/configure \
      --prefix="$PREFIX" \
      --target="$TARGET" \
      --enable-languages=c \
      --without-headers \
      --with-newlib \
      --with-gnu-as \
      --with-gnu-ld \
      > configure.log 2>&1
    make -j28 all-gcc > build.log 2>&1
    echo "  Installing (temporary)..."
    make install-gcc > install.log 2>&1
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
    echo "  Building..."
    mkdir -p out/newlib
    cd out/newlib
    ../../ext/newlib-mrisc32/configure \
      --prefix="$PREFIX" \
      --target="$TARGET" \
      > configure.log 2>&1
    make -j28 all > build.log 2>&1
    echo "  Installing..."
    make install > install.log 2>&1
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
    echo "  Building..."
    mkdir -p out/gcc
    cd out/gcc
    ../../ext/gcc-mrisc32/configure \
      --prefix="$PREFIX" \
      --target="$TARGET" \
      --enable-languages=c,c++,d \
      --with-newlib \
      --with-gnu-as \
      --with-gnu-ld \
      --disable-shared \
      --disable-libssp \
      > configure.log 2>&1
    make -j28 all > build.log 2>&1
    echo "  Installing..."
    make install > install.log 2>&1
    cd ../..
    echo ""
fi

echo "Build and installation finished succesfully!"

