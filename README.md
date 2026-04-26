# minimal-os

A minimal x86 operating system built from scratch. **No libraries. No runtime. No Linux underneath.**

The entire goal of **v0.1** is to:
1. Boot a custom bootloader
2. Switch the CPU into 32-bit protected mode
3. Load a C kernel
4. Print a startup message to the screen

That is the complete scope.

---

## Tech Stack

- **Language**: C and x86 Assembly (NASM)
- **Compiler**: GCC (i686-elf cross-compiler)
- **Emulator**: QEMU (qemu-system-i386)
- **Build System**: GNU Make
- **Environment**: Docker (fully isolated development environment)

---

## Quick Start

### Setup (First Time)

Build and start the Docker environment:

```bash
# Build the Docker image (first time takes ~5 minutes)
docker-compose build

# Start the container
docker-compose up -d

# Verify it's running
docker ps | grep osdev
```

Enter the development environment:

```bash
# Enter the container
docker exec -it osdev-environment bash

# You should now see: osdev@[container-id]:/workspace$
```

Verify the toolchain:

```bash
./verify-environment.sh
```

All checks should show green ✓ marks. If any fail, rebuild: `exit` then `docker-compose build --no-cache`

### Building and Running

From the workspace root, use the Makefile to build and run components:

```bash
# Build a component
make boot

# Build and run in QEMU
make boot-run

# Clean build artifacts
make boot-clean

# See all available targets
make help
```

**QEMU Controls**:
- `Ctrl+Alt+Q` — Quit QEMU
- `Ctrl+Alt+G` — Release/capture mouse

---

## Projects

### Project 1 — Bootloader Hello World

**Status**: Completed

A 512-byte boot sector written in x86 assembly that:
- Loads at address `0x7C00` (BIOS entry point)
- Uses BIOS interrupt `0x10` (video services) to print text
- Prints a "Hello from the Boot Sector!" message
- Halts the CPU

**File**: [src/boot/boot.asm](src/boot/boot.asm)

**Build & Test**:
```bash
make boot-run
```

**What this validates**:
- NASM assembler works
- QEMU emulation works
- Understanding of x86 real mode
- Understanding of BIOS interrupts and boot sector format

---

### Project 2 — Protected Mode Switch

**Status**: Not Started

Set up a minimal GDT (Global Descriptor Table) and switch the CPU from 16-bit real mode to 32-bit protected mode. Print a confirmation string after the switch.

**Concepts**:
- GDT setup
- Segment registers and descriptors
- Protected mode gate
- 32-bit instructions

---

### Project 3 — Load the Kernel

**Status**: Not Started

Read the kernel binary from disk into memory and jump to it. The kernel is a separate C binary from the bootloader.

**Concepts**:
- Disk I/O (reading sectors)
- Memory layouts and linking
- Far jumps between boot sector and kernel

---

### Project 4 — Kernel Startup Message

**Status**: Not Started

From C, write directly to VGA memory at `0xB8000` and print a startup message to the screen.

**Concepts**:
- VGA memory layout (text mode)
- Writing kernel code in C
- Cross-compiler usage (i686-elf-gcc)
- Kernel entry point and calling conventions

---

## Done Criteria (v0.1 Complete)

- [ ] QEMU boots the binary
- [ ] Startup message appears on screen
- [ ] Every line of code is written and understood by the author

---

## Development Workflow

### Inside the Container

All development happens inside the Docker container where all tools are pre-installed.

**Build commands**:
```bash
make boot           # Build boot sector
make boot-run       # Build and run in QEMU
make boot-clean     # Clean artifacts
make all            # Build all components
make clean          # Clean everything
```

**Manual commands** (if needed):
```bash
# Assemble boot sector
nasm -f bin src/boot/boot.asm -o bin/boot.bin

# Check boot sector size (must be exactly 512 bytes)
ls -lh bin/boot.bin

# Verify boot signature (last two bytes)
hexdump -C bin/boot.bin | tail -1
# Expected: Last two bytes should be: 55 aa

# Run in QEMU
qemu-system-i386 -drive format=raw,file=bin/boot.bin -nographic
```

### File Structure

```
.
├── Makefile                 # Root build system
├── Dockerfile              # Development environment
├── docker-compose.yaml     # Container orchestration
├── README.md              # This file
├── bin/                   # Build outputs (generated)
├── docs/                  # Documentation
└── src/
    └── boot/
        └── boot.asm       # Bootloader source
```

---

## Troubleshooting

**"Command not found"**: Make sure you're inside the Docker container (`docker exec -it osdev-environment bash`)

**Build fails**: Rebuild the Docker image: `docker-compose build --no-cache`

**QEMU won't quit**: Press `Ctrl+Alt+Q` or use terminal exit code (Ctrl+C)

**Binary is wrong size**: Check that `boot.asm` has proper padding before the boot signature (`0xAA55`)

---

## References

- [NASM Manual](https://www.nasm.us/xdoc/2.15/)
- [x86 Assembly (Real Mode)](https://en.wikibooks.org/wiki/X86_Assembly)
- [BIOS Interrupt Services](http://www.ctyme.com/intr/int-10.htm)
- [QEMU System i386](https://qemu.weilnetz.de/doc/qemu-doc.html#QEMU-PC-System-emulator)
- [GCC i686-elf Cross Compiler](https://github.com/gcc-mirror/gcc)