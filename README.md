# MRISC32 GNU toolchain

This is a top level repository for building the MRISC32 toolchain.

Currently there are two methods for building the toolchain:

1. Natively on your host machine (recommended).
2. Using Docker.

# Host build

The build has only been tested on Ubuntu 20.04, but may work on other similar systems too.

## Prerequities

The following packages are required:

```bash
sudo apt install bison build-essential curl flex texinfo zlib1g-dev
```

## Building

To build and install the GNU toolchain for MRISC32, do:

```bash
git submodule update --init --recursive
./build.sh --clean --prefix="$HOME/.local"
```

For more options, see:

```bash
./build.sh --help
```

# Docker build

The Docker based build will produce a toolchain for Linux hosts.

## Prerequities

Install Docker.

## Building

To build the GNU toolchain for MRISC32, do:

```bash
git submodule update --init --recursive
./build-in-docker.sh
```

The result is placed in the `out/install` folder. You can create a tar archive of the folder contents, or add `out/install/bin` to your PATH.
