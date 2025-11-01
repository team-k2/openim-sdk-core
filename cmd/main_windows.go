package main

import "C"

// 這是 Windows DLL 的入口點
// 引入所有需要導出的包
import (
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk"
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk_callback"
)

func main() {
    // Windows DLL 不需要 main 函數實現
    // 但 Go 的 c-shared 模式需要這個入口點
}