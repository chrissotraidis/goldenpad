cmake_minimum_required(VERSION 3.28)
project(GoldenPadGameModule LANGUAGES C CXX)
if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS" OR NOT CMAKE_OSX_ARCHITECTURES STREQUAL "arm64")
    message(FATAL_ERROR "Use PadMint's arm64 iOS module toolchain")
endif()
get_filename_component(GOLDENPAD_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(GOLDENPAD_GENERATED "" CACHE PATH "Verified private output from build-game-module.py")
find_package(Python3 REQUIRED COMPONENTS Interpreter)
execute_process(COMMAND "${Python3_EXECUTABLE}" "${GOLDENPAD_ROOT}/scripts/check-module-inputs.py" "${GOLDENPAD_GENERATED}"
    COMMAND_ERROR_IS_FATAL ANY)
include("${GOLDENPAD_ROOT}/cmake/ModuleIdentity.cmake")
goldenpad_module_identity("${GOLDENPAD_ROOT}" identity)
set(runtime "${GOLDENPAD_ROOT}/vendor/goldeneye/lib/N64ModernRuntime")
set(source "${GOLDENPAD_GENERATED}")
file(GLOB generated CONFIGURE_DEPENDS "${source}/RecompiledFuncs/*.c")
add_library(GoldenPadGame SHARED ${generated}
    "${source}/RecompiledFuncs/lookup.cpp" "${source}/rsp/aspMain.cpp"
    "${source}/RecompiledPatches/patches.c" "${source}/RecompiledPatches/patches_bin.c"
    "${source}/src/main/register_patches.cpp" "${source}/private/goldenpad_conversion_patch.c"
    "${GOLDENPAD_ROOT}/Support/RecompPrototype/recomp_register_overlays.cpp"
    "${GOLDENPAD_ROOT}/Support/RecompPrototype/game_module_entry.cpp")
set_target_properties(GoldenPadGame PROPERTIES C_STANDARD 11 CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON
    CXX_SCAN_FOR_MODULES OFF C_VISIBILITY_PRESET hidden CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON PREFIX "" OUTPUT_NAME "GoldenPadGame")
target_include_directories(GoldenPadGame PRIVATE "${GOLDENPAD_ROOT}/Support/RecompPrototype"
    "${source}/RecompiledFuncs" "${source}/RecompiledPatches" "${source}/include" "${source}/private"
    "${runtime}/N64Recomp/include" "${runtime}/librecomp/include" "${runtime}/ultramodern/include"
    "${runtime}/thirdparty" "${runtime}/thirdparty/sse2neon")
target_compile_definitions(GoldenPadGame PRIVATE "GOLDENPAD_MODULE_ID=\"${identity}\"")
target_compile_options(GoldenPadGame PRIVATE -fno-strict-aliasing -Wno-implicit-function-declaration
    -Wno-unused-variable -Wno-unused-but-set-variable "-ffile-prefix-map=${GOLDENPAD_ROOT}=.")
# Exactly as in the static route: strong translated patches replace weak base
# functions regardless of object order. Hidden symbols prevent app interposition.
set_source_files_properties("${source}/RecompiledPatches/patches.c" PROPERTIES
    COMPILE_OPTIONS "-include;${GOLDENPAD_ROOT}/Support/RecompPrototype/recomp_patch_attributes.h;-include;${source}/RecompiledFuncs/funcs.h")
target_link_options(GoldenPadGame PRIVATE "LINKER:-undefined,dynamic_lookup")
