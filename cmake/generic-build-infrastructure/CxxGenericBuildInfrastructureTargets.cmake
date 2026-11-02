include_guard(GLOBAL)

# 後続の標的に使う初期値を呼び出し元のスコープへ設定する
function(cmake_generic_build_infrastructure_set_output_directories)
	cmake_parse_arguments(PARSE_ARGN arg "" "ARCHIVE;LIBRARY;RUNTIME" "")
	if(DEFINED arg_UNPARSED_ARGUMENTS OR DEFINED arg_KEYWORDS_MISSING_VALUES OR
		NOT DEFINED arg_ARCHIVE OR NOT IS_ABSOLUTE "${arg_ARCHIVE}" OR
		NOT DEFINED arg_LIBRARY OR NOT IS_ABSOLUTE "${arg_LIBRARY}" OR
		NOT DEFINED arg_RUNTIME OR NOT IS_ABSOLUTE "${arg_RUNTIME}")
		message(FATAL_ERROR "cmake_generic_build_infrastructure_set_output_directories：ARCHIVE・LIBRARY・RUNTIMEには絶対パスを指定してください")
	endif()
	set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${arg_ARCHIVE}" PARENT_SCOPE)
	set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${arg_LIBRARY}" PARENT_SCOPE)
	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${arg_RUNTIME}" PARENT_SCOPE)
endfunction()

function(cmake_generic_build_infrastructure_use_static_msvc_runtime)
	if(ARGNC GREATER 0)
		message(FATAL_ERROR "cmake_generic_build_infrastructure_use_static_msvc_runtime：余分な引数が指定されています")
	endif()
	if(MSVC)
		set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>" PARENT_SCOPE)
	endif()
endfunction()

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
		$<$<CXX_COMPILER_FRONTEND_VARIANT:MSVC>:/EHsc>
		$<$<AND:$<CXX_COMPILER_FRONTEND_VARIANT:MSVC>,$<CXX_COMPILER_ID:MSVC>>:/MP>
		$<$<CXX_COMPILER_FRONTEND_VARIANT:GNU>:-Wall>
		$<$<CXX_COMPILER_FRONTEND_VARIANT:GNU>:-Wextra>
		$<$<CXX_COMPILER_FRONTEND_VARIANT:GNU>:-Wpedantic>
		$<$<AND:$<CXX_COMPILER_FRONTEND_VARIANT:GNU>,$<CXX_COMPILER_ID:Clang>>:-finput-charset=UTF-8>
	)
endfunction()

# WindowsでMSVC形式のlinkerを使う場合に、linker PDBの出力先を設定する
# OUTPUT_DIRECTORYは必須の絶対パス。他のプラットフォームでは標的を変更しない
function(cmake_generic_build_infrastructure_set_pdb_output_directory)
	cmake_parse_arguments(PARSE_ARGN arg "" "TARGET;OUTPUT_DIRECTORY" "")
	if(DEFINED arg_UNPARSED_ARGUMENTS OR DEFINED arg_KEYWORDS_MISSING_VALUES OR
		NOT DEFINED arg_TARGET OR arg_TARGET STREQUAL "" OR
		NOT DEFINED arg_OUTPUT_DIRECTORY OR arg_OUTPUT_DIRECTORY STREQUAL "")
		message(FATAL_ERROR "cmake_generic_build_infrastructure_set_pdb_output_directory：TARGET <target>とOUTPUT_DIRECTORY <path>を指定してください")
	endif()
	_cmake_generic_build_infrastructure_validate_target(cmake_generic_build_infrastructure_set_pdb_output_directory "${arg_TARGET}")
	if(NOT IS_ABSOLUTE "${arg_OUTPUT_DIRECTORY}")
		message(FATAL_ERROR "cmake_generic_build_infrastructure_set_pdb_output_directory：OUTPUT_DIRECTORYには絶対パスを指定してください")
	endif()
	if(WIN32 AND CMAKE_CXX_COMPILER_LINKER_FRONTEND_VARIANT STREQUAL "MSVC")
		set_target_properties("${arg_TARGET}" PROPERTIES
			PDB_OUTPUT_DIRECTORY "${arg_OUTPUT_DIRECTORY}"
		)
	endif()
endfunction()
