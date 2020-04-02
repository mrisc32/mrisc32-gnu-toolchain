# MRISC32 GNU toolchain

This is a top level repository for building the MRISC32 toolchain.

## Prerequities

TBD

# Building

To build and install the GNU toolchain for MRISC32, do:

```bash
./build.sh --clean --update --prefix="$HOME/.local"
```

This builds and installs a number of tools, including:

* `mrisc32-elf-gcc` - The GNU C compiler.
* `mrisc32-elf-as` - The GNU assembler.
* `mrisc32-elf-ld` - The GNU linker.
* `mrisc32-elf-ar` - The GNU archiver program.

For more options, see:

```bash
./build.sh --help
```
