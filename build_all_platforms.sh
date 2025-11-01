#!/bin/bash
# OpenIM SDK Core - 全平台 FFI 動態庫編譯腳本

set -e

echo "========================================="
echo "OpenIM SDK Core FFI 動態庫編譯"
echo "========================================="

SDK_CORE_PATH="/Users/macoluo/Projects/K2IM-github/openim-sdk-core"
FLUTTER_SDK_PATH="/Users/macoluo/Projects/K2IM-github/flutter_openim_sdk_ffi"
OUTPUT_DIR="$SDK_CORE_PATH/output"

# 創建輸出目錄
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/ios"
mkdir -p "$OUTPUT_DIR/android"
mkdir -p "$OUTPUT_DIR/macos"
mkdir -p "$OUTPUT_DIR/windows"

cd "$SDK_CORE_PATH"

# 設置環境變量
export PATH=$PATH:$(go env GOPATH)/bin
export CGO_ENABLED=1

echo -e "\n📱 1. 編譯 iOS Framework"
echo "================================"
echo "正在編譯 iOS (arm64)..."
if command -v gomobile &> /dev/null; then
    # 初始化 gomobile
    gomobile init 2>/dev/null || true

    # 編譯 iOS
    gomobile bind -v \
        -target=ios \
        -o "$OUTPUT_DIR/ios/OpenIMCore.xcframework" \
        -ldflags="-s -w" \
        ./open_im_sdk ./open_im_sdk_callback

    if [ -d "$OUTPUT_DIR/ios/OpenIMCore.xcframework" ]; then
        echo "✅ iOS Framework 編譯成功"
        echo "   位置: $OUTPUT_DIR/ios/OpenIMCore.xcframework"

        # 複製到 Flutter SDK
        cp -r "$OUTPUT_DIR/ios/OpenIMCore.xcframework" "$FLUTTER_SDK_PATH/ios/" 2>/dev/null || true
    else
        echo "❌ iOS Framework 編譯失敗"
    fi
else
    echo "⚠️  gomobile 未安裝，跳過 iOS 編譯"
fi

echo -e "\n🤖 2. 編譯 Android AAR"
echo "================================"
echo "正在編譯 Android (arm64-v8a, armeabi-v7a, x86_64)..."
if command -v gomobile &> /dev/null; then
    gomobile bind -v \
        -target=android \
        -androidapi 21 \
        -o "$OUTPUT_DIR/android/openim-sdk.aar" \
        -ldflags="-s -w" \
        ./open_im_sdk ./open_im_sdk_callback

    if [ -f "$OUTPUT_DIR/android/openim-sdk.aar" ]; then
        echo "✅ Android AAR 編譯成功"
        echo "   位置: $OUTPUT_DIR/android/openim-sdk.aar"

        # 複製到 Flutter SDK
        mkdir -p "$FLUTTER_SDK_PATH/android/libs"
        cp "$OUTPUT_DIR/android/openim-sdk.aar" "$FLUTTER_SDK_PATH/android/libs/" 2>/dev/null || true
    else
        echo "❌ Android AAR 編譯失敗"
    fi
else
    echo "⚠️  gomobile 未安裝，跳過 Android 編譯"
fi

echo -e "\n💻 3. 編譯 macOS 動態庫"
echo "================================"
echo "正在編譯 macOS (x86_64, arm64)..."

# macOS x86_64
GOARCH=amd64 go build -buildmode=c-shared \
    -ldflags="-s -w" \
    -o "$OUTPUT_DIR/macos/libopenim_sdk_x86_64.dylib" \
    ./open_im_sdk

# macOS arm64
GOARCH=arm64 go build -buildmode=c-shared \
    -ldflags="-s -w" \
    -o "$OUTPUT_DIR/macos/libopenim_sdk_arm64.dylib" \
    ./open_im_sdk

# 創建通用二進制文件（Universal Binary）
if [ -f "$OUTPUT_DIR/macos/libopenim_sdk_x86_64.dylib" ] && [ -f "$OUTPUT_DIR/macos/libopenim_sdk_arm64.dylib" ]; then
    lipo -create \
        "$OUTPUT_DIR/macos/libopenim_sdk_x86_64.dylib" \
        "$OUTPUT_DIR/macos/libopenim_sdk_arm64.dylib" \
        -output "$OUTPUT_DIR/macos/libopenim_sdk.dylib"

    echo "✅ macOS 通用動態庫編譯成功"
    echo "   位置: $OUTPUT_DIR/macos/libopenim_sdk.dylib"

    # 複製到 Flutter SDK
    mkdir -p "$FLUTTER_SDK_PATH/macos/libs"
    cp "$OUTPUT_DIR/macos/libopenim_sdk.dylib" "$FLUTTER_SDK_PATH/macos/libs/" 2>/dev/null || true
    cp "$OUTPUT_DIR/macos/libopenim_sdk.h" "$FLUTTER_SDK_PATH/macos/libs/" 2>/dev/null || true
else
    echo "❌ macOS 動態庫編譯失敗"
fi

echo -e "\n🪟 4. 編譯 Windows DLL"
echo "================================"
echo "正在編譯 Windows (x64)..."

# Windows 需要交叉編譯
if command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    CC=x86_64-w64-mingw32-gcc \
    GOOS=windows GOARCH=amd64 CGO_ENABLED=1 \
    go build -buildmode=c-shared \
        -ldflags="-s -w" \
        -o "$OUTPUT_DIR/windows/openim_sdk_x64.dll" \
        ./open_im_sdk

    if [ -f "$OUTPUT_DIR/windows/openim_sdk_x64.dll" ]; then
        echo "✅ Windows x64 DLL 編譯成功"
        echo "   位置: $OUTPUT_DIR/windows/openim_sdk_x64.dll"

        # 複製到 Flutter SDK
        mkdir -p "$FLUTTER_SDK_PATH/windows/libs"
        cp "$OUTPUT_DIR/windows/openim_sdk_x64.dll" "$FLUTTER_SDK_PATH/windows/libs/" 2>/dev/null || true
        cp "$OUTPUT_DIR/windows/openim_sdk_x64.h" "$FLUTTER_SDK_PATH/windows/libs/" 2>/dev/null || true
    fi
else
    echo "⚠️  MinGW 未安裝，無法編譯 Windows DLL"
    echo "   安裝方法: brew install mingw-w64"
fi

# Windows ARM64（可選）
if command -v aarch64-w64-mingw32-gcc &> /dev/null; then
    CC=aarch64-w64-mingw32-gcc \
    GOOS=windows GOARCH=arm64 CGO_ENABLED=1 \
    go build -buildmode=c-shared \
        -ldflags="-s -w" \
        -o "$OUTPUT_DIR/windows/openim_sdk_arm64.dll" \
        ./open_im_sdk

    if [ -f "$OUTPUT_DIR/windows/openim_sdk_arm64.dll" ]; then
        echo "✅ Windows ARM64 DLL 編譯成功"
        echo "   位置: $OUTPUT_DIR/windows/openim_sdk_arm64.dll"
    fi
fi

echo -e "\n📊 5. 編譯結果總結"
echo "================================"
echo "輸出目錄: $OUTPUT_DIR"
echo ""
echo "已生成的文件:"
ls -la "$OUTPUT_DIR"/*/ 2>/dev/null || true

echo -e "\n✅ 編譯完成！"
echo ""
echo "使用方法:"
echo "1. iOS: 將 OpenIMCore.xcframework 添加到 Xcode 項目"
echo "2. Android: 將 openim-sdk.aar 添加到 Android 項目"
echo "3. macOS: 將 libopenim_sdk.dylib 複製到應用包"
echo "4. Windows: 將 openim_sdk_x64.dll 複製到應用目錄"
echo ""
echo "Flutter SDK 集成:"
echo "動態庫已自動複製到 flutter_openim_sdk_ffi 對應目錄"