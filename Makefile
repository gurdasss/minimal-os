# Root Makefile for minimal-os project
# Builds bootloader, kernel, and combines them into a disk image

.PHONY: help all boot boot-build boot-clean kernel kernel-build kernel-clean os os-build os-run os-clean clean

BIN_DIR := bin
SRC_DIR := src

help:
	@echo "minimal-os Build System"
	@echo "======================="
	@echo ""
	@echo "Available components:"
	@echo "  make boot          - Build the boot component"
	@echo "  make boot-run      - Build and run boot in QEMU"
	@echo "  make boot-clean    - Clean boot build artifacts"
	@echo ""
	@echo "  make kernel        - Build the kernel"
	@echo "  make kernel-clean  - Clean kernel build artifacts"
	@echo ""
	@echo "  make os            - Build complete OS (bootloader + kernel disk image)"
	@echo "  make os-run        - Build and run complete OS in QEMU"
	@echo "  make os-clean      - Clean OS disk image"
	@echo ""
	@echo "Global targets:"
	@echo "  make all           - Build all components"
	@echo "  make clean         - Clean all build artifacts"
	@echo ""

# Default target
all: os

# ============================================================================
# BOOT Component
# ============================================================================

BOOT_SRC := $(SRC_DIR)/boot/boot.asm
BOOT_BIN := $(BIN_DIR)/boot.bin

boot: boot-build

boot-build: $(BOOT_BIN)

$(BOOT_BIN): $(BOOT_SRC) | $(BIN_DIR)
	nasm -f bin $(BOOT_SRC) -o $(BOOT_BIN)

boot-run: $(BOOT_BIN)
	qemu-system-i386 -drive format=raw,file=$(BOOT_BIN) -display none -serial stdio

boot-clean:
	rm -f $(BOOT_BIN)

# ============================================================================
# KERNEL Component
# ============================================================================

KERNEL_SRC := $(SRC_DIR)/kernel/kernel.c
KERNEL_LINKER := $(SRC_DIR)/kernel/linker.ld
KERNEL_OBJ := $(BIN_DIR)/kernel.o
KERNEL_ELF := $(BIN_DIR)/kernel.elf
KERNEL_BIN := $(BIN_DIR)/kernel.bin

# Cross-compiler tools
CC := i686-elf-gcc
LD := i686-elf-ld
OBJCOPY := i686-elf-objcopy

# Compiler flags for freestanding kernel
CFLAGS := -m32 -ffreestanding -O2 -Wall -Wextra -nostdlib -nostdinc -fno-builtin -fno-stack-protector

kernel: kernel-build

kernel-build: $(KERNEL_BIN)

# Step 1: Compile kernel.c to kernel.o (object file)
$(KERNEL_OBJ): $(KERNEL_SRC) | $(BIN_DIR)
	$(CC) $(CFLAGS) -c $(KERNEL_SRC) -o $(KERNEL_OBJ)

# Step 2: Link kernel.o to kernel.elf using the linker script
$(KERNEL_ELF): $(KERNEL_OBJ) $(KERNEL_LINKER)
	$(LD) -T $(KERNEL_LINKER) -o $(KERNEL_ELF) $(KERNEL_OBJ)

# Step 3: Strip ELF headers to produce raw binary
$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $(KERNEL_ELF) $(KERNEL_BIN)

kernel-clean:
	rm -f $(KERNEL_OBJ) $(KERNEL_ELF) $(KERNEL_BIN)

# ============================================================================
# OS (Complete Disk Image)
# ============================================================================

OS_IMG := $(BIN_DIR)/os.img

os: os-build

os-build: $(OS_IMG)

# Create disk image: bootloader (sector 0) + kernel (sector 1+)
$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	@echo "Building disk image..."
	# Create a 1MB disk image filled with zeros
	dd if=/dev/zero of=$(OS_IMG) bs=512 count=2048 2>/dev/null
	# Write bootloader to sector 0 (first 512 bytes)
	dd if=$(BOOT_BIN) of=$(OS_IMG) bs=512 count=1 conv=notrunc 2>/dev/null
	# Write kernel starting at sector 1 (offset 512 bytes)
	dd if=$(KERNEL_BIN) of=$(OS_IMG) bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "Disk image created: $(OS_IMG)"
	@ls -lh $(OS_IMG)

os-run: $(OS_IMG)
	@echo "Starting QEMU with disk image..."
	@echo "Press Ctrl+A then X to quit QEMU"
	@echo "========================================\n"
	qemu-system-i386 -drive format=raw,file=$(OS_IMG) -display none -serial stdio

os-clean:
	rm -f $(OS_IMG)

# ============================================================================
# Global Targets
# ============================================================================

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean: boot-clean kernel-clean os-clean
	rmdir $(BIN_DIR) 2>/dev/null || true

.DEFAULT_GOAL := help