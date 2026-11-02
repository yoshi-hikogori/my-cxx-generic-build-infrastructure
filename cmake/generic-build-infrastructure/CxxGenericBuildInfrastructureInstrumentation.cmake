include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/CxxGenericBuildInfrastructureTargets.cmake")

function(cmake_generic_build_infrastructure_enable_instrumentation)
	cmake_parse_arguments(PARSE_ARGN arg "" "OUTPUT_DIRECTORY" "")
	if(DEFINED arg_UNPARSED_ARGUMENTS OR DEFINED arg_KEYWORDS_MISSING_VALUES OR
		NOT DEFINED arg_OUTPUT_DIRECTORY OR NOT IS_ABSOLUTE "${arg_OUTPUT_DIRECTORY}")
		message(FATAL_ERROR "cmake_generic_build_infrastructure_enable_instrumentation：OUTPUT_DIRECTORYには絶対パスを指定してください")
	endif()
	# CMakeの収集データ外、かつビルドディレクトリ内という制約はcallbackでも検証する
	cmake_instrumentation(
		API_VERSION 1
		DATA_VERSION 1.2
		HOOKS postGenerate postCMakeBuild postCMakeInstall postCTest
		OPTIONS captureOutput compileTrace trace
		CALLBACK "${CMAKE_COMMAND}"
			"-DOUTPUT_DIRECTORY=${arg_OUTPUT_DIRECTORY}"
			-P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/SaveInstrumentation.cmake"
	)
endfunction()

function(cmake_generic_build_infrastructure_apply_compile_trace)
	cmake_parse_arguments(PARSE_ARGN arg "" "TARGET" "")
	if(DEFINED arg_UNPARSED_ARGUMENTS OR DEFINED arg_KEYWORDS_MISSING_VALUES OR
		NOT DEFINED arg_TARGET OR arg_TARGET STREQUAL "")
		message(FATAL_ERROR "cmake_generic_build_infrastructure_apply_compile_trace：TARGET <target>を指定してください")
	endif()
	_cmake_generic_build_infrastructure_validate_target(cmake_generic_build_infrastructure_apply_compile_trace "${arg_TARGET}")
	if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
		target_compile_options("${arg_TARGET}" PRIVATE -ftime-trace)
	endif()
endfunction()
