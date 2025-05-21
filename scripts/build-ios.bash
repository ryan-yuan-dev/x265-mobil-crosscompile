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
# 指定 Android NDK 路径
NDK_PATH=
# 指定 Android SDK 路径
SDK_PATH=
# 指定 arch-abi
PLATFORM=OS64
# 指定 api 版本
API_VERSION="12.0"

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
  echo "- ANDROID_HOME sdk              所在目录，比如： /xx/Android/sdk"
  echo "- ANDROID_NDK ndk               所在目录，比如： /xx/Android/sdk/ndk/26.3.11579264"
  echo ""
  echo "- 选项:"
  echo "  -h                            显示此帮助信息"
  echo "  -S, --src_dir                 * 必传，指定源目录 DIR 为 CMakeLists.txt 文件所在路径"
  echo "  -B, --build_dir               * 必传，指定构建目录，必传"
  echo "  -I, --install_dir             * 必传，指定静态库和动态库的安装目录"
  echo "  --platform                    指定目标架构， 默认 OS64"
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
    --platform)
      PLATFORM="$2"
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

set_toolchain_file() {
  # 获取当前脚本的绝对路径
  local SCRIPT_PATH
  SCRIPT_PATH="$(realpath "$0")"
  SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
  echo "SCRIPT_PATH: ${SCRIPT_PATH}; SCRIPT_DIR: ${SCRIPT_DIR}"
  # CMAKE_TOOLCHAIN_FILE="${SCRIPT_DIR}/ios.toolchain.cmake"
  CMAKE_TOOLCHAIN_FILE="${SCRIPT_DIR}/../build/xcode/ios-cmake-toolchain.cmake"
  echo "CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}"
  if [ ! -f "${CMAKE_TOOLCHAIN_FILE}" ]; then
    echo "Error: CMAKE_TOOLCHAIN_FILE not found: ${CMAKE_TOOLCHAIN_FILE}"
    exit 1
  fi
}

# cmake  使用收集到的信息创建 Makefile
build() {
  FLAVOR_BUILD_DIR="${BUILD_DIR}/${PLATFORM}"
  FLAVOR_INSTALL_DIR="${INSTALL_DIR}/${PLATFORM}"
  mkdir -p "$FLAVOR_BUILD_DIR"
  mkdir -p "${FLAVOR_INSTALL_DIR}"
  echo "FLAVOR_BUILD_DIR: ${FLAVOR_BUILD_DIR}"
  echo "FLAVOR_INSTALL_DIR: ${FLAVOR_INSTALL_DIR}"
  cmake -S "$SOURCE_DIR" -B "$FLAVOR_BUILD_DIR" \
    -G "Ninja" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TOOLCHAIN_FILE}" \
    -DCMAKE_INSTALL_PREFIX="${FLAVOR_INSTALL_DIR}" \
    -DPLATFORM="$PLATFORM" \
    -DDEPLOYMENT_TARGET="$API_VERSION" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DENABLE_PIC="ON" \
    -DENABLE_BITCODE=1 \
    -DEXPORT_C_API=1 \
    -DENABLE_ASSEMBLY=0 \
    -DENABLE_CLI=0 \
    -DENABLE_VISIBILITY="ON"
  # cmake --build "${FLAVOR_BUILD_DIR}" --config Release -v
  # cd "${FLAVOR_BUILD_DIR}" && xcodebuild -scheme ALL_BUILD -configuration Release build
  # cmake --install "${FLAVOR_BUILD_DIR}" --config Release
  ninja -C "$FLAVOR_BUILD_DIR" clean
  ninja -C "$FLAVOR_BUILD_DIR" all -j"$(nproc)" --config Release
  ninja -C "$FLAVOR_BUILD_DIR" install
}

main() {
  echo ""
  echo "当前工作目录：$(pwd)"
  echo ""
  parse_arguments "$@"
  check_paths
  set_toolchain_file
  build
}

main "$@"

# cmake -DCMAKE_TOOLCHAIN_FILE="crosscompile.cmake" -G "Unix Makefiles" ../../source && ccmake ../../source
