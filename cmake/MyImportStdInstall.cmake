# プロジェクト固有のinstall／export・配布設定です。ターゲット定義の後にincludeしてください
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

block(SCOPE_FOR VARIABLES DIAGNOSTICS)
	cmake_diagnostic(PROMOTE CMD_INSTALL_ABSOLUTE_DESTINATION SEND_ERROR)
	install(TARGETS my_import_std_app my_import_std_modules
		EXPORT MyImportStdTargets
		RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}/$<CONFIG>"
		LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}/$<CONFIG>"
		ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}/$<CONFIG>"
		FILE_SET cxx_modules DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/my_import_std/modules"
		CXX_MODULES_BMI DESTINATION "${CMAKE_INSTALL_LIBDIR}/bmi/$<CONFIG>"
	)
	install(EXPORT MyImportStdTargets
		NAMESPACE MyImportStd::
		DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/MyImportStd"
		CXX_MODULES_DIRECTORY cxx-modules
	)

	configure_package_config_file(
		"${CMAKE_CURRENT_LIST_DIR}/MyImportStdConfig.cmake.in"
		"${PROJECT_BINARY_DIR}/MyImportStdConfig.cmake"
		INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/MyImportStd"
	)
	write_basic_package_version_file(
		"${PROJECT_BINARY_DIR}/MyImportStdConfigVersion.cmake"
		VERSION "${PROJECT_VERSION}"
		COMPATIBILITY SemanticVersion
	)
	install(FILES
		"${PROJECT_BINARY_DIR}/MyImportStdConfig.cmake"
		"${PROJECT_BINARY_DIR}/MyImportStdConfigVersion.cmake"
		DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/MyImportStd"
	)

	# CPackはここでこれらの変数を読み取り、独立した設定ファイルを生成する
	if(MY_IMPORT_STD_ENABLE_PACKAGING)
		set(CPACK_GENERATOR "ZIP")
		set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)
		set(CPACK_PACKAGE_CHECKSUM "SHA256")
		set(CPACK_VERBATIM_VARIABLES ON)
		if(NOT DEFINED CPACK_ARCHIVE_ENCODING)
			set(CPACK_ARCHIVE_ENCODING "UTF-8")
		endif()
		if(NOT DEFINED CPACK_PACKAGE_DIRECTORY)
			set(CPACK_PACKAGE_DIRECTORY "${PROJECT_SOURCE_DIR}/dist")
		endif()
		if(NOT IS_ABSOLUTE "${CPACK_PACKAGE_DIRECTORY}")
			message(FATAL_ERROR "CPACK_PACKAGE_DIRECTORYには絶対パスを指定してください")
		endif()
		set(CPACK_PACKAGE_FILE_NAME
			"${PROJECT_NAME}-${PROJECT_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}"
		)
		include(CPack)

		add_custom_target(verify-package-checksum
			COMMAND "${CMAKE_COMMAND}"
				"-DDIST_DIRECTORY=${CPACK_PACKAGE_DIRECTORY}"
				-P "${CMAKE_CURRENT_LIST_DIR}/VerifyPackageChecksums.cmake"
			COMMENT "Verifying package checksums"
			VERBATIM
		)
	endif()
endblock()
