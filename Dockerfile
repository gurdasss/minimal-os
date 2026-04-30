# OS Development Environment
# This container includes all tools needed for bare-metal development
# including a cross-compiler (i686-elf-gcc) built from source

FROM ubuntu:22.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and emulators for bootloader development
RUN apt-get update && apt-get install -y \
    nasm \
    build-essential \
    gcc \
    g++ \
    make \
    bison \
    flex \
    libgmp3-dev \
    libmpc-dev \
    libmpfr-dev \
    texinfo \
    wget \
    qemu-system-x86 \
    gdb \
    xxd \
    && rm -rf /var/lib/apt/lists/*

# Set up environment variables for cross-compiler
ENV PREFIX="/usr/local/cross"
ENV TARGET=i686-elf
ENV PATH="$PREFIX/bin:$PATH"

# Create directory for cross-compiler build
RUN mkdir -p /tmp/cross-compiler-build
WORKDIR /tmp/cross-compiler-build

# Define versions (latest stable as of 2025)
ENV BINUTILS_VERSION=2.42
ENV GCC_VERSION=13.2.0

# Download and build binutils
RUN wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz && \
    tar -xzf binutils-${BINUTILS_VERSION}.tar.gz && \
    mkdir build-binutils && \
    cd build-binutils && \
    ../binutils-${BINUTILS_VERSION}/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf binutils-${BINUTILS_VERSION} binutils-${BINUTILS_VERSION}.tar.gz build-binutils

# Download and build GCC
# Note: We only build the C compiler (--enable-languages=c) for now
# We'll add C++ later if needed
RUN wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz && \
    tar -xzf gcc-${GCC_VERSION}.tar.gz && \
    mkdir build-gcc && \
    cd build-gcc && \
    ../gcc-${GCC_VERSION}/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c --without-headers && \
    make all-gcc -j$(nproc) && \
    make all-target-libgcc -j$(nproc) && \
    make install-gcc && \
    make install-target-libgcc && \
    cd .. && \
    rm -rf gcc-${GCC_VERSION} gcc-${GCC_VERSION}.tar.gz build-gcc

# Clean up build directory
WORKDIR /
RUN rm -rf /tmp/cross-compiler-build

# Verify the cross-compiler installation
RUN i686-elf-gcc --version && \
    i686-elf-ld --version && \
    i686-elf-as --version

# Create workspace directory
WORKDIR /workspace

# Set up a non-root user for development
RUN useradd -m -s /bin/bash osdev && \
    chown -R osdev:osdev /workspace

USER osdev

# Dynamic User Creation
ARG USER_ID=1000
ARG GROUP_ID=1000

# Create group and user only if they don't exist (safety for base image defaults)
RUN groupadd -g ${GROUP_ID} osdev || true && \
    useradd -l -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash osdev || true

# Set permissions for the workspace
RUN chown -R osdev:osdev /workspace

CMD ["/bin/bash"]