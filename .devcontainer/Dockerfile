ARG VARIANT=12
FROM debian:${VARIANT}
RUN set -eux;\
    apt-get update;\
    export DEBIAN_FRONTEND=noninteractive; apt-get install -y --no-install-recommends\
  build-essential\
  ca-certificates\
  clang\
  cmake\
  cppcheck\
  curl\
  gdb\
  git\
  lldb\
  llvm\
  make\
  ninja-build\
  valgrind\
  wget\
  xz-utils\
;\
    apt-get autoremove -y; apt-get clean -y ; apt-get clean; rm -rf /var/lib/apt/lists/*;\
    echo DONE

RUN set -eux;\
    ARCH=$(uname -m);\
    case "$ARCH" in\
        x86_64)   NVIDIA_ARCH="x86_64" ;;\
        aarch64|arm64) NVIDIA_ARCH="sbsa" ;;\
        *) echo "Unsupported arch: $ARCH"; exit 1 ;;\
    esac;\
    REPO_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/${NVIDIA_ARCH}";\
    wget -q "${REPO_URL}/cuda-keyring_1.1-1_all.deb" -O /tmp/cuda-keyring.deb;\
    dpkg -i /tmp/cuda-keyring.deb;\
    rm /tmp/cuda-keyring.deb;\
    apt-get update;\
    export DEBIAN_FRONTEND=noninteractive; apt-get install -y --no-install-recommends\
  cuda-toolkit-13-0\
;\
    apt-get autoremove -y; apt-get clean; rm -rf /var/lib/apt/lists/*;\
    echo DONE
