# OS Development Environment
# This container includes all tools needed for bare-metal development

FROM ubuntu:22.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and emulators for bootloader development
RUN apt-get update && apt-get install -y \
    nasm \
    build-essential \
    gcc \
    make \
    qemu-system-x86 \
    gdb \
    && rm -rf /var/lib/apt/lists/*

# Create a workspace directory
WORKDIR /workspace

# Set up a non-root user for development
RUN useradd -m -s /bin/bash osdev && \
    chown -R osdev:osdev /workspace

USER osdev

CMD ["/bin/bash"]