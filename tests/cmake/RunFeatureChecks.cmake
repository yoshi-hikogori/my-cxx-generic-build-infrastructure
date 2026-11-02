cmake_minimum_required(VERSION 4.5)
if(NOT DEFINED CHECK_BINARY_DIR OR NOT IS_ABSOLUTE "${CHECK_BINARY_DIR}")
	message(FATAL_ERROR "CHECK_BINARY_DIRには絶対パスを指定してください")
endif()
cmake_path(CONVERT "${CHECK_BINARY_DIR}" TO_CMAKE_PATH_LIST CHECK_BINARY_DIR NORMALIZE)

function(check_keyword_only)
	cmake_parse_arguments(PARSE_ARGN arg "" "TARGET;VALUE" "")
	if(NOT ARGNC EQUAL ARGC OR NOT arg_TARGET STREQUAL "OFF" OR
		NOT arg_VALUE STREQUAL "a;b" OR NOT DEFINED arg_UNPARSED_ARGUMENTS OR
		NOT arg_UNPARSED_ARGUMENTS STREQUAL "OFF")
		message(FATAL_ERROR "キーワードだけの引数解析で値が保持されていません")
	endif()
endfunction()
check_keyword_only(TARGET OFF VALUE "a;b" OFF)

function(check_named_prefix required)
	cmake_parse_arguments(PARSE_ARGN arg "" "VALUE" "")
	if(NOT required STREQUAL "prefix" OR NOT ARGNC EQUAL 2 OR NOT arg_VALUE STREQUAL "a;b")
		message(FATAL_ERROR "名前付き引数の後から始める解析位置が正しくありません")
	endif()
endfunction()
check_named_prefix(prefix VALUE "a;b")

function(check_empty_extra first second)
	if(NOT ARGNC EQUAL 1)
		message(FATAL_ERROR "ARGNCは空の追加引数も数える必要があります")
	endif()
endfunction()
check_empty_extra(one two "")

function(check_missing_value)
	cmake_parse_arguments(PARSE_ARGN arg "" "TARGET" "")
	if(NOT arg_KEYWORDS_MISSING_VALUES STREQUAL "TARGET")
		message(FATAL_ERROR "キーワードに値がない状態を検出できませんでした")
	endif()
endfunction()
check_missing_value(TARGET)

include(CMakePackageConfigHelpers)
file(MAKE_DIRECTORY "${CHECK_BINARY_DIR}")
foreach(version IN ITEMS 0.1.2 1.2.3)
	write_basic_package_version_file(
		"${CHECK_BINARY_DIR}/${version}.cmake"
		VERSION "${version}" COMPATIBILITY SemanticVersion
	)
endforeach()

function(check_compatibility installed requested expected)
	set(PACKAGE_FIND_VERSION "${requested}")
	string(REPLACE "." ";" components "${requested}")
	list(GET components 0 PACKAGE_FIND_VERSION_MAJOR)
	list(GET components 1 PACKAGE_FIND_VERSION_MINOR)
	list(GET components 2 PACKAGE_FIND_VERSION_PATCH)
	include("${CHECK_BINARY_DIR}/${installed}.cmake")
	if(NOT "${PACKAGE_VERSION_COMPATIBLE}" STREQUAL "${expected}")
		message(FATAL_ERROR "${installed}と${requested}：想定外の互換性判定です：${PACKAGE_VERSION_COMPATIBLE}")
	endif()
endfunction()
check_compatibility(0.1.2 0.1.1 TRUE)
check_compatibility(0.1.2 0.1.2 TRUE)
check_compatibility(0.1.2 0.0.1 FALSE)
check_compatibility(0.1.2 0.1.3 FALSE)
check_compatibility(1.2.3 1.1.0 TRUE)
check_compatibility(1.2.3 2.0.0 FALSE)
message(STATUS "引数解析とSemanticVersionのテストを確認しました")

set(fixture_source "${CHECK_BINARY_DIR}/source")
set(fixture_binary "${CHECK_BINARY_DIR}/build")
file(MAKE_DIRECTORY "${fixture_source}")
file(WRITE "${fixture_source}/input.txt" "initial\n")
file(WRITE "${fixture_source}/日本語 sample.txt" "UTF-8 archive entry\n")
file(WRITE "${fixture_source}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 4.5)
project(FeatureFixture LANGUAGES NONE)
include("${INSTRUMENTATION_MODULE}")
include("${PACKAGING_MODULE}")
cmake_generic_build_infrastructure_enable_instrumentation(
	OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/instrumentation"
)
enable_testing()
add_test(NAME tracked COMMAND "${CMAKE_COMMAND}" -E true
	BUILD_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/input.txt")
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/日本語 sample.txt" DESTINATION share)
set(CPACK_ARCHIVE_COMPRESSION_LEVEL 6)
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)
cmake_generic_build_infrastructure_enable_packaging(
	GENERATORS ZIP
	OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
	FILE_NAME fixture
	CHECKSUM_TARGET verify-fixture-checksum
)
if(DEFINED CPACK_PACKAGE_FILE_NAME OR DEFINED CPACK_PACKAGE_CHECKSUM OR DEFINED arg_OUTPUT_DIRECTORY)
	message(FATAL_ERROR "配布関数の一時変数が外部に漏れています")
endif()
]=])

execute_process(
	COMMAND "${CMAKE_COMMAND}" -S "${fixture_source}" -B "${fixture_binary}" -G Ninja
		"-DINSTRUMENTATION_MODULE=${CMAKE_CURRENT_LIST_DIR}/../../cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake"
		"-DPACKAGING_MODULE=${CMAKE_CURRENT_LIST_DIR}/../../cmake/generic-build-infrastructure/CxxGenericBuildInfrastructurePackaging.cmake"
	ENVIRONMENT "CMAKE_SYSTEM_ENVIRONMENT_ID=fixture-environment-1"
	ENVIRONMENT_MODIFICATION "CMAKE_SYSTEM_ENVIRONMENT_ACTION=unset:"
	COMMAND_ERROR_IS_FATAL ANY
)
execute_process(
	ENCODING UTF-8
	COMMAND "${CMAKE_COMMAND}" -S "${fixture_source}" -B "${fixture_binary}"
	ENVIRONMENT "CMAKE_SYSTEM_ENVIRONMENT_ID=fixture-environment-2"
	ENVIRONMENT_MODIFICATION "CMAKE_SYSTEM_ENVIRONMENT_ACTION=unset:"
	OUTPUT_VARIABLE output ERROR_VARIABLE error RESULT_VARIABLE result
)
if(NOT result EQUAL 0 OR NOT error MATCHES "Does not match the previous value")
	message(FATAL_ERROR "環境識別子の変更が診断されませんでした：\n${output}\n${error}")
endif()

cmake_path(GET CMAKE_COMMAND PARENT_PATH cmake_bin)
find_program(ctest_command NAMES ctest HINTS "${cmake_bin}" NO_DEFAULT_PATH REQUIRED)
find_program(cpack_command NAMES cpack HINTS "${cmake_bin}" NO_DEFAULT_PATH REQUIRED)
execute_process(
	COMMAND "${CMAKE_COMMAND}" --build "${fixture_binary}" --target test_prep/all install_prep/all
	COMMAND_ERROR_IS_FATAL ANY
)
execute_process(
	COMMAND "${ctest_command}" --test-dir "${fixture_binary}" --output-on-failure
	COMMAND_ERROR_IS_FATAL ANY
)
execute_process(
	ENCODING UTF-8
	COMMAND "${ctest_command}" --test-dir "${fixture_binary}" --out-of-date
	OUTPUT_VARIABLE output ERROR_VARIABLE error RESULT_VARIABLE result
)
if(NOT result EQUAL 0 OR NOT "${output}\n${error}" MATCHES "No tests were found")
	message(FATAL_ERROR "変更されていない依存関係のテストが省略されませんでした：\n${output}\n${error}")
endif()
execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 1.1 COMMAND_ERROR_IS_FATAL ANY)
file(WRITE "${fixture_source}/input.txt" "changed\n")
execute_process(
	ENCODING UTF-8
	COMMAND "${ctest_command}" --test-dir "${fixture_binary}" --out-of-date --output-on-failure
	OUTPUT_VARIABLE output ERROR_VARIABLE error RESULT_VARIABLE result
)
if(NOT result EQUAL 0 OR NOT output MATCHES "1/1 Test")
	message(FATAL_ERROR "変更された依存関係に対応するテストが選択されませんでした：\n${output}\n${error}")
endif()

execute_process(
	COMMAND "${cpack_command}" --config "${fixture_binary}/CPackConfig.cmake" -B "${fixture_binary}"
	COMMAND_ERROR_IS_FATAL ANY
)
execute_process(
	ENCODING UTF-8
	COMMAND "${CMAKE_COMMAND}" --build "${fixture_binary}" --target verify-fixture-checksum
	COMMAND_ERROR_IS_FATAL ANY
)
file(ARCHIVE_EXTRACT INPUT "${fixture_binary}/fixture.zip" DESTINATION "${fixture_binary}/extracted")
file(READ "${fixture_binary}/extracted/share/日本語 sample.txt" content)
if(NOT content STREQUAL "UTF-8 archive entry\n")
	message(FATAL_ERROR "ZIP内のUTF-8ファイル名を正しく読み戻せませんでした")
endif()
file(GLOB indexes "${fixture_binary}/instrumentation/index/*.json")
if(NOT indexes)
	message(FATAL_ERROR "Instrumentationのindexが保持されていません")
endif()
foreach(index_path IN LISTS indexes)
	file(READ "${index_path}" index)
	string(JSON saved_data_dir GET "${index}" dataDir)
	if(NOT saved_data_dir STREQUAL "${fixture_binary}/instrumentation")
		message(FATAL_ERROR "保存したInstrumentation indexのdataDirが更新されていません")
	endif()
	string(JSON snippets ARRAY_SPLIT "${index}" snippets)
	foreach(element IN LISTS snippets)
		string(JSON relative GET "${element}")
		if(NOT EXISTS "${saved_data_dir}/${relative}")
			message(FATAL_ERROR "indexに記録されたInstrumentationデータが保持されていません：${relative}")
		endif()
	endforeach()
endforeach()
message(STATUS "準備処理、差分テスト、環境識別子、UTF-8 ZIP、Instrumentationデータの保持を確認しました")

set(packaging_source "${CHECK_BINARY_DIR}/packaging-inputs")
file(MAKE_DIRECTORY "${packaging_source}")
file(WRITE "${packaging_source}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 4.5)
project(PackagingInputs LANGUAGES NONE)
include("${PACKAGING_MODULE}")
set(arguments GENERATORS ZIP OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
	FILE_NAME fixture CHECKSUM_TARGET verify-checksum)
if(CASE STREQUAL "relative")
	set(arguments GENERATORS ZIP OUTPUT_DIRECTORY relative FILE_NAME fixture CHECKSUM_TARGET verify-checksum)
elseif(CASE STREQUAL "filename")
	set(arguments GENERATORS ZIP OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
		FILE_NAME "../fixture" CHECKSUM_TARGET verify-checksum)
elseif(CASE STREQUAL "missing")
	set(arguments GENERATORS ZIP OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" FILE_NAME)
elseif(CASE STREQUAL "unknown")
	list(APPEND arguments UNKNOWN OFF)
elseif(CASE STREQUAL "duplicate")
	add_custom_target(verify-checksum)
elseif(CASE STREQUAL "target")
	set(arguments GENERATORS ZIP OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
		FILE_NAME fixture CHECKSUM_TARGET "bad::target")
elseif(CASE STREQUAL "generator")
	set(arguments OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" FILE_NAME fixture CHECKSUM_TARGET verify-checksum)
endif()
cmake_generic_build_infrastructure_enable_packaging(${arguments})
]=])
foreach(case IN ITEMS relative filename missing unknown duplicate target generator)
	execute_process(
		ENCODING UTF-8
		COMMAND "${CMAKE_COMMAND}" -S "${packaging_source}" -B "${CHECK_BINARY_DIR}/packaging-${case}" -G Ninja
			"-DCASE=${case}"
			"-DPACKAGING_MODULE=${CMAKE_CURRENT_LIST_DIR}/../../cmake/generic-build-infrastructure/CxxGenericBuildInfrastructurePackaging.cmake"
		RESULT_VARIABLE result OUTPUT_VARIABLE output ERROR_VARIABLE error
	)
	string(REGEX REPLACE "[ \t\r\n]+" " " diagnostic "${output}\n${error}")
	if(case STREQUAL "filename")
		set(expected "FILE_NAMEにはディレクトリを含まない配布物の名前")
	elseif(case MATCHES "^(duplicate|target)$")
		set(expected "CHECKSUM_TARGETには未使用の有効なターゲット名")
	else()
		set(expected "絶対パスのOUTPUT_DIRECTORY、FILE_NAME、CHECKSUM_TARGET、GENERATORS")
	endif()
	if(result EQUAL 0 OR NOT diagnostic MATCHES "${expected}")
		message(FATAL_ERROR "配布設定 ${case}：想定した入力エラーになりませんでした：\n${output}\n${error}")
	endif()
endforeach()
message(STATUS "配布関数の入力検証を確認しました")
