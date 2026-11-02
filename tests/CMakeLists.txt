add_executable(my_import_std_module_tests module_tests.cpp)
target_link_libraries(my_import_std_module_tests PRIVATE MyImportStd::modules)
my_import_std_apply_compile_settings(TARGET my_import_std_module_tests)

# nested try_compileのパス長をpreset名から切り離し、同時実行する構成も隔離する
string(SHA256 check_build_id "${PROJECT_BINARY_DIR}")
string(SUBSTRING "${check_build_id}" 0 16 check_build_id)
set(check_root "${PROJECT_SOURCE_DIR}/build/.checks/${check_build_id}/$<CONFIG>")

add_test(NAME my_import_std.module COMMAND my_import_std_module_tests)
add_test(NAME my_import_std.app COMMAND my_import_std_app)
set_tests_properties(my_import_std.app PROPERTIES PASS_REGULAR_EXPRESSION "Module answer: 42")
if(MY_IMPORT_STD_BUILD_EXAMPLES)
	add_test(NAME my_import_std.example COMMAND my_import_std_example)
endif()

add_test(NAME my_import_std.cmake_helpers
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${check_root}/helpers"
		"-DCHECK_COMPILER=${CMAKE_CXX_COMPILER}"
		"-DCHECK_COMPILER_TARGET=${CMAKE_CXX_COMPILER_TARGET}"
		"-DCHECK_ARCH=${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunChecks.cmake"
	BUILD_DEPENDS
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureTargets.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureCPU.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/MyImportStdTargetSettings.cmake"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunChecks.cmake"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/CMakeLists.txt"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/main.cpp"
)
add_test(NAME my_import_std.checksums
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${check_root}/checksums"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunChecksumChecks.cmake"
	BUILD_DEPENDS
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/VerifyPackageChecksums.cmake"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunChecksumChecks.cmake"
)
add_test(NAME my_import_std.cpu_baseline
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${check_root}/cpu"
		"-DCHECK_COMPILER=${CMAKE_CXX_COMPILER}"
		"-DCHECK_ARCH=${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunCpuBaselineChecks.cmake"
	BUILD_DEPENDS
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunCpuBaselineChecks.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Windows.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Linux.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/CpuBaseline.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/InitializeCpuBaseline.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureCPU.cmake"
)
add_test(NAME my_import_std.toolchains
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${check_root}/toolchains"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunToolchainChecks.cmake"
	BUILD_DEPENDS
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Emscripten.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/WASI.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Windows.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Linux.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/CpuBaseline.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/InitializeCpuBaseline.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureCPU.cmake"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunToolchainChecks.cmake"
)

add_test(NAME my_import_std.cmake_features
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${check_root}/features"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunFeatureChecks.cmake"
	BUILD_DEPENDS
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunFeatureChecks.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/MyImportStdInstall.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructurePackaging.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CPackConfig.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/InstallPackage.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/ValidatePackage.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/VerifyPackageChecksums.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureTargets.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/SaveInstrumentation.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake"
)

add_test(NAME my_import_std.preset_axes
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${check_root}/presets"
		"-DCHECK_PROJECT_BINARY_DIR=${PROJECT_BINARY_DIR}"
		"-DCHECK_CONFIGURATION=$<CONFIG>"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunPresetChecks.cmake"
	BUILD_DEPENDS
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunPresetChecks.cmake"
		"${PROJECT_SOURCE_DIR}/CMakePresets.json"
		"${PROJECT_SOURCE_DIR}/CMakeUserPresets.json"
		"${PROJECT_SOURCE_DIR}/cmake/presets/CMakeRecommendedUserPresets.json"
		"${PROJECT_SOURCE_DIR}/cmake/presets/CMakeGenericBuildInfrastructurePresets.json"
		"${PROJECT_SOURCE_DIR}/work/cmake-refactoring/CMakePresets.json"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureTargets.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureCPU.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/SaveInstrumentation.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Windows.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Linux.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Emscripten.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/WASI.cmake"
)

add_test(NAME my_import_std.distribution
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${check_root}/distribution"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunDistributionChecks.cmake"
	BUILD_DEPENDS
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunDistributionChecks.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructurePackaging.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CPackConfig.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/InstallPackage.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/ValidatePackage.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/VerifyPackageChecksums.cmake"
)