# MRISC32 GNU toolchain

This is a top level repository for building the MRISC32 GNU toolchain.

The toolchain consists of:

* C and C++ compilers ([GCC](https://gcc.gnu.org/))
* Assembler, linker, ELF tools etc ([binutils](https://www.gnu.org/software/binutils/))
* A standard C library ([newlib](https://sourceware.org/newlib/))

# Pre-built binaries

The latest pre-built version of the toolchain can be found [here](https://github.com/mrisc32/mrisc32-gnu-toolchain/releases/latest).

Binaries are available for:

* Linux (x86_64)
* macOS (ARM64 + x86_64)
* Windows (x86_64)

Some releases also have pre-built versions for Linux ARM32 and/or ARM64 (e.g. for Raspberry Pi).

## Installation

1. Unpack the archive to a location of your choice.
2. Add `path/to/mrisc32-gnu-toolchain/bin` to your `PATH` environment variable (e.g. in `$HOME/.bashrc` on Linux).

# Building yourself

Currently there are two methods for building the toolchain:

1. Natively on your host machine (recommended).
2. Using Docker.

## Host build

The build has been tested on Ubuntu 20.04 (with GCC), macOS (with clang) and Windows (with MSYS2 and MinGW), but may work on other similar systems too.

### Prerequities

The following packages are required (example given for Ubuntu):

```bash
sudo apt install bison build-essential curl flex texinfo
```

### Building

To build and install the GNU toolchain for MRISC32, do (example given for Ubuntu):

```bash
git submodule update --init --recursive
./build.sh --clean --prefix="$HOME/.local"
```

For more options, see:

```bash
./build.sh --help
```

## Docker build

The Docker based build will produce a toolchain for Linux hosts.

### Prerequities

Install Docker.

### Building

To build the GNU toolchain for MRISC32, do:

```bash
git submodule update --init --recursive
./build-in-docker.sh
```

The result is placed in the `out/install` folder. You can create a tar archive of the folder contents, or add `out/install/bin` to your PATH.
