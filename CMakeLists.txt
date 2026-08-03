cmake_minimum_required(VERSION 3.28)

project(GoldenPad LANGUAGES Swift C CXX OBJCXX)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
    message(FATAL_ERROR "GoldenPad currently configures only for iOS/iPadOS. See docs/BUILDING.md.")
endif()

set(CMAKE_OSX_DEPLOYMENT_TARGET "17.0" CACHE STRING "Minimum iOS/iPadOS version")

set(GOLDENPAD_RT64_ARCHIVE_DIR "" CACHE PATH "Directory containing the four RT64 mobile archives")
set(GOLDENPAD_RT64_SOURCE_DIR "" CACHE PATH "Pinned RT64 source checkout used for Plume headers")
set(GOLDENPAD_MGB64_SOURCE_DIR "" CACHE PATH "Pinned MGB64 checkout used for the native game core")

set(goldenpad_rt64_bridge Support/RT64/rt64_bridge_stub.cpp)
if(GOLDENPAD_RT64_ARCHIVE_DIR)
    if(NOT GOLDENPAD_RT64_SOURCE_DIR)
        message(FATAL_ERROR "GOLDENPAD_RT64_SOURCE_DIR is required when linking RT64")
    endif()

    set(goldenpad_rt64_bridge Support/RT64/rt64_metal_bridge.cpp)
    set(goldenpad_rt64_archives
        "${GOLDENPAD_RT64_ARCHIVE_DIR}/rt64.a"
        "${GOLDENPAD_RT64_ARCHIVE_DIR}/libplume.a"
        "${GOLDENPAD_RT64_ARCHIVE_DIR}/libre-spirv.a"
        "${GOLDENPAD_RT64_ARCHIVE_DIR}/libzstd.a"
    )
    foreach(archive IN LISTS goldenpad_rt64_archives)
        if(NOT EXISTS "${archive}")
            message(FATAL_ERROR "Missing RT64 archive: ${archive}")
        endif()
    endforeach()
endif()

add_executable(GoldenPad MACOSX_BUNDLE
    Assets.xcassets
    Sources/AppleRenderSurface.swift
    Sources/GoldenPadApp.swift
    Sources/InputSystem.swift
    Sources/MetalCanvas.swift
    Sources/PlatformServices.swift
    Sources/ROMValidator.swift
    Sources/TouchControlsView.swift
    Sources/TouchLayout.swift
    Support/MGB64/mgb64_core_bridge.c
    ${goldenpad_rt64_bridge}
)

include(Support/MGB64/MGB64Core.cmake)

set_target_properties(GoldenPad PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_NAME "GoldenPad"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.chrissotraidis.goldenpad"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "0.1.0"
    MACOSX_BUNDLE_BUNDLE_VERSION "1"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Config/Info.plist.in"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
    XCODE_ATTRIBUTE_GENERATE_INFOPLIST_FILE "NO"
    XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "17.0"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.chrissotraidis.goldenpad"
    XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS "iphoneos iphonesimulator"
    XCODE_ATTRIBUTE_SUPPORTS_MACCATALYST "NO"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
    XCODE_ATTRIBUTE_SWIFT_VERSION "5.0"
)

set_source_files_properties(Assets.xcassets PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

target_link_libraries(GoldenPad PRIVATE
    "-framework SwiftUI"
    "-framework Metal"
    "-framework MetalKit"
    "-framework QuartzCore"
    "-framework AVFAudio"
    "-framework CoreMotion"
    "-framework GameController"
    "-framework UniformTypeIdentifiers"
    "-framework CryptoKit"
)

if(GOLDENPAD_RT64_ARCHIVE_DIR)
    target_include_directories(GoldenPad PRIVATE
        "${GOLDENPAD_RT64_SOURCE_DIR}/src/contrib/plume"
    )
    foreach(archive IN LISTS goldenpad_rt64_archives)
        target_link_options(GoldenPad PRIVATE "LINKER:-force_load,${archive}")
    endforeach()
endif()
