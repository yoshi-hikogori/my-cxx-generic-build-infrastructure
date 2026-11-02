include_guard(GLOBAL)

# install定義の後に呼ぶ。配布対象・形式・保存先・ファイル名は案件側で決める
function(cmake_generic_build_infrastructure_enable_packaging)
	cmake_parse_arguments(PARSE_ARGN arg "" "OUTPUT_DIRECTORY;FILE_NAME;CHECKSUM_TARGET" "GENERATORS")
	if(DEFINED arg_UNPARSED_ARGUMENTS OR DEFINED arg_KEYWORDS_MISSING_VALUES OR
		NOT DEFINED arg_OUTPUT_DIRECTORY OR NOT IS_ABSOLUTE "${arg_OUTPUT_DIRECTORY}" OR
		NOT DEFINED arg_FILE_NAME OR arg_FILE_NAME STREQUAL "" OR
		NOT DEFINED arg_CHECKSUM_TARGET OR arg_CHECKSUM_TARGET STREQUAL "" OR
		NOT DEFINED arg_GENERATORS OR arg_GENERATORS STREQUAL "")
		message(FATAL_ERROR "cmake_generic_build_infrastructure_enable_packaging：絶対パスのOUTPUT_DIRECTORY、FILE_NAME、CHECKSUM_TARGET、GENERATORSを指定してください")
	endif()
	if(arg_FILE_NAME MATCHES "[/\\\\;]" OR arg_FILE_NAME STREQUAL "." OR arg_FILE_NAME STREQUAL "..")
		message(FATAL_ERROR "FILE_NAMEにはディレクトリを含まない配布物の名前を指定してください")
	endif()
	if(NOT arg_CHECKSUM_TARGET MATCHES "^[A-Za-z0-9_.+-]+$" OR TARGET "${arg_CHECKSUM_TARGET}")
		message(FATAL_ERROR "CHECKSUM_TARGETには未使用の有効なターゲット名を指定してください")
	endif()

	set(CPACK_GENERATOR "${arg_GENERATORS}")
	set(CPACK_PACKAGE_DIRECTORY "${arg_OUTPUT_DIRECTORY}")
	set(CPACK_PACKAGE_FILE_NAME "${arg_FILE_NAME}")
	set(CPACK_PACKAGE_CHECKSUM "SHA256")
	set(CPACK_VERBATIM_VARIABLES ON)
	if(NOT DEFINED CPACK_ARCHIVE_ENCODING)
		set(CPACK_ARCHIVE_ENCODING "UTF-8")
	endif()
	# CPack用変数は関数内で読み取り、生成した設定ファイルに保持する
	include(CPack)

	add_custom_target("${arg_CHECKSUM_TARGET}"
		COMMAND "${CMAKE_COMMAND}"
			"-DDIST_DIRECTORY=${arg_OUTPUT_DIRECTORY}"
			-P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/VerifyPackageChecksums.cmake"
		COMMENT "配布物のSHA-256検査合計を検証する"
		VERBATIM
	)
endfunction()
