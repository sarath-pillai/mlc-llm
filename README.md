> 📘 **Introduction**  
> This repository has been created to demonstrate the tasks outlined in an assignment.  
>  
> 🗂️ It includes a copy of the original source:  
> [https://github.com/mlc-ai/mlc-llm](https://github.com/mlc-ai/mlc-llm)  
>  
> ✍️ In addition to the content from the original project, this repository also features  
> supplementary work developed specifically to meet the assignment's deliverables.

### 🐳 **Docker Image**

> This project includes a Docker image preconfigured with Python 3,Miniconda, Rust and several other dev dependencies. The idea is to use the docker image as a Development environment. Basically a single docker image that serves two purposes.

- An interactive shell, with all required tools to build/test MLC LLM.
- An unattended local build environment. Devs can trigger build locally without any interaction. 


### Development environment (Interactive shell)
Assuming you have already cloned this repo, and your current working directory is the root of the project, run the below commands. 

```bash
docker pull ghcr.io/sarath-pillai/mlc-llm:latest
```

```bash
docker run -v .:/workspace/mlc-llm -it ghcr.io/sarath-pillai/mlc-llm:latest DevEnvironment
==============================
 Welcome to MLC-LLM Dev Shell 
==============================
Source Dir      : /workspace/mlc-llm
Conda Env       : mlc-chat-venv
Python Version  : Python 3.11.13
CMake Version   : cmake version 3.25.1
Rust Version    : rustc 1.87.0 (17067e9ac 2025-05-09)
==============================
root@e32352e04240:/workspace/mlc-llm# 
```

You are now in an interactive shell with all required dependencies for dev work. 

### Build environment (Non interactive local build)
Ensure you have a local clone of this repository, and the below command must be fired from within the root of the local clone. 

```bash
docker run -v .:/workspace/mlc-llm -it ghcr.io/sarath-pillai/mlc-llm:latest build
```

The above command will start the compilation process. 


### ⚙️ **CI/CD Workflow**

This repository includes a comprehensive GitHub Actions workflow (`.github/workflows/ci.yml`) that automates testing, building, and packaging of the MLC-LLM project across platforms.

#### ✅ **Triggers**
The workflow is triggered on:
- Pushes to the `master` branch
- Creation of tags matching `v*` (used for releases)
- Pull requests targeting `master`

#### 🧪 **Job: Run Unit Tests (`test`)**
This job ensures correctness of core functionality:

- Sets up Python 3.11
- Installs dependencies: `pytest`, `torch`, and nightly builds of `mlc-ai` and `mlc-llm`
- Executes tests via `ci/task/test_unittest.sh`

#### 🐳 **Job: Docker Build & Push (`docker`)**
This job builds and publishes a Docker image to GitHub Container Registry (GHCR):

- Authenticates with GHCR using `GITHUB_TOKEN`
- Tags the image based on branch, tag, commit SHA, and `latest` if on the default branch
- Builds and pushes the image using Docker BuildKit with caching enabled

#### 🏗️ **Job: Build on Linux (`build-mlc-llm-linux`)**
This job builds the MLC-LLM project and generates a Python wheel:

- Sets up the build environment and dependencies (e.g., `cmake`, `ninja`, `libopenblas`, etc.)
- Configures build options like `USE_CUDA`, `USE_VULKAN`, etc.
- Caches intermediate build files for performance
- Builds the C++ code with CMake
- Packages the Python wheel (`python/dist/*.whl`)
- If it's a release tag (`v*`), the wheel is uploaded to GitHub Releases

#### 🪟 **Job: Build on Windows (`build-mlc-llm-windows`)**
This job mirrors the Linux build but is tailored for Windows:

- Uses Miniconda to manage the environment (via `build-environment.yaml`)
- Runs the Windows build script (`ci\task\build_win.bat`)
- Builds and uploads the wheel on release tag

#### 🔒 **Permissions**
The workflow grants the following permissions:
- `contents: write` – required for uploading release assets
- `packages: write` – required for pushing Docker images to GHCR

---

### 📦 **Release Artifacts**
If a release tag (e.g., `v1.0.0`) is pushed:
- Docker image is tagged and pushed to `ghcr.io/<owner>/mlc-llm`
- Python wheels (`.whl` files) for both Linux and Windows are uploaded to the GitHub Release
