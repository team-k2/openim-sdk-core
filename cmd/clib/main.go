package main

import "C"
import (
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk"
    _ "github.com/openimsdk/openim-sdk-core/v3/open_im_sdk_callback"
)

//export InitSDK
func InitSDK() {}

//export GetVersion
func GetVersion() *C.char {
    return C.CString("custom-fc140147-20251101-164706")
}

func main() {}
