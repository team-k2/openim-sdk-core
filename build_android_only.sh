#!/bin/bash

# Android SDK 單獨建置腳本
set -e

echo "================================================"
echo "📱 Building Android SDK Only"
echo "================================================"

# 設置 PATH
export GOPATH=$(go env GOPATH)
export PATH=$PATH:$GOPATH/bin

echo "Go version: $(go version)"
echo "GOPATH: $GOPATH"
echo "gomobile location: $(which gomobile || echo 'not found')"
echo ""

# Android 建置（完全按照官方 Makefile）
echo "Running: go get golang.org/x/mobile/bind"
go get golang.org/x/mobile/bind

echo ""
echo "Running gomobile bind for Android..."
GOARCH=amd64 gomobile bind -v -trimpath \
    -ldflags="-s -w" \
    -o ./open_im_sdk.aar \
    -target=android \
    ./open_im_sdk/ ./open_im_sdk_callback/

if [ -f "open_im_sdk.aar" ]; then
    echo ""
    echo "✅ Android SDK 建置成功！"
    echo "路徑: open_im_sdk.aar"
    ls -lh open_im_sdk.aar
    echo ""
    echo "AAR 檔案內容："
    unzip -l open_im_sdk.aar | head -20
else
    echo ""
    echo "❌ Android SDK 建置失敗"
    exit 1
fi
