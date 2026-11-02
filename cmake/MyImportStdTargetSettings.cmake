include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/generic-build-infrastructure/CxxGenericBuildInfrastructureCPU.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake")

# この案件で採用するコンパイル設定を各標的に適用する
function(my_import_std_apply_compile_settings)
	cmake_parse_arguments(PARSE_ARGN arg "" "TARGET" "")
	if(DEFINED arg_UNPARSED_ARGUMENTS OR DEFINED arg_KEYWORDS_MISSING_VALUES OR
		NOT DEFINED arg_TARGET OR arg_TARGET STREQUAL "")
		message(FATAL_ERROR "my_import_std_apply_compile_settings：TARGET <target>を指定してください")
	endif()
	cmake_generic_build_infrastructure_apply_compile_settings(TARGET "${arg_TARGET}")
	if(MY_IMPORT_STD_ENABLE_AVX2)
		cmake_generic_build_infrastructure_apply_cpu_settings(TARGET "${arg_TARGET}" ENABLE_AVX2 ON)
	endif()
	if(MY_IMPORT_STD_ENABLE_INSTRUMENTATION)
		cmake_generic_build_infrastructure_apply_compile_trace(TARGET "${arg_TARGET}")
	endif()
endfunction()
