include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/generic-build-infrastructure/CxxGenericBuildInfrastructurePlatform.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake")

function(_my_import_std_cpu_options output)
	if(ARGNC GREATER 0)
		message(FATAL_ERROR "_my_import_std_cpu_options：余分な引数が指定されています")
	endif()
	_cmake_generic_build_infrastructure_cpu_options(options "${MY_IMPORT_STD_CPU_BASELINE}")
	set("${output}" "${options}" PARENT_SCOPE)
endfunction()

function(my_import_std_validate_target_platform)
	if(ARGNC GREATER 0)
		message(FATAL_ERROR "my_import_std_validate_target_platform：余分な引数が指定されています")
	endif()
	cmake_generic_build_infrastructure_validate_target_platform(
		TARGET_ARCH "${MY_IMPORT_STD_TARGET_ARCH}"
		CPU_BASELINE "${MY_IMPORT_STD_CPU_BASELINE}"
		TARGET_ENVIRONMENT "${MY_IMPORT_STD_TARGET_ENVIRONMENT}"
		ENABLE_AVX2 "${MY_IMPORT_STD_ENABLE_AVX2}"
	)
endfunction()

# この案件で採用するコンパイル設定を各標的に適用する
function(my_import_std_apply_compile_settings)
	cmake_parse_arguments(PARSE_ARGN arg "" "TARGET" "")
	if(DEFINED arg_UNPARSED_ARGUMENTS OR DEFINED arg_KEYWORDS_MISSING_VALUES OR
		NOT DEFINED arg_TARGET OR arg_TARGET STREQUAL "")
		message(FATAL_ERROR "my_import_std_apply_compile_settings：TARGET <target>を指定してください")
	endif()
	cmake_generic_build_infrastructure_apply_compile_settings(TARGET "${arg_TARGET}")
	cmake_generic_build_infrastructure_apply_cpu_settings(
		TARGET "${arg_TARGET}"
		TARGET_ARCH "${MY_IMPORT_STD_TARGET_ARCH}"
		CPU_BASELINE "${MY_IMPORT_STD_CPU_BASELINE}"
		ENABLE_AVX2 "${MY_IMPORT_STD_ENABLE_AVX2}"
	)
	if(MY_IMPORT_STD_ENABLE_INSTRUMENTATION)
		cmake_generic_build_infrastructure_apply_compile_trace(TARGET "${arg_TARGET}")
	endif()
endfunction()
