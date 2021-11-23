#!/bin/bash
##############################################################################
# Copyright (c) 2021 Marcus Geelnard
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

# Set up the installation folder.
_install_dir=/opt/mrisc32-gcc
_install_dir_host=${SCRIPT_DIR}/out/install
mkdir -p "${_install_dir_host}"

# Build the docker image.
_container_name=mrisc32-gnu-toolchain-builder
docker build -q -t ${_container_name} ${SCRIPT_DIR}/docker

# Run the build inside the container.
_uid=$(id -u)
_gid=$(id -g)
docker run \
    --rm \
    -u "${_uid}":"${_gid}" \
    -v "${_install_dir_host}":"${_install_dir}" \
    -v "${SCRIPT_DIR}":/work \
    -w /work \
    ${_container_name} \
    ./build.sh --prefix="${_install_dir}" --clean

