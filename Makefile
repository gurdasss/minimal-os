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

KERNEL_DIR := $(SRC_DIR)/kernel
KERNEL_ENTRY := $(KERNEL_DIR)/kernel_entry.asm
KERNEL_C := $(KERNEL_DIR)/kernel.c
VGA_C := $(KERNEL_DIR)/vga.c
SERIAL_C := $(KERNEL_DIR)/serial.c
LINKER_SCRIPT := $(KERNEL_DIR)/linker.ld

KERNEL_ENTRY_O := $(BIN_DIR)/kernel_entry.o
KERNEL_O := $(BIN_DIR)/kernel.o
VGA_O := $(BIN_DIR)/vga.o
SERIAL_O := $(BIN_DIR)/serial.o
KERNEL_BIN := $(BIN_DIR)/kernel.bin

# Compiler flags for i686 cross-compilation
CFLAGS := -m32 -ffreestanding -nostdlib -fno-pie -fno-stack-protector -O2

kernel: kernel-build

kernel-build: $(KERNEL_BIN)

# Assemble kernel entry point
$(KERNEL_ENTRY_O): $(KERNEL_ENTRY) | $(BIN_DIR)
	nasm -f elf32 $(KERNEL_ENTRY) -o $(KERNEL_ENTRY_O)

# Compile kernel.c
$(KERNEL_O): $(KERNEL_C) | $(BIN_DIR)
	gcc $(CFLAGS) -c $(KERNEL_C) -o $(KERNEL_O)

# Compile vga.c
$(VGA_O): $(VGA_C) | $(BIN_DIR)
	gcc $(CFLAGS) -c $(VGA_C) -o $(VGA_O)

# Compile serial.c
$(SERIAL_O): $(SERIAL_C) | $(BIN_DIR)
	gcc $(CFLAGS) -c $(SERIAL_C) -o $(SERIAL_O)

# Link kernel
$(KERNEL_BIN): $(KERNEL_ENTRY_O) $(KERNEL_O) $(VGA_O) $(SERIAL_O) $(LINKER_SCRIPT) | $(BIN_DIR)
	ld -m elf_i386 -T $(LINKER_SCRIPT) -o $(KERNEL_BIN) \
	$(KERNEL_ENTRY_O) $(KERNEL_O) $(VGA_O) $(SERIAL_O) \
	--oformat binary
kernel-clean:
	rm -f $(KERNEL_ENTRY_O) $(KERNEL_O) $(VGA_O) $(SERIAL_O) $(KERNEL_BIN)

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
	@echo "========================================"
	@echo "Running minimal-os with serial output"
	@echo "Press Ctrl+A then X to quit QEMU"
	@echo "========================================"
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