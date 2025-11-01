# 🔧 OpenIM SDK Core - FFI 動態庫編譯指南

## 📊 各平台編譯狀態

| 平台 | 架構 | 編譯工具 | 前置需求 | 編譯命令 |
|------|------|----------|---------|----------|
| **iOS** | arm64 | gomobile | Xcode | `gomobile bind -target=ios` |
| **Android** | arm64-v8a, armeabi-v7a, x86_64 | gomobile | Android SDK | `gomobile bind -target=android` |
| **macOS** | arm64, x86_64 | go build | 無 | `go build -buildmode=c-archive` |
| **Windows** | x64, arm64 | go build + mingw | MinGW | `GOOS=windows go build` |
| **Linux** | x64, arm64 | go build | 無 | `go build -buildmode=c-shared` |

## 🚀 快速開始

### 環境準備

```bash
# 1. 安裝 gomobile
go install golang.org/x/mobile/cmd/gomobile@latest
go install golang.org/x/mobile/cmd/gobind@latest

# 2. 設置環境變量
export PATH=$PATH:$(go env GOPATH)/bin

# 3. 初始化 gomobile
gomobile init
```

## 📱 iOS 編譯

### 前置需求
- macOS 系統
- Xcode 已安裝
- Xcode Command Line Tools

### 編譯命令
```bash
cd /Users/macoluo/Projects/K2IM-github/openim-sdk-core

# 編譯 iOS Framework
gomobile bind -v \
    -target=ios \
    -o flutter_openim_sdk_ffi/ios/OpenIMCore.xcframework \
    -ldflags="-s -w" \
    ./open_im_sdk ./open_im_sdk_callback
```

### Flutter 集成
```yaml
# ios/Runner.xcodeproj
# 1. 將 OpenIMCore.xcframework 拖入項目
# 2. Embed & Sign 設置
# 3. 在 Info.plist 添加必要權限
```

## 🤖 Android 編譯

### 前置需求
- Android SDK (API 21+)
- NDK
- 設置 ANDROID_HOME 環境變量

### 環境設置
```bash
# macOS/Linux
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 或安裝 Android Studio 自動配置
```

### 編譯命令
```bash
# 編譯 Android AAR
gomobile bind -v \
    -target=android \
    -androidapi 21 \
    -o flutter_openim_sdk_ffi/android/openim-sdk.aar \
    -ldflags="-s -w" \
    ./open_im_sdk ./open_im_sdk_callback
```

### Flutter 集成
```gradle
// android/app/build.gradle
dependencies {
    implementation files('libs/openim-sdk.aar')
}
```

## 💻 macOS 編譯

### 方法 A: 靜態庫（推薦）
```bash
# 編譯靜態庫
go build -buildmode=c-archive \
    -ldflags="-s -w" \
    -o output/macos/libopenim_sdk.a \
    ./cmd/clib

# 生成頭文件
go tool cgo -exportheader output/macos/libopenim_sdk.h ./cmd/clib
```

### 方法 B: 使用 gomobile（如果有 main 包）
```bash
# 創建 cmd/clib/main.go
cat > cmd/clib/main.go << 'EOF'
package main

import "C"
import (
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk"
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk_callback"
)

func main() {}
EOF

# 編譯
go build -buildmode=c-shared \
    -o output/macos/libopenim_sdk.dylib \
    ./cmd/clib
```

### Flutter 集成
```yaml
# macos/Runner/DebugProfile.entitlements
<key>com.apple.security.cs.disable-library-validation</key>
<true/>
```

## 🪟 Windows 編譯

### 前置需求
```bash
# macOS/Linux 交叉編譯
brew install mingw-w64  # macOS
apt-get install mingw-w64  # Linux
```

### 編譯命令
```bash
# Windows x64
CC=x86_64-w64-mingw32-gcc \
GOOS=windows GOARCH=amd64 CGO_ENABLED=1 \
go build -buildmode=c-shared \
    -ldflags="-s -w" \
    -o output/windows/openim_sdk.dll \
    ./cmd/clib

# Windows ARM64
CC=aarch64-w64-mingw32-gcc \
GOOS=windows GOARCH=arm64 CGO_ENABLED=1 \
go build -buildmode=c-shared \
    -ldflags="-s -w" \
    -o output/windows/openim_sdk_arm64.dll \
    ./cmd/clib
```

### Flutter 集成
```cmake
# windows/CMakeLists.txt
target_link_libraries(${BINARY_NAME} PRIVATE openim_sdk.dll)
```

## 🐧 Linux 編譯

```bash
# Linux x64
GOOS=linux GOARCH=amd64 \
go build -buildmode=c-shared \
    -ldflags="-s -w" \
    -o output/linux/libopenim_sdk.so \
    ./cmd/clib

# Linux ARM64
GOOS=linux GOARCH=arm64 \
go build -buildmode=c-shared \
    -ldflags="-s -w" \
    -o output/linux/libopenim_sdk_arm64.so \
    ./cmd/clib
```

## 📦 預編譯版本下載

如果無法自行編譯，可以使用預編譯版本：

| 平台 | 下載連結 | SHA256 |
|------|---------|---------|
| iOS | [OpenIMCore.xcframework.zip](#) | `待提供` |
| Android | [openim-sdk.aar](#) | `待提供` |
| macOS | [libopenim_sdk.dylib](#) | `待提供` |
| Windows x64 | [openim_sdk.dll](#) | `待提供` |
| Linux x64 | [libopenim_sdk.so](#) | `待提供` |

## 🔍 驗證編譯結果

### iOS
```bash
# 檢查 Framework 結構
ls -la OpenIMCore.xcframework/
# 應包含 Info.plist 和各架構目錄
```

### Android
```bash
# 解壓 AAR 查看內容
unzip -l openim-sdk.aar
# 應包含 classes.jar 和 jni/ 目錄
```

### macOS/Linux
```bash
# 檢查導出符號
nm -g libopenim_sdk.dylib | grep EditMessage
# 應顯示導出的函數
```

### Windows
```bash
# 使用 dumpbin 或 objdump
objdump -p openim_sdk.dll | grep EditMessage
```

## ⚠️ 常見問題

### 1. iOS 編譯失敗
```
錯誤: requires Xcode
解決: 安裝 Xcode 並運行 xcode-select --install
```

### 2. Android 編譯失敗
```
錯誤: could not locate Android SDK
解決: 安裝 Android Studio 或設置 ANDROID_HOME
```

### 3. Windows 交叉編譯失敗
```
錯誤: x86_64-w64-mingw32-gcc: command not found
解決: brew install mingw-w64
```

### 4. 符號未導出
```
錯誤: undefined symbol
解決: 確保函數名首字母大寫，添加 //export 注釋
```

## 📝 集成測試

創建測試文件驗證動態庫：

```dart
// test_ffi.dart
import 'dart:ffi';
import 'dart:io';

void main() {
  final DynamicLibrary lib = Platform.isAndroid
      ? DynamicLibrary.open('libopenim_sdk.so')
      : Platform.isIOS
          ? DynamicLibrary.process()
          : Platform.isMacOS
              ? DynamicLibrary.open('libopenim_sdk.dylib')
              : Platform.isWindows
                  ? DynamicLibrary.open('openim_sdk.dll')
                  : DynamicLibrary.open('libopenim_sdk.so');

  print('動態庫載入成功: $lib');
}
```

## 🚀 自動化編譯腳本

使用 GitHub Actions 自動編譯：

```yaml
# .github/workflows/build-ffi.yml
name: Build FFI Libraries

on:
  push:
    branches: [ main ]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-go@v2
      - run: |
          go install golang.org/x/mobile/cmd/gomobile@latest
          gomobile init
          gomobile bind -target=android -o openim-sdk.aar ./open_im_sdk

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-go@v2
      - run: |
          go install golang.org/x/mobile/cmd/gomobile@latest
          gomobile init
          gomobile bind -target=ios -o OpenIMCore.xcframework ./open_im_sdk
```

---

**提示**: 如果本地編譯遇到困難，建議：
1. 使用 CI/CD 系統（GitHub Actions）進行編譯
2. 使用 Docker 容器隔離編譯環境
3. 聯繫團隊獲取預編譯版本