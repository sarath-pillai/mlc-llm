FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV PATH="$CONDA_DIR/bin:$PATH"

# Build args for config.cmake
ARG ENABLE_CUDA=OFF
ARG ENABLE_CUTLASS=OFF
ARG ENABLE_CUBLAS=OFF
ARG ENABLE_ROCM=OFF
ARG ENABLE_VULKAN=OFF
ARG ENABLE_METAL=OFF
ARG ENABLE_OPENCL=OFF
ARG ENABLE_OPENCL_HOST_PTR=OFF
ARG ENABLE_FLASHINFER=OFF
ARG CUDA_ARCH=80

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
      software-properties-common \
      build-essential \
      git \
      curl \
      wget \
      unzip \
      ninja-build \
      libopenblas-dev \
      libgl1-mesa-dev \
      libvulkan-dev \
      vulkan-tools \
      python3-pip \
      python-is-python3 \
      ca-certificates \
      bzip2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install CMake 3.24.4 (from Kitware)
RUN curl -LO https://github.com/Kitware/CMake/releases/download/v3.24.4/cmake-3.24.4-linux-x86_64.sh && \
    chmod +x cmake-3.24.4-linux-x86_64.sh && \
    ./cmake-3.24.4-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-3.24.4-linux-x86_64.sh

# Install Rust and make it available globally
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH="${CARGO_HOME}/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf -o rustup-init && \
    chmod +x rustup-init && \
    ./rustup-init -y --no-modify-path --default-toolchain stable --profile minimal && \
    rm rustup-init

# Install Miniconda
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh && \
    /opt/conda/bin/conda clean -afy

# Create conda environment without cmake
RUN conda create -n mlc-chat-venv -c conda-forge \
    git \
    python=3.11 && \
    conda clean -afy

COPY bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
