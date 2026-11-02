# プロジェクト固有のinstall／export・配布設定です。ターゲット定義の後にincludeしてください
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)
include("${CMAKE_CURRENT_LIST_DIR}/generic-build-infrastructure/CxxGenericBuildInfrastructurePackaging.cmake")

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

	cmake_generic_build_infrastructure_register_distribution(
		CHECKSUM_TARGET verify-package-checksum
	)
endblock()
