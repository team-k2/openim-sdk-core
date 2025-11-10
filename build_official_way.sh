#!/bin/bash

# 基於 OpenIM 官方 Makefile 的建置腳本
set -e

echo "================================================"
echo "🚀 Building SDKs using Official OpenIM Method"
echo "================================================"

# 設置 PATH
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin

# 檢查 gomobile 是否安裝
if ! command -v gomobile &> /dev/null; then
    echo "Installing gomobile..."
    go install golang.org/x/mobile/cmd/gomobile@latest
    go install golang.org/x/mobile/cmd/gobind@latest
    $GOPATH/bin/gomobile init
fi

echo ""
echo "📱 Building iOS SDK..."
echo "================================================"

# iOS 建置（完全按照官方 Makefile）
go get golang.org/x/mobile
rm -rf build/ open_im_sdk/t_friend_sdk.go open_im_sdk/t_group_sdk.go open_im_sdk/ws_wrapper/

GOARCH=arm64 gomobile bind -v -trimpath \
    -ldflags "-s -w" \
    -o build/OpenIMCore.xcframework \
    -target=ios \
    ./open_im_sdk/ ./open_im_sdk_callback/

if [ -d "build/OpenIMCore.xcframework" ]; then
    echo "✅ iOS SDK 建置成功！"
    echo "路徑: build/OpenIMCore.xcframework"
    du -sh build/OpenIMCore.xcframework
else
    echo "❌ iOS SDK 建置失敗"
    exit 1
fi

echo ""
echo "📱 Building Android SDK..."
echo "================================================"

# Android 建置（完全按照官方 Makefile）
go get golang.org/x/mobile/bind

GOARCH=amd64 gomobile bind -v -trimpath \
    -ldflags="-s -w" \
    -o ./open_im_sdk.aar \
    -target=android \
    ./open_im_sdk/ ./open_im_sdk_callback/

if [ -f "open_im_sdk.aar" ]; then
    echo "✅ Android SDK 建置成功！"
    echo "路徑: open_im_sdk.aar"
    ls -lh open_im_sdk.aar
else
    echo "❌ Android SDK 建置失敗"
    exit 1
fi

echo ""
echo "================================================"
echo "✅ 所有 SDK 建置完成！"
echo "================================================"
echo ""
echo "輸出文件："
echo "  iOS: build/OpenIMCore.xcframework"
echo "  Android: open_im_sdk.aar"
echo ""