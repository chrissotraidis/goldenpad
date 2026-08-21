cmake_minimum_required(VERSION 3.28)

project(GoldenPad LANGUAGES Swift C CXX OBJCXX)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
    message(FATAL_ERROR "GoldenPad currently configures only for iOS/iPadOS. See docs/BUILDING.md.")
endif()

set(CMAKE_OSX_DEPLOYMENT_TARGET "17.0" CACHE STRING "Minimum iOS/iPadOS version")

set(GOLDENPAD_BUNDLE_IDENTIFIER "com.chrissotraidis.goldenpad" CACHE STRING
    "Bundle identifier used by the iOS/iPadOS app")
set(GOLDENPAD_DEVELOPMENT_TEAM "" CACHE STRING
    "Apple development team ID; leave empty for reproducible unsigned builds")
set(GOLDENPAD_RT64_ARCHIVE_DIR "" CACHE PATH "Directory containing the four RT64 mobile archives")
set(GOLDENPAD_RT64_SOURCE_DIR "" CACHE PATH "Pinned RT64 source checkout used for Plume headers")
set(GOLDENPAD_MGB64_SOURCE_DIR "" CACHE PATH "Pinned MGB64 checkout used for the native game core")
option(GOLDENPAD_MGB64_RENDERER "Link the opt-in MGB64 Fast3D/Metal renderer probe" OFF)
option(GOLDENPAD_RECOMP_PROTOTYPE "Build the isolated RT64/N64Recomp prototype host" OFF)
set(GOLDENPAD_RECOMP_BUNDLE_IDENTIFIER "com.chrissotraidis.goldenpad.recomp-prototype" CACHE STRING
    "Bundle identifier used by the isolated recompilation prototype")
set(GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR "" CACHE PATH "Directory containing verified RT64 mobile archives for the prototype")
set(GOLDENPAD_RECOMP_RT64_SOURCE_DIR "" CACHE PATH "Pinned RT64 source checkout used for prototype headers")
set(GOLDENPAD_RECOMP_AOT_DIR "" CACHE PATH "Private directory containing generated GoldenEye AOT sources")
set(GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR "" CACHE PATH "Private pinned N64ModernRuntime source directory for the prototype")
set(GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR "" CACHE PATH "Private AOT-only N64ModernRuntime archive directory for the prototype")
set(GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR "" CACHE PATH "Pinned GoldenEye recompilation source used only by the prototype RT64 context")

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

if(GOLDENPAD_RECOMP_PROTOTYPE)
    set(goldenpad_recomp_code_signing_allowed NO)
    set(goldenpad_recomp_code_signing_required NO)
    if(GOLDENPAD_DEVELOPMENT_TEAM)
        set(goldenpad_recomp_code_signing_allowed YES)
        set(goldenpad_recomp_code_signing_required YES)
    endif()
    set(goldenpad_recomp_rt64_bridge Support/RecompPrototype/recomp_rt64_surface_stub.cpp)
    set(goldenpad_recomp_aot_sources)
    set(goldenpad_recomp_resources)
    set(goldenpad_recomp_runtime_archives)
    if(GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR)
        if(NOT GOLDENPAD_RECOMP_RT64_SOURCE_DIR)
            message(FATAL_ERROR "GOLDENPAD_RECOMP_RT64_SOURCE_DIR is required when linking prototype RT64")
        endif()
        set(goldenpad_recomp_rt64_bridge Support/RecompPrototype/recomp_rt64_surface_bridge.cpp)
        set(goldenpad_recomp_rt64_archives
            "${GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR}/rt64.a"
            "${GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR}/libplume.a"
            "${GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR}/libre-spirv.a"
            "${GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR}/libzstd.a"
        )
        foreach(archive IN LISTS goldenpad_recomp_rt64_archives)
            if(NOT EXISTS "${archive}")
                message(FATAL_ERROR "Missing prototype RT64 archive: ${archive}")
            endif()
        endforeach()
    endif()

    if(GOLDENPAD_RECOMP_AOT_DIR OR GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR OR GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR OR GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR)
        if(NOT GOLDENPAD_RECOMP_AOT_DIR OR NOT GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR OR NOT GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR OR NOT GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR)
            message(FATAL_ERROR "GOLDENPAD_RECOMP_AOT_DIR, GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR, GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR, and GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR must be set together")
        endif()
        if(NOT GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR)
            message(FATAL_ERROR "GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR is required for the AOT prototype")
        endif()

        file(GLOB goldenpad_recomp_aot_c CONFIGURE_DEPENDS
            "${GOLDENPAD_RECOMP_AOT_DIR}/RecompiledFuncs/*.c")
        set(goldenpad_recomp_patch_sources
            "${GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR}/RecompiledPatches/patches.c"
            "${GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR}/RecompiledPatches/patches_bin.c"
            "${GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR}/src/main/register_patches.cpp")
        foreach(patch_source IN LISTS goldenpad_recomp_patch_sources)
            if(NOT EXISTS "${patch_source}")
                message(FATAL_ERROR
                    "Missing upstream recomp patch output: ${patch_source}. Generate RecompiledPatches before configuring the AOT prototype.")
            endif()
        endforeach()
        set(goldenpad_recomp_render_context
            "${GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR}/src/main/rt64_render_context.cpp")
        file(READ "${goldenpad_recomp_render_context}" goldenpad_recomp_render_context_text)
        string(FIND "${goldenpad_recomp_render_context_text}"
            "GoldenPadRecompRT64" goldenpad_recomp_writable_rt64_path)
        if(goldenpad_recomp_writable_rt64_path EQUAL -1)
            message(FATAL_ERROR
                "GoldenEye64Recomp is missing patches/goldeneye64recomp-ios-prototype-render-trace.patch; a clean iOS install would crash while RT64 creates its data directory")
        endif()
        set(goldenpad_recomp_rom_patch
            "${GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR}/vanilla_to_tlbfree.gep1")
        if(NOT EXISTS "${goldenpad_recomp_rom_patch}")
            message(FATAL_ERROR
                "Missing pinned GoldenEye64Recomp GEP1 conversion patch: ${goldenpad_recomp_rom_patch}")
        endif()
        file(SHA256 "${goldenpad_recomp_rom_patch}" goldenpad_recomp_rom_patch_sha256)
        if(NOT goldenpad_recomp_rom_patch_sha256 STREQUAL
                "5a079d5b3750afcb027e46367e318b884eadabbd238a450a70f95e3976ded263")
            message(FATAL_ERROR
                "GoldenEye64Recomp GEP1 conversion patch does not match pinned revision a787fe0d95e8278fcba5ba2d768fa6a606e75f55")
        endif()
        set(goldenpad_recomp_resources "${goldenpad_recomp_rom_patch}")
        set(goldenpad_recomp_aot_sources
            ${goldenpad_recomp_patch_sources}
            ${goldenpad_recomp_aot_c}
            "${GOLDENPAD_RECOMP_AOT_DIR}/RecompiledFuncs/lookup.cpp"
            "${GOLDENPAD_RECOMP_AOT_DIR}/rsp/aspMain.cpp"
            Support/RecompPrototype/recomp_aot_link_bridge.cpp
            Support/RecompPrototype/recomp_game_start.cpp
            Support/RecompPrototype/recomp_rom_import.cpp
            Support/RecompPrototype/recomp_register_overlays.cpp
            Support/RecompPrototype/recomp_ultra_shims.cpp
            Support/RecompPrototype/recomp_ui_stub.cpp
            "${goldenpad_recomp_render_context}")
        set_source_files_properties(
            "${goldenpad_recomp_render_context}"
            PROPERTIES
            COMPILE_OPTIONS
            "-DSDL_PROTOTYPES_ONLY=1;-include;${CMAKE_CURRENT_SOURCE_DIR}/Support/RecompPrototype/rt64_namespace_compat.hpp")
        set(goldenpad_recomp_runtime_archives
            "${GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR}/ultramodern/libultramodern.a"
            "${GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR}/librecomp/liblibrecomp.a"
            "${GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR}/librecomp/N64Recomp/libN64Recomp.a"
            "${GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR}/librecomp/N64Recomp/librabbitizer.a"
            "${GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR}/librecomp/N64Recomp/lib/fmt/libfmt.a"
            "${GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR}/librecomp/N64Recomp/libSymbolLists.a")
        foreach(archive IN LISTS goldenpad_recomp_runtime_archives)
            if(NOT EXISTS "${archive}")
                message(FATAL_ERROR "Missing AOT runtime archive: ${archive}")
            endif()
        endforeach()
    endif()

    add_executable(GoldenPadRecompPrototype MACOSX_BUNDLE
        Assets.xcassets
        Config/ThirdPartyNotices.txt
        Sources/RecompPrototypeApp.swift
        Sources/RecompPrototypeAudio.swift
        Sources/RecompPrototypeInput.swift
        Sources/RecompPrototypeMetalCanvas.swift
        Sources/RecompPrototypeROMStore.swift
        Sources/RecompPrototypeTouchLayout.swift
        ${goldenpad_recomp_resources}
        ${goldenpad_recomp_rt64_bridge}
        ${goldenpad_recomp_aot_sources}
    )
    set_target_properties(GoldenPadRecompPrototype PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "GoldenPad"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${GOLDENPAD_RECOMP_BUNDLE_IDENTIFIER}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "0.1.0"
        MACOSX_BUNDLE_BUNDLE_VERSION "2"
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Config/RecompPrototypeInfo.plist.in"
        XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "${goldenpad_recomp_code_signing_allowed}"
        XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "${goldenpad_recomp_code_signing_required}"
        XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic"
        XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${GOLDENPAD_DEVELOPMENT_TEAM}"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        XCODE_ATTRIBUTE_GENERATE_INFOPLIST_FILE "NO"
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "17.0"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${GOLDENPAD_RECOMP_BUNDLE_IDENTIFIER}"
        XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS "iphoneos iphonesimulator"
        XCODE_ATTRIBUTE_SUPPORTS_MACCATALYST "NO"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        XCODE_ATTRIBUTE_SWIFT_VERSION "5.0"
        XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++20"
        CXX_STANDARD 20
        CXX_STANDARD_REQUIRED TRUE
    )
    set_source_files_properties(
        Assets.xcassets
        Config/ThirdPartyNotices.txt
        ${goldenpad_recomp_resources}
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    target_link_libraries(GoldenPadRecompPrototype PRIVATE
        "-framework SwiftUI"
        "-framework AVFAudio"
        "-framework Metal"
        "-framework MetalKit"
        "-framework QuartzCore"
        "-framework UIKit"
        "-framework UniformTypeIdentifiers"
    )
    if(GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR)
        target_include_directories(GoldenPadRecompPrototype PRIVATE
            "${GOLDENPAD_RECOMP_RT64_SOURCE_DIR}/src/contrib/plume")
        foreach(archive IN LISTS goldenpad_recomp_rt64_archives)
            target_link_options(GoldenPadRecompPrototype PRIVATE "LINKER:-force_load,${archive}")
        endforeach()
    endif()
    if(GOLDENPAD_RECOMP_AOT_DIR)
        target_compile_definitions(GoldenPadRecompPrototype PRIVATE
            GOLDENPAD_RECOMP_AOT_LINKED=1
            RT64_EMBEDDED_APPLE=1)
        target_include_directories(GoldenPadRecompPrototype PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}/Support/RecompPrototype"
            "${GOLDENPAD_RECOMP_AOT_DIR}/RecompiledFuncs"
            "${GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR}/RecompiledPatches"
            "${GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR}/include"
            "${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR}/librecomp/include"
            "${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR}/ultramodern/include"
            "${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR}/N64Recomp/include"
            "${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR}/N64Recomp/lib/rabbitizer/include"
            "${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR}/N64Recomp/lib/rabbitizer/cplusplus/include"
            "${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR}/thirdparty"
            "${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR}/thirdparty/concurrentqueue"
            "${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR}/thirdparty/sse2neon"
            "${GOLDENPAD_RECOMP_RT64_SOURCE_DIR}/src"
            "${GOLDENPAD_RECOMP_RT64_SOURCE_DIR}/src/rhi"
            "${GOLDENPAD_RECOMP_RT64_SOURCE_DIR}/src/contrib"
            "${GOLDENPAD_RECOMP_RT64_SOURCE_DIR}/src/contrib/hlslpp/include"
            "${GOLDENPAD_RECOMP_RT64_SOURCE_DIR}/src/contrib/mupen64plus-win32-deps/SDL2-2.26.3/include")
        set_source_files_properties(${goldenpad_recomp_aot_c} PROPERTIES
            COMPILE_OPTIONS "-Wno-implicit-function-declaration")
        set_source_files_properties(
            "${GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR}/RecompiledPatches/patches.c"
            PROPERTIES COMPILE_OPTIONS "-fno-strict-aliasing;-Wno-implicit-function-declaration")
        foreach(archive IN LISTS goldenpad_recomp_runtime_archives)
            target_link_options(GoldenPadRecompPrototype PRIVATE "LINKER:-force_load,${archive}")
        endforeach()
    endif()
endif()

add_executable(GoldenPad MACOSX_BUNDLE
    Assets.xcassets
    Config/ThirdPartyNotices.txt
    Sources/AppleRenderSurface.swift
    Sources/GoldenPadApp.swift
    Sources/InputSystem.swift
    Sources/MetalCanvas.swift
    Sources/PlatformServices.swift
    Sources/ROMValidator.swift
    Sources/TouchControlsView.swift
    Sources/TouchLayout.swift
    Support/MGB64/mgb64_core_bridge.c
    Support/MGB64/mgb64_rom_bridge.c
    Support/MGB64/mgb64_renderer_bridge.c
    Support/MGB64/mgb64_metal_surface_bridge.mm
    ${goldenpad_rt64_bridge}
)

set(goldenpad_code_signing_allowed "NO")
set(goldenpad_code_signing_required "NO")
if(GOLDENPAD_DEVELOPMENT_TEAM)
    set(goldenpad_code_signing_allowed "YES")
    set(goldenpad_code_signing_required "YES")
endif()

set_source_files_properties(
    Support/MGB64/mgb64_metal_surface_bridge.mm
    PROPERTIES COMPILE_OPTIONS "-fobjc-arc")

include(Support/MGB64/MGB64Core.cmake)

set_target_properties(GoldenPad PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_NAME "GoldenPad Legacy"
    MACOSX_BUNDLE_GUI_IDENTIFIER "${GOLDENPAD_BUNDLE_IDENTIFIER}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "0.1.0"
    MACOSX_BUNDLE_BUNDLE_VERSION "1"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Config/Info.plist.in"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "${goldenpad_code_signing_allowed}"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "${goldenpad_code_signing_required}"
    XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic"
    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${GOLDENPAD_DEVELOPMENT_TEAM}"
    XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
    XCODE_ATTRIBUTE_GENERATE_INFOPLIST_FILE "NO"
    XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "17.0"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${GOLDENPAD_BUNDLE_IDENTIFIER}"
    XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS "iphoneos iphonesimulator"
    XCODE_ATTRIBUTE_SUPPORTS_MACCATALYST "NO"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
    XCODE_ATTRIBUTE_SWIFT_VERSION "5.0"
)

set_source_files_properties(
    Assets.xcassets
    Config/ThirdPartyNotices.txt
    PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

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
