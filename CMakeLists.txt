cmake_minimum_required(VERSION 3.12)
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.4" CACHE STRING "Minimum MacOS deployment version")

project(LabRecorder
	DESCRIPTION "Record and write LabStreamingLayer streams to an XDF file"
	HOMEPAGE_URL "https://github.com/labstreaminglayer/App-LabRecorder/"
	LANGUAGES C CXX
	VERSION 1.17.0)

# Needed for customized MacOSXBundleInfo.plist.in
SET(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake" ${CMAKE_MODULE_PATH})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED On)

option(BUILD_GUI "Build the GUI, set to off for CLI only build" ON)
option(LABRECORDER_SINGLE_FILE_EXE "Enable Windows single-file EXE packaging (optional)" OFF)
set(SEVENZIP_DIR "" CACHE PATH "Path to 7-Zip installation directory containing 7z.exe and 7z.sfx")

set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO")
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "")

# Dependencies
# list(APPEND CMAKE_MODULE_PATH "C:/Users/pho/repos/EmotivEpoc/LSL_REPOS/LSL/liblsl/build/install/lib/cmake/LSL")
list(APPEND CMAKE_MODULE_PATH "C:/Users/pho/repos/EmotivEpoc/LSL_REPOS/LSL/liblsl/out/install/x64-Debug/lib/cmake/LSL")

set_source_files_properties("./res/app.icns" PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

# Platform-specific icon resources
if(WIN32)
    set(app_icon_resource_windows "res/app.rc")
endif()

if(APPLE)
    set(MACOSX_BUNDLE_ICON_FILE app.icns)
    set_source_files_properties(res/app.icns PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    set(MACOSX_BUNDLE_GUI_IDENTIFIER "org.labstreaminglayer.LabRecorder")
    set(MACOSX_BUNDLE_BUNDLE_NAME "LabRecorder")
    set(MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}")
    set(MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}")
    set(MACOSX_BUNDLE_LONG_VERSION_STRING "${PROJECT_VERSION}")
    set(MACOSX_BUNDLE_COPYRIGHT "Lab Streaming Layer")
endif()

# Include the LSLCMake.cmake file, just for testing.
# This doesn't do much for us now that we don't use installLSLApp() anymore.
# include("${LSL_PATH}/LSLCMake.cmake")

## LSL
if(ANDROID)
	set(LIBLSL_SOURCE_PATH "../../LSL/liblsl" CACHE STRING "Path to liblsl sources")

	# force include liblsl as target to build with the android toolchain
	# as path of the normal build process
	add_subdirectory(${LIBLSL_SOURCE_PATH} liblsl_bin)
	add_library(LSL::lsl ALIAS lsl)
else()
	find_package(LSL REQUIRED
		HINTS ${LSL_INSTALL_ROOT}
		"${CMAKE_CURRENT_LIST_DIR}/../../LSL/liblsl/build/"
		"${CMAKE_CURRENT_LIST_DIR}/../../LSL/liblsl/build/install"
		"${CMAKE_CURRENT_LIST_DIR}/../../LSL/liblsl/out/build/x64-Release"
		"${CMAKE_CURRENT_LIST_DIR}/../../LSL/liblsl/out/install/x64-Release"
		PATH_SUFFIXES share/LSL
	)
endif()

if (BUILD_GUI)
    ## Qt
	set(CMAKE_AUTOMOC ON)  # The later version of this in LSLCMake is somehow not enough.
	set(CMAKE_AUTORCC ON)
	set(CMAKE_AUTOUIC ON)
	find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
	find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Widgets Network DBus)
endif(BUILD_GUI)

## Threads
find_package(Threads REQUIRED)

# Targets

## xdfwriter - stand alone library
add_subdirectory(xdfwriter)

if (BUILD_GUI)
	if(APPLE)
		add_executable(${PROJECT_NAME} MACOSX_BUNDLE ${app_icon_resource_windows} res/app.icns)
	else()
		add_executable(${PROJECT_NAME} MACOSX_BUNDLE ${app_icon_resource_windows})
	endif()

	target_sources(${PROJECT_NAME} PRIVATE
		src/main.cpp
		src/mainwindow.cpp
		src/mainwindow.h
		src/mainwindow.ui
		src/recording.h
		src/recording.cpp
		src/tcpinterface.h
		src/tcpinterface.cpp
		src/IconFlasher.h
		src/IconFlasher.cpp
	)

    target_link_libraries(${PROJECT_NAME}
		PRIVATE
		xdfwriter
		Qt${QT_VERSION_MAJOR}::Core
		Qt${QT_VERSION_MAJOR}::Widgets
		Qt${QT_VERSION_MAJOR}::Network
		Qt${QT_VERSION_MAJOR}::DBus
		Threads::Threads
		LSL::lsl
	)

	# macOS bundle settings
	if(APPLE)
		set_target_properties(${PROJECT_NAME} PROPERTIES
			MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_LIST_DIR}/cmake/MacOSXBundleInfo.plist.in"
		)
	endif()
endif(BUILD_GUI)

if(APPLE)
add_executable(LabRecorderCLI MACOSX_BUNDLE
	src/clirecorder.cpp
	src/recording.h
	src/recording.cpp
)
else()
add_executable(LabRecorderCLI
	src/clirecorder.cpp
	src/recording.h
	src/recording.cpp
)
endif()


target_link_libraries(LabRecorderCLI
	PRIVATE
	xdfwriter
	Threads::Threads
	LSL::lsl
)

# if((DEFINED LSL_INSTALL) AND (NOT LSL_INSTALL))
# 	return()
# endif()

include(GNUInstallDirs)

# Minimal install rules to provide an INSTALL target for multi-config generators
install(TARGETS xdfwriter
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(TARGETS LabRecorderCLI
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (BUILD_GUI)
    install(TARGETS ${PROJECT_NAME}
        BUNDLE DESTINATION ${CMAKE_INSTALL_BINDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

    install(FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.cfg
        LICENSE
        README.md
        DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}
    )
else()
    install(FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.cfg
        LICENSE
        README.md
        DESTINATION ${CMAKE_INSTALL_DATADIR}/LabRecorderCLI
    )
endif()




if (WIN32)
	if(BUILD_GUI)
		get_target_property(QT_QMAKE_EXECUTABLE Qt::qmake IMPORTED_LOCATION)
		get_filename_component(QT_WINDEPLOYQT_EXECUTABLE ${QT_QMAKE_EXECUTABLE} PATH)
		set(QT_WINDEPLOYQT_EXECUTABLE "${QT_WINDEPLOYQT_EXECUTABLE}/windeployqt.exe")

		add_custom_command(
			TARGET ${PROJECT_NAME} POST_BUILD
			COMMAND ${QT_WINDEPLOYQT_EXECUTABLE}
			--no-translations --no-system-d3d-compiler
			--qmldir ${CMAKE_CURRENT_SOURCE_DIR}
			$<TARGET_FILE:${PROJECT_NAME}>)

		add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:LSL::lsl>
			$<TARGET_FILE:xdfwriter>
			$<TARGET_FILE_DIR:${PROJECT_NAME}>)

		# Optional: package GUI into a single-file EXE using a PowerShell script and 7-Zip SFX
		if(LABRECORDER_SINGLE_FILE_EXE)
			set(LABRECORDER_PACK_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/scripts/windows/make-single-file-exe.ps1")
			add_custom_target(package-single-file-exe ALL
				DEPENDS ${PROJECT_NAME}
				COMMAND powershell -NoProfile -ExecutionPolicy Bypass -File
					"${LABRECORDER_PACK_SCRIPT}"
					-AppExe "$<TARGET_FILE:${PROJECT_NAME}>"
					-OutDir "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
					-OutputExe "$<TARGET_FILE_DIR:${PROJECT_NAME}>/LabRecorder-single.exe"
					-SevenZipDir "${SEVENZIP_DIR}"
				WORKING_DIRECTORY $<TARGET_FILE_DIR:${PROJECT_NAME}>
			)
		endif()
	else()
		add_custom_command(TARGET LabRecorderCLI POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:LSL::lsl>
			$<TARGET_FILE:xdfwriter>
			$<TARGET_FILE_DIR:LabRecorderCLI>)
	endif(BUILD_GUI)
endif()

if (BUILD_GUI)
	add_custom_command(
		TARGET ${PROJECT_NAME} POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy
		${CMAKE_CURRENT_SOURCE_DIR}//${PROJECT_NAME}.cfg
		$<TARGET_FILE_DIR:${PROJECT_NAME}>)
	add_custom_command(
		TARGET ${PROJECT_NAME} POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy
		${CMAKE_CURRENT_SOURCE_DIR}//LICENSE
		$<TARGET_FILE_DIR:${PROJECT_NAME}>)
	add_custom_command(
		TARGET ${PROJECT_NAME} POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy
		${CMAKE_CURRENT_SOURCE_DIR}//README.md
		$<TARGET_FILE_DIR:${PROJECT_NAME}>)
else()
	add_custom_command(
		TARGET LabRecorderCLI POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy
		${CMAKE_CURRENT_SOURCE_DIR}//${PROJECT_NAME}.cfg
		$<TARGET_FILE_DIR:LabRecorderCLI>)
	add_custom_command(
		TARGET LabRecorderCLI POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy
		${CMAKE_CURRENT_SOURCE_DIR}//LICENSE
		$<TARGET_FILE_DIR:LabRecorderCLI>)
	add_custom_command(
		TARGET LabRecorderCLI POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy
		${CMAKE_CURRENT_SOURCE_DIR}//README.md
		$<TARGET_FILE_DIR:LabRecorderCLI>)
endif(BUILD_GUI)

if(Qt6_FOUND AND BUILD_GUI)
	set_target_properties(${PROJECT_NAME} PROPERTIES
		QT_ANDROID_EXTRA_LIBS "${CMAKE_CURRENT_BINARY_DIR}/liblsl_bin/liblsl.so")
	qt_finalize_executable(${PROJECT_NAME})
endif(Qt6_FOUND AND BUILD_GUI)

set(CPACK_DEBIAN_LABRECORDER_PACKAGE_SECTION "science" CACHE INTERNAL "")


if((DEFINED LSLGenerateCPackConfig))
	LSLGenerateCPackConfig()
endif((DEFINED LSLGenerateCPackConfig))


if(APPLE AND NOT DEFINED ENV{GITHUB_ACTIONS})
    # Qt6 QtNetwork depends on libbrotidec which depends on libbroticommon but whose search path uses @loader_path.
    #  Unfortunately, macdeployqt does not seem to traverse @loader_path dependencies.
    #  So we are forced to call `fixup_bundle`. For now, we only do this if homebrew is present
    #  because that seems to be where the bad dependency is coming from.
    # Note that fixup_bundle also destroys the codesigning so we have to redo that.
  	# TODO: Checkout supercollider apple-specific stuff, e.g.: https://github.com/supercollider/supercollider/blob/develop/CMakeLists.txt#L260-L262

    # Detect Apple Silicon
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    # Check for Homebrew
    execute_process(
        COMMAND brew --prefix
        RESULT_VARIABLE BREW_LIB
        OUTPUT_VARIABLE BREW_PREFIX
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    if (BREW_LIB EQUAL 0 AND EXISTS "${BREW_PREFIX}")
        install(CODE
            "
                include(BundleUtilities)
                fixup_bundle(\"${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${PROJECT_NAME}.app\" \"\" \"${BREW_PREFIX}/lib\")
                
                # Fix Qt plugin references specifically for Apple Silicon
                if(\"${ARCH}\" STREQUAL \"arm64\")
                    execute_process(COMMAND install_name_tool -change @rpath/QtGui.framework/Versions/A/QtGui @executable_path/../Frameworks/QtGui
                        \"${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${PROJECT_NAME}.app/Contents/PlugIns/platforms/libqcocoa.dylib\")
                endif()
                
                # Re-sign with the same approach the project already uses
				execute_process(COMMAND codesign --remove-signature \"${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${PROJECT_NAME}.app\")
				execute_process(COMMAND find \"${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${PROJECT_NAME}.app/Contents/Frameworks\" -type f -exec codesign --force --sign - {} \\; 2>/dev/null || true)
				execute_process(COMMAND find \"${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${PROJECT_NAME}.app/Contents/PlugIns\" -type f -exec codesign --force --sign - {} \\; 2>/dev/null || true)
				execute_process(COMMAND codesign --force --deep --sign - \"${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${PROJECT_NAME}.app\")            "
        )
    endif()
endif(APPLE AND NOT DEFINED ENV{GITHUB_ACTIONS})

# Linux desktop integration (GUI)
if(UNIX AND NOT APPLE AND BUILD_GUI)
	# Install a desktop entry and icon for desktop environments
	install(FILES res/labrecorder.desktop DESTINATION share/applications)
	install(FILES res/icon.png DESTINATION share/icons/hicolor/256x256/apps RENAME labrecorder.png)
endif()


# CPack configuration
if(WIN32)
    set(CPACK_GENERATOR "ZIP;NSIS")
elseif(APPLE)
    set(CPACK_GENERATOR "DragNDrop")
elseif(UNIX)
    set(CPACK_GENERATOR "DEB;TGZ")
	
endif()

set(CPACK_PACKAGE_NAME "LabRecorder")
set(CPACK_PACKAGE_VENDOR "PhoHale")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "LSL stream recorder")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_CONTACT "Pho Hale")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "LabRecorder")
set(CPACK_PACKAGE_CONTACT "phohale@gmail.com")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Pho Hale")

# This MUST come after all CPACK_* variables are set
include(CPack)