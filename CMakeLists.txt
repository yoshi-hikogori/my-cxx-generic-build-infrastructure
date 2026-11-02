cmake_minimum_required(VERSION 4.5.0)

project(my_import_std VERSION 0.1.0 LANGUAGES CXX)

include(CTest)
include("${PROJECT_SOURCE_DIR}/cmake/MyImportStdTargetSettings.cmake")

if(DEFINED MY_IMPORT_STD_ENABLE_MODULES AND NOT MY_IMPORT_STD_ENABLE_MODULES)
	message(FATAL_ERROR "このプロジェクトではC++モジュールが必須です。MY_IMPORT_STD_ENABLE_MODULES=OFFはもう対応していません")
endif()
cmake_generic_build_infrastructure_require_module_generator()

option(MY_IMPORT_STD_ENABLE_PCH "Enable precompiled headers" ON)
option(MY_IMPORT_STD_BUILD_EXAMPLES "Build example projects" OFF)
option(MY_IMPORT_STD_ENABLE_AVX2 "Require AVX2 support on the target CPU" OFF)
option(MY_IMPORT_STD_USE_STATIC_RUNTIME "Use the statically linked MSVC runtime" OFF)
option(MY_IMPORT_STD_ENABLE_INSTRUMENTATION "Collect local build timing, output and Clang traces" OFF)
set(MY_IMPORT_STD_TARGET_ARCH "" CACHE STRING "Required target architecture: x86_64 or aarch64; empty delegates to the toolchain")
set_property(CACHE MY_IMPORT_STD_TARGET_ARCH PROPERTY STRINGS "" x86_64 aarch64)
set(MY_IMPORT_STD_CPU_BASELINE "" CACHE STRING "Required CPU baseline: x86-64-v3 or armv8.2-a; empty uses compiler defaults")
set_property(CACHE MY_IMPORT_STD_CPU_BASELINE PROPERTY STRINGS "" x86-64-v3 armv8.2-a)
set(MY_IMPORT_STD_TARGET_ENVIRONMENT "" CACHE STRING "Required target environment: gnu for Linux/glibc; empty delegates to the toolchain")
set_property(CACHE MY_IMPORT_STD_TARGET_ENVIRONMENT PROPERTY STRINGS "" gnu)
my_import_std_validate_target_platform()

if(MY_IMPORT_STD_ENABLE_INSTRUMENTATION)
	cmake_generic_build_infrastructure_enable_instrumentation(
		OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/instrumentation"
	)
endif()

if(MY_IMPORT_STD_USE_STATIC_RUNTIME)
	cmake_generic_build_infrastructure_use_static_msvc_runtime()
endif()

add_library(my_import_std_modules STATIC)
add_library(MyImportStd::modules ALIAS my_import_std_modules)
target_sources(my_import_std_modules
	PUBLIC
		FILE_SET cxx_modules TYPE CXX_MODULES
		BASE_DIRS src/modules
		FILES src/modules/my_import_std.cppm
)
target_compile_features(my_import_std_modules PUBLIC cxx_std_23)
set_target_properties(my_import_std_modules PROPERTIES
	EXPORT_NAME modules
)
my_import_std_apply_compile_settings(TARGET my_import_std_modules)

add_executable(my_import_std_app src/app/main.cpp)
target_link_libraries(my_import_std_app PRIVATE MyImportStd::modules)
set_target_properties(my_import_std_app PROPERTIES
	VS_DEBUGGER_WORKING_DIRECTORY "$<TARGET_FILE_DIR:my_import_std_app>"
)
my_import_std_apply_compile_settings(TARGET my_import_std_app)

if(MY_IMPORT_STD_ENABLE_PCH)
	target_precompile_headers(my_import_std_app PRIVATE
		<iostream>
	)
endif()

if(MY_IMPORT_STD_BUILD_EXAMPLES)
	add_executable(my_import_std_example examples/module_consumer.cpp)
	target_link_libraries(my_import_std_example PRIVATE MyImportStd::modules)
	my_import_std_apply_compile_settings(TARGET my_import_std_example)
endif()

if(BUILD_TESTING)
	add_subdirectory(tests)
endif()

include("${PROJECT_SOURCE_DIR}/cmake/MyImportStdInstall.cmake")
