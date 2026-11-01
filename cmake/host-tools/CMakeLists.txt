cmake_minimum_required(VERSION 3.28)
project(GoldenPadHostTools LANGUAGES C CXX)
get_filename_component(GOLDENPAD_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
set(source "${GOLDENPAD_ROOT}/vendor/goldeneye/n64recomp-src")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
add_subdirectory("${source}" upstream)

# Only the output order changes: unordered-set iteration differs between MSVC
# and libc++. Keep the immutable source checkout clean; compile a build copy.
set(rsp_source "${source}/RSPRecomp/src/rsp_recomp.cpp")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${rsp_source}")
file(READ "${rsp_source}" rsp)
foreach(targets branch_targets.indirect_targets resume_targets.delay_targets resume_targets.non_delay_targets)
    set(needle "${targets}) {")
    string(FIND "${rsp}" "${needle}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Pinned RSPRecomp emission loop changed; review deterministic generation")
    endif()
    string(REPLACE "${needle}" "std::set<uint32_t>(${targets}.begin(), ${targets}.end())) {" rsp "${rsp}")
endforeach()
string(REPLACE "#include <unordered_set>" "#include <unordered_set>\n#include <set>" rsp "${rsp}")
file(CONFIGURE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/rsp_recomp.cpp" CONTENT "${rsp}" @ONLY)
set_property(TARGET RSPRecomp PROPERTY SOURCES "${CMAKE_CURRENT_BINARY_DIR}/rsp_recomp.cpp")

# Match the base-game generator's canonical names when emitting reference calls
# from patches. The pinned emitter otherwise calls host sprintf with the N64
# callback signature. Change the emitter, never generated strings or comments.
set(c_source "${source}/src/cgenerator.cpp")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${c_source}")
file(READ "${c_source}" generator)
set(needle [=[fmt::print(output_file, "{}(rdram, ctx);\n", sym.name);]=])
string(FIND "${generator}" "${needle}" position)
if(position EQUAL -1)
    message(FATAL_ERROR "Pinned reference-call emitter changed; review its canonical symbol names")
endif()
string(REPLACE "${needle}"
    [=[fmt::print(output_file, "{}(rdram, ctx);\n", N64Recomp::renamed_funcs.contains(sym.name) ? sym.name + "_recomp" : sym.name);]=]
    generator "${generator}")
file(CONFIGURE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/cgenerator.cpp" CONTENT "${generator}" @ONLY)
get_target_property(core_sources N64Recomp SOURCES)
list(REMOVE_ITEM core_sources "${c_source}")
set_property(TARGET N64Recomp PROPERTY SOURCES ${core_sources} "${CMAKE_CURRENT_BINARY_DIR}/cgenerator.cpp")
add_executable(GoldenPadGeneratorTest "${GOLDENPAD_ROOT}/Tests/module_generator_test.cpp")
target_link_libraries(GoldenPadGeneratorTest PRIVATE N64Recomp)
target_compile_features(GoldenPadGeneratorTest PRIVATE cxx_std_20)

# The generators consume UTF-8 TOML paths and use narrow filesystem APIs.
if(MSVC)
    foreach(target N64RecompCLI RSPRecomp)
        target_sources(${target} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/windows-utf8.manifest")
    endforeach()
endif()
