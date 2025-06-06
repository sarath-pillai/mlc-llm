#!/bin/bash
set -e

### Configuration ###
SOURCE_DIR="${SOURCE_DIR:-/workspace/mlc-llm}"
BUILD_DIR="${BUILD_DIR:-$SOURCE_DIR/build}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
INSTALL_PREFIX="${INSTALL_PREFIX:-$SOURCE_DIR/install}"

# Feature toggles
ENABLE_CUDA="${ENABLE_CUDA:-OFF}"
ENABLE_VULKAN="${ENABLE_VULKAN:-OFF}"
ENABLE_METAL="${ENABLE_METAL:-OFF}"
ENABLE_OPENCL="${ENABLE_OPENCL:-OFF}"
ENABLE_FLASHINFER="${ENABLE_FLASHINFER:-OFF}"
CUDA_ARCH="${CUDA_ARCH:-80}"

### Functions ###

print_help() {
  echo "Usage: docker run ... mlc-llm [DevEnvironment|build|test]"
  echo
  echo "  DevEnvironment  - Drop into a shell with dev tools preinstalled"
  echo "  build           - Run cmake and build the MLC-LLM project"
  echo "  test            - Run pytest from tests/python"
  echo
  echo "Environment Variables:"
  echo "  SOURCE_DIR, BUILD_DIR, BUILD_TYPE, INSTALL_PREFIX"
  echo "  ENABLE_CUDA, ENABLE_VULKAN, ENABLE_METAL, ENABLE_OPENCL, ENABLE_FLASHINFER, CUDA_ARCH"
}

validate_source_directory() {
  if [ ! -d "$SOURCE_DIR/.git" ] || [ ! -f "$SOURCE_DIR/CMakeLists.txt" ]; then
    echo "[ERROR] Source directory at $SOURCE_DIR is not a valid MLC-LLM repository."
    echo "Please mount the source code correctly using:"
    echo "  -v \$(pwd):/workspace/mlc-llm"
    exit 1
  fi
}

initialize_submodules_if_needed() {
  if [ -f "$SOURCE_DIR/.gitmodules" ]; then
    echo "[INFO] Initializing git submodules..."
    cd "$SOURCE_DIR"
    git submodule update --init --recursive || {
      echo "[ERROR] Submodule initialization failed."
      exit 1
    }
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
  cd "$SOURCE_DIR"
  exec bash
}

build_python_wheel() {
  cd "$SOURCE_DIR/python"
  python setup.py bdist_wheel
}


run_tests() {
    pip install pytest
    pip install torch --index-url https://download.pytorch.org/whl/cpu
    pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu mlc-llm-nightly-cpu
    bash ci/task/test_unittest.sh
}

### Execution Flow ###
ACTION="$1"

validate_source_directory

case "$ACTION" in
  DevEnvironment)
    launch_dev_environment
    ;;
  build)
    initialize_submodules_if_needed
    generate_config_cmake
    build_project
    build_python_wheel
    ;;
  test)
    initialize_submodules_if_needed
    run_tests
    ;;
  ""|help|--help|-h)
    print_help
    ;;
  *)
    echo "[ERROR] Unknown option: $ACTION"
    print_help
    exit 1
    ;;
esac

