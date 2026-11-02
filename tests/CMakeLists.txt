add_executable(my_import_std_module_tests module_tests.cpp)
target_link_libraries(my_import_std_module_tests PRIVATE MyImportStd::modules)
set_target_properties(my_import_std_module_tests PROPERTIES CXX_EXTENSIONS OFF)
my_import_std_apply_compile_settings(TARGET my_import_std_module_tests)
cmake_generic_build_infrastructure_set_pdb_output_directory(
	TARGET my_import_std_module_tests
	OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/$<CONFIG>/bin"
)

add_test(NAME my_import_std.module COMMAND my_import_std_module_tests)
add_test(NAME my_import_std.app COMMAND my_import_std_app)
set_tests_properties(my_import_std.app PROPERTIES PASS_REGULAR_EXPRESSION "Module answer: 42")
if(MY_IMPORT_STD_BUILD_EXAMPLES)
	add_test(NAME my_import_std.example COMMAND my_import_std_example)
endif()

add_test(NAME my_import_std.cmake_helpers
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}/helper checks"
		"-DCHECK_COMPILER=${CMAKE_CXX_COMPILER}"
		"-DCHECK_COMPILER_TARGET=${CMAKE_CXX_COMPILER_TARGET}"
		"-DCHECK_ARCH=${MY_IMPORT_STD_TARGET_ARCH}"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunChecks.cmake"
	BUILD_DEPENDS
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureTargets.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructurePlatform.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/MyImportStdTargetSettings.cmake"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunChecks.cmake"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/CMakeLists.txt"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/main.cpp"
)
add_test(NAME my_import_std.checksums
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}/checksum checks"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunChecksumChecks.cmake"
	BUILD_DEPENDS
		"${PROJECT_SOURCE_DIR}/cmake/VerifyPackageChecksums.cmake"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunChecksumChecks.cmake"
)
add_test(NAME my_import_std.toolchains
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}/toolchain checks"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunToolchainChecks.cmake"
	BUILD_DEPENDS
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Emscripten.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/WASI.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/toolchains/Windows.cmake"
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunToolchainChecks.cmake"
)

add_test(NAME my_import_std.cmake_features
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}/feature checks"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunFeatureChecks.cmake"
	BUILD_DEPENDS
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunFeatureChecks.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/MyImportStdInstall.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureTargets.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/SaveInstrumentation.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake"
)

add_test(NAME my_import_std.preset_axes
	COMMAND "${CMAKE_COMMAND}"
		"-DCHECK_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}/preset checks"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunPresetChecks.cmake"
	BUILD_DEPENDS
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunPresetChecks.cmake"
		"${PROJECT_SOURCE_DIR}/CMakePresets.json"
		"${PROJECT_SOURCE_DIR}/cmake/presets/CMakeGenericBuildInfrastructurePresets.json"
		"${PROJECT_SOURCE_DIR}/cmake/presets/CMakeProjectPresets.json"
		"${PROJECT_SOURCE_DIR}/work/cmake-refactoring/CMakePresets.json"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureTargets.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructurePlatform.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake"
		"${PROJECT_SOURCE_DIR}/cmake/generic-build-infrastructure/SaveInstrumentation.cmake"
)