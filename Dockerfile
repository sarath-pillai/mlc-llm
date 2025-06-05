FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH="$CARGO_HOME/bin:$PATH"

# Build args
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

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    ca-certificates \
    bzip2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install CMake
RUN curl -sSL https://github.com/Kitware/CMake/releases/download/v3.24.4/cmake-3.24.4-linux-x86_64.sh -o cmake.sh && \
    chmod +x cmake.sh && \
    ./cmake.sh --skip-license --prefix=/usr/local && \
    rm cmake.sh

# Install Rust
RUN curl https://sh.rustup.rs -sSf -o rustup-init && \
    chmod +x rustup-init && \
    ./rustup-init -y --no-modify-path --default-toolchain stable --profile minimal && \
    rm rustup-init && \
    rm -rf /root/.rustup /root/.cargo

# Install Miniconda and remove installer + caches
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh && \
    bash miniconda.sh -b -p "$CONDA_DIR" && \
    rm miniconda.sh && \
    "$CONDA_DIR/bin/conda" clean -afy

ENV PATH="/opt/conda/bin:${PATH}"

# Create conda env with minimal packages (no cmake)
RUN conda create -n mlc-chat-venv -c conda-forge python=3.11 git && \
    conda clean -afy

# Add conda activation logic inside bashrc
RUN /opt/conda/bin/conda init bash \
    && echo "conda activate mlc-llm" >> ~/.bashrc

# Add entrypoint
COPY bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []

