# ターゲット・ABI・sysrootの選択はwasi-sdkのツールチェーンに委譲する
set(WASI_SDK_PATH "$ENV{WASI_SDK_PATH}" CACHE PATH "Absolute wasi-sdk installation root")
if(NOT IS_ABSOLUTE "${WASI_SDK_PATH}" OR
	NOT EXISTS "${WASI_SDK_PATH}/share/cmake/wasi-sdk.cmake")
	message(FATAL_ERROR "WASI SDKが見つかりません。share/cmake/wasi-sdk.cmakeを含む絶対パスをWASI_SDK_PATHに指定してください")
endif()
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES WASI_SDK_PATH)
include("${WASI_SDK_PATH}/share/cmake/wasi-sdk.cmake")
