include_guard(GLOBAL)

# CPackをconfigure時に実行せず、ビルド情報と明示実行用のchecksum操作だけを登録する
function(cmake_generic_build_infrastructure_register_distribution)
	cmake_parse_arguments(PARSE_ARGN arg "" "CHECKSUM_TARGET" "")
	if(DEFINED arg_UNPARSED_ARGUMENTS OR DEFINED arg_KEYWORDS_MISSING_VALUES OR
		NOT DEFINED arg_CHECKSUM_TARGET OR arg_CHECKSUM_TARGET STREQUAL "")
		message(FATAL_ERROR "cmake_generic_build_infrastructure_register_distribution：CHECKSUM_TARGETを指定してください")
	endif()
	if(NOT arg_CHECKSUM_TARGET MATCHES "^[A-Za-z0-9_.+-]+$" OR TARGET "${arg_CHECKSUM_TARGET}")
		message(FATAL_ERROR "CHECKSUM_TARGETには未使用の有効なターゲット名を指定してください")
	endif()

	set(CGBI_PROJECT_NAME "${PROJECT_NAME}")
	set(CGBI_PROJECT_VERSION "${PROJECT_VERSION}")
	set(CGBI_SOURCE_DIR "${CMAKE_SOURCE_DIR}")
	set(CGBI_BINARY_DIR "${CMAKE_BINARY_DIR}")
	set(CGBI_SYSTEM_NAME "${CMAKE_SYSTEM_NAME}")
	set(CGBI_SYSTEM_PROCESSOR "${CMAKE_SYSTEM_PROCESSOR}")
	set(CGBI_GENERATOR "${CMAKE_GENERATOR}")
	set(CGBI_CONFIGURATIONS "${CMAKE_CONFIGURATION_TYPES}")
	set(CGBI_BUILD_TYPE "${CMAKE_BUILD_TYPE}")
	set(metadata "")
	foreach(key IN ITEMS PROJECT_NAME PROJECT_VERSION SOURCE_DIR BINARY_DIR
		SYSTEM_NAME SYSTEM_PROCESSOR GENERATOR CONFIGURATIONS BUILD_TYPE)
		set(value "${CGBI_${key}}")
		string(REPLACE "\\" "\\\\" value "${value}")
		string(REPLACE "\"" "\\\"" value "${value}")
		string(REPLACE "$" "\\$" value "${value}")
		string(APPEND metadata "set(CGBI_${key} \"${value}\")\n")
	endforeach()
	set(metadata_file "${CMAKE_BINARY_DIR}/CxxGenericBuildInfrastructureBuild.cmake")
	file(WRITE "${metadata_file}" "${metadata}")
	set(entry "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CPackConfig.cmake")
	string(REPLACE "\"" "\\\"" entry "${entry}")
	string(REPLACE "$" "\\$" entry "${entry}")
	file(WRITE "${CMAKE_BINARY_DIR}/DistributionConfig.cmake" "include(\"${entry}\")\n")

	add_custom_target("${arg_CHECKSUM_TARGET}"
		COMMAND "${CMAKE_COMMAND}"
			"-DBUILD_METADATA_FILE=${metadata_file}"
			-P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/VerifyPackageChecksums.cmake"
		COMMENT "配布物のSHA-256検査合計を検証する"
		VERBATIM
	)
endfunction()
