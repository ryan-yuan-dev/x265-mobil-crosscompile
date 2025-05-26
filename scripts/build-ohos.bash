#!/bin/bash
# Run this from within a bash shell

# ----- 外部设置 -----

# 指定 CMakeLists.txt 所在文件夹
SOURCE_DIR=
# 指定构建文件目录
BUILD_DIR=
FLAVOR_BUILD_DIR=
INSTALL_DIR=
FLAVOR_INSTALL_DIR=
# 指定 OHOS SDK native 路径.
# 如果安装了 DevEco Studio，则路径通常在 sdk/default/openharmony/native;
# 如果安装了独立的 sdk, 则路径通常在类似 sdk/11/native 这样的位置
SDK_NATIVE_PATH=
# 指定 arch-abi
ARCH_ABI=arm64-v8a
# 指定 api 版本
API_VERSION=1

# ----- 内部计算 -----

# cmake 执行文件所在目录，${SDK_PATH}/cmake/3.22.1/bin
CMAKE_HOME=
# android.toolchain.cmake 文件路径
CMAKE_TOOLCHAIN_FILE=

# 显示脚本帮助信息
help() {
  echo "$(pwd)/$0 执行说明："
  echo ""
  echo "- 请设置以下环境变量："
  echo "- OHOS_SDK sdk                 所在目录，比如： sdk/default/openharmony 或者 sdk/11"
  echo ""
  echo "- 选项:"
  echo "  -h                            显示此帮助信息"
  echo "  -S, --src_dir                 * 必传，指定源目录 DIR 为 CMakeLists.txt 文件所在路径"
  echo "  -B, --build_dir               * 必传，指定构建目录，必传"
  echo "  -I, --install_dir             * 必传，指定静态库和动态库的安装目录"
  echo "  --abi                         指定目标架构， 默认 arm64-v8a"
  echo "  --api                         指定目标 api 版本， 默认 21"
  exit 0
}

# 解析脚本参数
parse_arguments() {
  # 解析参数
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h)
      help # 调用帮助函数并退出
      ;;
    --src_dir)
      if [[ "$2" == /* ]]; then
        SOURCE_DIR="$2"
      else
        SOURCE_DIR="$(pwd)/$2"
      fi
      shift 2
      ;;
    --build_dir)
      if [[ "$2" == /* ]]; then
        BUILD_DIR="$2"
      else
        BUILD_DIR="$(pwd)/$2"
      fi
      shift 2
      ;;
    --install_dir)
      if [[ "$2" == /* ]]; then
        INSTALL_DIR="$2"
      else
        INSTALL_DIR="$(pwd)/$2"
      fi
      shift 2
      ;;
    -S)
      if [[ "$2" == /* ]]; then
        SOURCE_DIR="$2"
      else
        SOURCE_DIR="$(pwd)/$2"
      fi
      shift 2
      ;;
    -B)
      if [[ "$2" == /* ]]; then
        BUILD_DIR="$2"
      else
        BUILD_DIR="$(pwd)/$2"
      fi
      shift 2
      ;;
    -I)
      if [[ "$2" == /* ]]; then
        INSTALL_DIR="$2"
      else
        INSTALL_DIR="$(pwd)/$2"
      fi
      shift 2
      ;;
    --abi)
      ARCH_ABI="$2"
      shift 2
      ;;
    --api)
      API_VERSION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      help # 显示帮助并退出
      ;;
    esac
  done
}

# 检查是否设置了 SOURCE_DIR 和 BUILD_DIR
check_paths() {
  if [ -z "${SOURCE_DIR}" ]; then
    echo "Please specify the source directory with --src_dir or -S"
    exit 1
  fi
  echo "SOURCE_DIR $SOURCE_DIR"
  if [ -z "${BUILD_DIR}" ]; then
    echo "Please specify the build directory with --build_dir or -B"
    exit 1
  fi
  echo "BUILD_DIR $BUILD_DIR"
  if [ -z "${INSTALL_DIR}" ]; then
    echo "Please specify the install directory with --install_dir or -I"
    exit 1
  fi
  echo "INSTALL_DIR $INSTALL_DIR"
}

# 获取当前脚本所在目录
get_this_script_dir() {
  # 获取当前脚本的绝对路径
  local SCRIPT_PATH
  SCRIPT_PATH="$(realpath "$0")"
  # 获取当前脚本所在的目录
  BUILD_DIR=$(dirname "$SCRIPT_PATH")
  echo "BUILD_DIR $BUILD_DIR"
}

# 检测是否定义了 Android SDK 环境变量
check_sdk() {
  if [ -n "$OHOS_SDK_NATIVE" ]; then
    SDK_NATIVE_PATH="$OHOS_SDK_NATIVE"
  fi
  if [ -z "$SDK_NATIVE_PATH" ] && [ -n "$OHOS_SDK" ]; then
    SDK_NATIVE_PATH="$OHOS_SDK/native"
  fi
  if [ -z "$SDK_NATIVE_PATH" ]; then
    echo -e "Error: Environment variable OHOS_SDK_NATIVE or OHOS_SDK must be set. \n" \
      "Please configure it as follows: \n" \
      "    export OHOS_SDK_NATIVE=/path/to/native/sdk \n" \
      "    or \n" \
      "    export OHOS_SDK=/path/to/sdk/**/native" # Full SDK path"
    exit 1
  fi
  echo "SDK_NATIVE_PATH found ${SDK_NATIVE_PATH}"
  CMAKE_TOOLCHAIN_FILE="${SDK_NATIVE_PATH}/build/cmake/ohos.toolchain.cmake"
}

# 检测是否安装了 Android Cmake
check_cmake() {
  CMAKE_HOME="${SDK_NATIVE_PATH}/build-tools/cmake"
  # 判断 ${CMAKE_HOME}/bin/cmake 文件是否存在
  if [ ! -f "${CMAKE_HOME}/bin/cmake" ]; then
    echo "cmake not found, be sure your OHOS_SDK is right"
    exit 1
  fi
  echo "CMAKE PATH fount ${CMAKE_HOME}/bin/cmake; ccmake cpack ctest and ninja are in path too"
  export PATH=${CMAKE_HOME}/bin:$PATH
}

# cmake  使用收集到的信息创建 Makefile
build() {
  FLAVOR_BUILD_DIR="${BUILD_DIR}/${ARCH_ABI}"
  FLAVOR_INSTALL_DIR="${INSTALL_DIR}/${ARCH_ABI}"
  mkdir -p "${FLAVOR_INSTALL_DIR}"
  echo "FLAVOR_BUILD_DIR: ${FLAVOR_BUILD_DIR}"
  echo "FLAVOR_INSTALL_DIR: ${FLAVOR_INSTALL_DIR}"
  # ohos level 设置 -DOHOS_SDK_NATIVE_PLATFORM="ohos-${API_VERSION}"
  cmake -S "$SOURCE_DIR" -B "$FLAVOR_BUILD_DIR" \
    -G "Ninja" \
    -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
    -DCMAKE_INSTALL_PREFIX="${FLAVOR_INSTALL_DIR}" \
    -DOHOS_SDK_NATIVE="${SDK_PATH/native/}" \
    -DOHOS_ARCH="$ARCH_ABI" \
    -DCMAKE_POSITION_INDEPENDENT_CODE="ON" \
    -DOHOS_STL="c++_shared" \
    -DENABLE_ASSEMBLY="OFF" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  ninja -C "$FLAVOR_BUILD_DIR" clean
  ninja -C "$FLAVOR_BUILD_DIR" all -j"$(nproc)" --verbose
  ninja -C "$FLAVOR_BUILD_DIR" install
}

main() {
  echo ""
  echo "当前工作目录：$(pwd)"
  echo ""
  parse_arguments "$@"
  check_paths
  check_sdk
  check_cmake
  build
}

main "$@"

# cmake -DCMAKE_TOOLCHAIN_FILE="crosscompile.cmake" -G "Unix Makefiles" ../../source && ccmake ../../source
