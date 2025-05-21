# 🔧 [x265-mobil-crosscompile](https://github.com/ryan-yuan-dev/x265-mobil-crosscompile) 项目说明

本项目提供一套完整的构建脚本和工具链配置，用于在 macOS 系统上交叉编译 x265 编码器库，生成适用于移动平台（Android、iOS、OHOS）的动态链接库（.so, .dylib, .so）。

## 📱 支持的平台

- Android 支持多种 ABI：armeabi-v7a, arm64-v8a, x86_64, x86
- iOS 架构支持：arm64, x86_64，手机和模拟器
- HarmonyOS（OHOS）： 当前支持标准 C/C++ 接口调用的动态库构建

## 使用说明（待完善）

重点参照 `scripts` 目录下的编译脚本。

以下示例演示了使用脚本的具体方式：

```shell
# 查看 android 交叉编译脚本帮助信息
bash scripts/build-android.sh -h

# 一行代码编译各平台的动态库
# - iOS 手机 arm64 动态库
# - android arm64-v8a 动态库
# - ohos arm64-v8a 动态库
bash build-all.bash
```

## 待补充
