cmake_minimum_required(VERSION 4.5)
if(NOT DEFINED CHECK_BINARY_DIR OR NOT IS_ABSOLUTE "${CHECK_BINARY_DIR}")
	message(FATAL_ERROR "CHECK_BINARY_DIRには絶対パスを指定してください")
endif()
cmake_path(CONVERT "${CHECK_BINARY_DIR}" TO_CMAKE_PATH_LIST CHECK_BINARY_DIR NORMALIZE)
cmake_path(GET CMAKE_COMMAND PARENT_PATH cmake_bin)
find_program(cpack_command NAMES cpack HINTS "${cmake_bin}" NO_DEFAULT_PATH REQUIRED)
set(module_dir "${CMAKE_CURRENT_LIST_DIR}/../../cmake/generic-build-infrastructure")
file(REAL_PATH "${module_dir}" module_dir)
set(source "${CHECK_BINARY_DIR}/source")
set(binary "${CHECK_BINARY_DIR}/build")
file(MAKE_DIRECTORY "${source}")
file(WRITE "${source}/BuildPayload.cmake" [=[
file(APPEND "${OUTPUT_DIR}/build-log.txt" "build\n")
file(WRITE "${OUTPUT_DIR}/payload.txt" "distribution fixture\n")
]=])
file(WRITE "${source}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 4.5)
project(DistributionFixture VERSION 1.2.3 LANGUAGES NONE)
include("${MODULE_DIR}/CxxGenericBuildInfrastructurePackaging.cmake")
add_custom_target(payload ALL
	COMMAND "${CMAKE_COMMAND}" "-DOUTPUT_DIR=${CMAKE_CURRENT_BINARY_DIR}"
		-P "${CMAKE_CURRENT_SOURCE_DIR}/BuildPayload.cmake"
)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/payload.txt" DESTINATION "share/$<CONFIG>")
enable_testing()
add_test(NAME payload COMMAND "${CMAKE_COMMAND}" -E compare_files
	"${CMAKE_CURRENT_BINARY_DIR}/payload.txt" "${CMAKE_CURRENT_BINARY_DIR}/payload.txt")
cmake_generic_build_infrastructure_register_distribution(CHECKSUM_TARGET verify-checksum)
]=])
set(presets [=[
{
	"version": 13,
	"configurePresets": [{
		"name": "fixture",
		"generator": "Ninja Multi-Config",
		"binaryDir": "@binary@",
		"cacheVariables": { "MODULE_DIR": "@module_dir@" }
	}],
	"buildPresets": [
		{ "name": "build", "configurePreset": "fixture", "configuration": "Release" },
		{ "name": "verify", "configurePreset": "fixture", "configuration": "Release",
			"targets": ["verify-checksum"],
			"environment": { "CGBI_PACKAGE_DIRECTORY": "${sourceDir}/packages" } },
		{ "name": "verify-relative", "inherits": "verify",
			"environment": { "CGBI_PACKAGE_DIRECTORY": "relative packages" } }
	],
	"testPresets": [{ "name": "test", "configurePreset": "fixture", "configuration": "Release" }],
	"packagePresets": [
		{ "name": "package-base", "hidden": true, "generators": ["ZIP"], "configurations": ["Release"],
			"variables": { "CPACK_INCLUDE_TOPLEVEL_DIRECTORY": "OFF", "CPACK_PACKAGE_FILE_NAME": "fixture" } },
		{ "name": "package", "inherits": "package-base", "configurePreset": "fixture",
			"configFile": "DistributionConfig.cmake",
			"environment": { "CGBI_PACKAGE_DIRECTORY": "${sourceDir}/packages" } },
		{ "name": "package-relative", "inherits": "package",
			"configFile": "DistributionConfig.cmake",
			"environment": { "CGBI_PACKAGE_DIRECTORY": "relative packages" } }
	],
	"workflowPresets": [{
		"name": "distribution",
		"steps": [
			{ "type": "configure", "name": "fixture" },
			{ "type": "build", "name": "build" },
			{ "type": "test", "name": "test" },
			{ "type": "package", "name": "package" },
			{ "type": "build", "name": "verify" }
		]
	}]
}
]=])
string(CONFIGURE "${presets}" presets @ONLY)
file(WRITE "${source}/CMakePresets.json" "${presets}")
execute_process(
	COMMAND "${CMAKE_COMMAND}" --preset fixture
	ENVIRONMENT "CGBI_PACKAGE_DIRECTORY=invalid-for-packaging"
	WORKING_DIRECTORY "${source}" COMMAND_ERROR_IS_FATAL ANY
)
file(READ "${binary}/DistributionConfig.cmake" adapter)
if(NOT adapter MATCHES "^include\\(\"[^\n]+\"\\)\n$")
	message(FATAL_ERROR "通常configureのCPack接続はincludeだけにしてください：${adapter}")
endif()
execute_process(
	COMMAND "${CMAKE_COMMAND}" --build "${binary}" --target help
	OUTPUT_VARIABLE targets COMMAND_ERROR_IS_FATAL ANY
)
if(targets MATCHES "(^|\n)package:")
	message(FATAL_ERROR "通常configureにCPackのpackage targetが登録されています")
endif()

function(check_package name expected)
	cmake_parse_arguments(PARSE_ARGN arg "" "" "")
	execute_process(
		COMMAND "${CMAKE_COMMAND}" -E env --unset=CGBI_PACKAGE_DIRECTORY
			"${cpack_command}" --config DistributionConfig.cmake ${arg_UNPARSED_ARGUMENTS}
		WORKING_DIRECTORY "${binary}"
		ENCODING UTF-8 OUTPUT_VARIABLE output ERROR_VARIABLE error RESULT_VARIABLE result
	)
	string(REGEX REPLACE "[ \t\r\n]+" " " diagnostic "${output}\n${error}")
	if(expected STREQUAL "success")
		if(NOT result EQUAL 0)
			message(FATAL_ERROR "${name}：配布に失敗しました：\n${output}\n${error}")
		endif()
	elseif(result EQUAL 0 OR NOT diagnostic MATCHES "${expected}")
		message(FATAL_ERROR "${name}：想定した入力エラーになりませんでした：\n${output}\n${error}")
	endif()
endfunction()

# ビルドしないままの配布は失敗し、配布処理からビルドを起動しない
file(REMOVE "${binary}/payload.txt" "${binary}/build-log.txt")
check_package(unbuilt "cannot find" -G ZIP -C Release)
if(EXISTS "${binary}/build-log.txt")
	message(FATAL_ERROR "配布処理がビルドを起動しました")
endif()
check_package(configuration-required "配布する構成を" -G ZIP)
check_package(configuration-invalid "配布する構成を" -G ZIP -C Unknown)
check_package(relative-directory "絶対パスを指定" -G ZIP -C Release -D CPACK_PACKAGE_DIRECTORY=relative)
check_package(filename "ディレクトリを含まない" -G ZIP -C Release -D CPACK_PACKAGE_FILE_NAME=../invalid)
check_package(generator "specified generator not found|Could not create CPack generator"
	-G Unknown -C Release)

execute_process(
	COMMAND "${CMAKE_COMMAND}" --workflow --preset distribution
	WORKING_DIRECTORY "${source}" COMMAND_ERROR_IS_FATAL ANY
)
file(READ "${binary}/build-log.txt" build_log)
if(NOT build_log STREQUAL "build\n")
	message(FATAL_ERROR "workflowのビルドが配布時に重複実行されています：${build_log}")
endif()
file(ARCHIVE_EXTRACT INPUT "${source}/packages/fixture.zip" DESTINATION "${CHECK_BINARY_DIR}/extracted")
file(READ "${CHECK_BINARY_DIR}/extracted/share/Release/payload.txt" payload)
if(NOT payload STREQUAL "distribution fixture\n")
	message(FATAL_ERROR "配布物の内容がinstall定義と一致しません")
endif()
check_package(standalone success -G ZIP -C Release
	-B "${CHECK_BINARY_DIR}/package output"
	-D CPACK_PACKAGE_FILE_NAME=standalone -D CPACK_INCLUDE_TOPLEVEL_DIRECTORY=OFF)
execute_process(
	COMMAND "${cpack_command}" --preset package-relative
	WORKING_DIRECTORY "${source}" COMMAND_ERROR_IS_FATAL ANY
)
if(NOT EXISTS "${binary}/relative packages/fixture.zip.sha256")
	message(FATAL_ERROR "相対的な配布先がconfigure presetのbuild先を基準にしていません")
endif()
execute_process(
	COMMAND "${CMAKE_COMMAND}" --build --preset verify-relative
	WORKING_DIRECTORY "${source}" COMMAND_ERROR_IS_FATAL ANY
)
execute_process(
	COMMAND "${cpack_command}" --config DistributionConfig.cmake -G ZIP -C Release
	ENVIRONMENT "CGBI_PACKAGE_DIRECTORY="
	WORKING_DIRECTORY "${binary}"
	ENCODING UTF-8 OUTPUT_VARIABLE output ERROR_VARIABLE error RESULT_VARIABLE result
)
if(result EQUAL 0 OR NOT error MATCHES "空でないパスを指定")
	message(FATAL_ERROR "空の配布先が拒否されませんでした：${output}\n${error}")
endif()
execute_process(
	COMMAND "${CMAKE_COMMAND}" "-DDIST_DIRECTORY=${CHECK_BINARY_DIR}/package output"
		-P "${module_dir}/VerifyPackageChecksums.cmake"
	COMMAND_ERROR_IS_FATAL ANY
)
file(READ "${binary}/build-log.txt" build_log)
if(NOT build_log STREQUAL "build\n")
	message(FATAL_ERROR "配布単独実行がビルドを起動しました")
endif()
check_package(multiple-configurations success -G ZIP -C "Debug;Release"
	-B "${CHECK_BINARY_DIR}/multiple configurations"
	-D CPACK_PACKAGE_FILE_NAME=combined -D CPACK_INCLUDE_TOPLEVEL_DIRECTORY=OFF)
file(ARCHIVE_EXTRACT INPUT "${CHECK_BINARY_DIR}/multiple configurations/combined.zip"
	DESTINATION "${CHECK_BINARY_DIR}/combined")
foreach(configuration IN ITEMS Debug Release)
	file(READ "${CHECK_BINARY_DIR}/combined/share/${configuration}/payload.txt" payload)
	if(NOT payload STREQUAL "distribution fixture\n")
		message(FATAL_ERROR "${configuration}のinstall内容が複数構成の配布物にありません")
	endif()
endforeach()
file(READ "${binary}/CxxGenericBuildInfrastructureBuild.cmake" metadata)
string(REPLACE "${binary}\"" "${CHECK_BINARY_DIR}/different\"" bad_metadata "${metadata}")
file(WRITE "${binary}/CxxGenericBuildInfrastructureBuild.cmake" "${bad_metadata}")
check_package(mismatched-build "ビルドディレクトリが一致しない" -G ZIP -C Release)
file(WRITE "${binary}/CxxGenericBuildInfrastructureBuild.cmake" "${metadata}")
set(multi_binary "${binary}")
set(binary "${CHECK_BINARY_DIR}/single")
execute_process(
	COMMAND "${CMAKE_COMMAND}" -S "${source}" -B "${binary}" -G Ninja
		"-DMODULE_DIR=${module_dir}" -DCMAKE_BUILD_TYPE=Release
	COMMAND_ERROR_IS_FATAL ANY
)
check_package(single-config-mismatch "CMAKE_BUILD_TYPEと一致しません" -G ZIP -C Debug)
execute_process(
	COMMAND "${CMAKE_COMMAND}" --build "${binary}"
	COMMAND_ERROR_IS_FATAL ANY
)
check_package(single-config success -G ZIP -C Release -B "${binary}/packages")
set(binary "${multi_binary}")
# metadataなしの場所から独立entryを使う場合も、黙って別のビルドを選択しない
execute_process(
	COMMAND "${cpack_command}" --config "${module_dir}/CPackConfig.cmake" -G ZIP
	WORKING_DIRECTORY "${source}"
	ENCODING UTF-8 OUTPUT_VARIABLE output ERROR_VARIABLE error RESULT_VARIABLE result
)
if(result EQUAL 0 OR NOT error MATCHES "ビルド情報がありません")
	message(FATAL_ERROR "ビルド情報の不足が診断されませんでした：${output}\n${error}")
endif()
message(STATUS "配布単独実行、workflow、成果物不足、実行時入力検証を確認しました")
