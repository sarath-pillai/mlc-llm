FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH="$CARGO_HOME/bin:$PATH"

# Runtime configuration defaults
ENV ENABLE_CUDA=OFF
ENV ENABLE_CUTLASS=OFF
ENV ENABLE_CUBLAS=OFF
ENV ENABLE_ROCM=OFF
ENV ENABLE_VULKAN=OFF
ENV ENABLE_METAL=OFF
ENV ENABLE_OPENCL=OFF
ENV ENABLE_OPENCL_HOST_PTR=OFF
ENV ENABLE_FLASHINFER=OFF
ENV CUDA_ARCH=80

# Install system packages
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    cmake \
    ninja-build \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \ 
    libopenblas-dev \
    libgl1-mesa-dev \
    libvulkan-dev \
    vulkan-tools \
    ca-certificates \
    bzip2 \
    libtinfo-dev \
    zlib1g-dev \
    libxml2-dev \
    libncurses5-dev \
    libffi-dev \
    libedit-dev \
    libssl-dev \
    ocl-icd-opencl-dev \
    opencl-headers \
    clinfo \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python Packages useful for devs

RUN pip install \
    pylint \
    pytest \
    scipy \
    numpy \
    setuptools \
    wheel \
    transformers \
    tokenizers \
    jupyter \
    ipython \
    black \
    flake8 \
    mypy \
    pre-commit \
    pybind11 \
    cython \
    requests \
    tqdm \
    pyyaml \
    click \
    auditwheel

# Install TVM

RUN pip install torch --index-url https://download.pytorch.org/whl/cpu && \
    pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu mlc-llm-nightly-cpu

# Install Rust
RUN curl https://sh.rustup.rs -sSf -o rustup-init && \
    chmod +x rustup-init && \
    ./rustup-init -y --no-modify-path --default-toolchain stable --profile minimal && \
    rm rustup-init && \
    rm -rf /root/.rustup /root/.cargo

# Copy and set entrypoint
COPY bin/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8888 8000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []

