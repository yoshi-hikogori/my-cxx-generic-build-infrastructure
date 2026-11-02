include_guard(GLOBAL)

function(_cmake_generic_build_infrastructure_validate_target caller target)
	if(ARGNC GREATER 0)
		message(FATAL_ERROR "${caller}：余分な引数が指定されています")
	endif()
	if(NOT TARGET "${target}")
		message(FATAL_ERROR "${caller}：ターゲットが存在しません：${target}")
	endif()
	get_target_property(is_imported "${target}" IMPORTED)
	get_target_property(target_type "${target}" TYPE)
	if(is_imported OR
		NOT target_type MATCHES "^(EXECUTABLE|STATIC_LIBRARY|SHARED_LIBRARY|MODULE_LIBRARY|OBJECT_LIBRARY)$")
		message(FATAL_ERROR "${caller}：TARGETはローカルのコンパイル可能なターゲットを指定してください")
	endif()
endfunction()

# ローカルのコンパイル可能なターゲットに共通の非公開C++コンパイラ設定を適用する
function(cmake_generic_build_infrastructure_apply_compile_settings)
	cmake_parse_arguments(PARSE_ARGN arg "" "TARGET" "")
	if(DEFINED arg_UNPARSED_ARGUMENTS OR DEFINED arg_KEYWORDS_MISSING_VALUES OR
		NOT DEFINED arg_TARGET OR arg_TARGET STREQUAL "")
		message(FATAL_ERROR "cmake_generic_build_infrastructure_apply_compile_settings：TARGET <target>を指定してください")
	endif()
	_cmake_generic_build_infrastructure_validate_target(cmake_generic_build_infrastructure_apply_compile_settings "${arg_TARGET}")

	target_compile_options("${arg_TARGET}" PRIVATE
		$<$<CXX_COMPILER_FRONTEND_VARIANT:MSVC>:/W4>
		$<$<CXX_COMPILER_FRONTEND_VARIANT:MSVC>:/permissive->
		$<$<CXX_COMPILER_FRONTEND_VARIANT:MSVC>:/utf-8>
		$<$<CXX_COMPILER_FRONTEND_VARIANT:MSVC>:/Zc:__cplusplus>
		$<$<CXX_COMPILER_FRONTEND_VARIANT:GNU>:-Wall>
		$<$<CXX_COMPILER_FRONTEND_VARIANT:GNU>:-Wextra>
		$<$<CXX_COMPILER_FRONTEND_VARIANT:GNU>:-Wpedantic>
		$<$<AND:$<CXX_COMPILER_FRONTEND_VARIANT:GNU>,$<CXX_COMPILER_ID:Clang>>:-finput-charset=UTF-8>
	)
endfunction()
