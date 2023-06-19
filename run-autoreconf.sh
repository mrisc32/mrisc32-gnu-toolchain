#!/bin/bash
##############################################################################
# Copyright (c) 2023 Marcus Geelnard
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
    echo "Usage: $0"
    echo ""
    echo "Run automake in the different submodules."
}

# Parse arguments.
for arg in "$@" ; do
    case $arg in
        -h|--help)
            help
            exit 0
            ;;
        *)
            echo "*** Invalid argument: $arg"
            help
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Build the docker image.
ARCH=amd64
_container_name=mrisc32-gnu-toolchain-builder-${ARCH/\//-}
echo "Building the container ${_container_name}"
docker build \
    -q \
    -t ${_container_name} \
    --build-arg _cpu_arch="${ARCH}" \
    ${SCRIPT_DIR}/docker
echo ""

run_autoreconf_in_dir() {
    _work=${SCRIPT_DIR}
    _srcdir=$1
    _uid=$(id -u)
    _gid=$(id -g)
    echo "Running autoreconf in ${_work}/${_srcdir}"
    docker run \
        --rm \
        -u "${_uid}":"${_gid}" \
        -v "${_work}":/work \
        -w /work \
        -e CC="${CC:-cc}" \
        -e CXX="${CXX:-c++}" \
        -e CFLAGS="${CFLAGS:--O2}" \
        -e CXXFLAGS="${CXXFLAGS:--O2}" \
        -e LDFLAGS="${LDFLAGS:-}" \
        ${_container_name} \
        autoreconf "${_srcdir}"
}

# Run autoreconf inside the container.
run_automake_in_dir ext/binutils-mrisc32
run_automake_in_dir ext/binutils-mrisc32/bfd
run_automake_in_dir ext/binutils-mrisc32/gas
run_automake_in_dir ext/binutils-mrisc32/ld
run_automake_in_dir ext/binutils-mrisc32/opcodes

run_automake_in_dir ext/gcc-mrisc32
run_automake_in_dir ext/gcc-mrisc32/gcc
run_automake_in_dir ext/gcc-mrisc32/libgcc

run_automake_in_dir ext/newlib-mrisc32
run_automake_in_dir ext/newlib-mrisc32/newlib
run_automake_in_dir ext/newlib-mrisc32/libgloss

