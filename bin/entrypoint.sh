#!/bin/bash
set -e

### Configuration ###
REPO_URL="${REPO_URL:-https://github.com/mlc-ai/mlc-llm.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"
SOURCE_DIR="${SOURCE_DIR:-/root/mlc-llm}"
BUILD_DIR="${BUILD_DIR:-$SOURCE_DIR/build}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
INSTALL_PREFIX="${INSTALL_PREFIX:-$SOURCE_DIR/install}"

ENABLE_CUDA="${ENABLE_CUDA:-OFF}"
ENABLE_VULKAN="${ENABLE_VULKAN:-OFF}"
ENABLE_METAL="${ENABLE_METAL:-OFF}"
ENABLE_OPENCL="${ENABLE_OPENCL:-OFF}"
ENABLE_FLASHINFER="${ENABLE_FLASHINFER:-OFF}"
CUDA_ARCH="${CUDA_ARCH:-80}"

### Functions ###
clone_repo_if_needed() {
  if [ ! -d "$SOURCE_DIR" ]; then
    echo "[INFO] Cloning MLC-LLM from $REPO_URL (branch: $REPO_BRANCH)..."
    git clone --recursive --branch "$REPO_BRANCH" "$REPO_URL" "$SOURCE_DIR"
  fi
}

initialize_submodules_if_needed() {
  if [ -d "$SOURCE_DIR/.git" ] && [ -f "$SOURCE_DIR/.gitmodules" ]; then
    echo "[INFO] Initializing git submodules..."
    cd "$SOURCE_DIR"
    git submodule update --init --recursive
  fi
}

generate_config_cmake() {
  echo "[INFO] Generating config.cmake..."
  mkdir -p "$BUILD_DIR"
  cat <<EOF > "$BUILD_DIR/config.cmake"
set(TVM_SOURCE_DIR 3rdparty/tvm)
set(CMAKE_BUILD_TYPE $BUILD_TYPE)
set(CMAKE_INSTALL_PREFIX $INSTALL_PREFIX)
set(USE_CUDA $ENABLE_CUDA)
set(USE_VULKAN $ENABLE_VULKAN)
set(USE_METAL $ENABLE_METAL)
set(USE_OPENCL $ENABLE_OPENCL)
set(USE_FLASHINFER $ENABLE_FLASHINFER)
EOF

  if [ "$ENABLE_FLASHINFER" = "ON" ]; then
    cat <<EOF >> "$BUILD_DIR/config.cmake"
set(FLASHINFER_CUDA_ARCHITECTURES $CUDA_ARCH)
set(CMAKE_CUDA_ARCHITECTURES $CUDA_ARCH)
EOF
  fi
}

build_project() {
  echo "[INFO] Building MLC-LLM with:"
  echo "  Source: $SOURCE_DIR"
  echo "  Build Dir: $BUILD_DIR"
  echo "  Build Type: $BUILD_TYPE"
  echo "  Install Prefix: $INSTALL_PREFIX"

  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"

  cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DUSE_CUDA="$ENABLE_CUDA" \
        -DUSE_VULKAN="$ENABLE_VULKAN" \
        -DUSE_METAL="$ENABLE_METAL" \
        -DUSE_OPENCL="$ENABLE_OPENCL" \
        -DUSE_FLASHINFER="$ENABLE_FLASHINFER" \
        "$SOURCE_DIR"

  cmake --build . --parallel "$(nproc)"
}

run_tests() {
  echo "[INFO] Running tests..."
  cd "$SOURCE_DIR/tests/python"
  pytest .
}

launch_dev_environment() {
  echo "=============================="
  echo " Welcome to MLC-LLM Dev Shell "
  echo "=============================="
  echo "Source Dir      : $SOURCE_DIR"
  echo "Conda Env       : mlc-chat-venv"
  echo "Python Version  : $(python --version)"
  echo "CMake Version   : $(cmake --version | head -n 1)"
  echo "Rust Version    : $(rustc --version)"
  echo "=============================="
  exec /bin/bash --login
}

show_help() {
  echo "Usage: docker run <image> [DevEnvironment|build|test]"
  echo ""
  echo "  DevEnvironment   Start an interactive shell"
  echo "  build            Build the project"
  echo "  test             Run pytest from tests/python"
  echo ""
  echo "If no argument is provided, this help message is shown."
}

### Main ###
case "$1" in
  DevEnvironment)
    launch_dev_environment
    ;;
  build)
    clone_repo_if_needed
    initialize_submodules_if_needed
    generate_config_cmake
    build_project
    ;;
  test)
    run_tests
    ;;
  *)
    show_help
    ;;
esac
