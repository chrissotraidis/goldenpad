cmake_minimum_required(VERSION 3.28)

project(GoldenPad LANGUAGES Swift)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
    message(FATAL_ERROR "GoldenPad currently configures only for iOS/iPadOS. See docs/BUILDING.md.")
endif()

add_executable(GoldenPad MACOSX_BUNDLE
    Assets.xcassets
    Sources/GoldenPadApp.swift
    Sources/InputSystem.swift
    Sources/MetalCanvas.swift
    Sources/PlatformServices.swift
    Sources/ROMValidator.swift
    Sources/TouchControlsView.swift
    Sources/TouchLayout.swift
)

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
    "-framework AVFAudio"
    "-framework CoreMotion"
    "-framework GameController"
    "-framework UniformTypeIdentifiers"
    "-framework CryptoKit"
)
