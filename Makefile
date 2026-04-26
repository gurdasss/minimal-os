# Root Makefile for minimal-os project
# Allows building and running components from the src/ directory
# Usage: make boot, make boot run, make boot clean, etc.

.PHONY: help all boot boot-build boot-run boot-clean clean

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
	@echo "Global targets:"
	@echo "  make all           - Build all components"
	@echo "  make clean         - Clean all build artifacts"
	@echo ""

# Default target
all: boot

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
	qemu-system-i386 -drive format=raw,file=$(BOOT_BIN) -nographic

boot-clean:
	rm -f $(BOOT_BIN)

# ============================================================================
# Global Targets
# ============================================================================

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean: boot-clean
	rmdir $(BIN_DIR) 2>/dev/null || true

.DEFAULT_GOAL := help
