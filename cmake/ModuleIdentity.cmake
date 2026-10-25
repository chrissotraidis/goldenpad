# Recompute the ABI contract whenever any included source/configuration changes.
function(goldenpad_module_identity root output)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    file(GLOB_RECURSE bridge_inputs CONFIGURE_DEPENDS "${root}/Support/RecompPrototype/*.h" "${root}/Support/RecompPrototype/*.hpp"
        "${root}/Support/RecompPrototype/*.cpp" "${root}/Support/RecompPrototype/*.mm")
    file(GLOB contract_patches CONFIGURE_DEPENDS "${root}/patches/*.patch")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${bridge_inputs} ${contract_patches}
        "${root}/sources.lock.json" "${root}/CMakeLists.txt" "${root}/cmake/game-module/CMakeLists.txt"
        "${root}/cmake/host-tools/CMakeLists.txt"
        "${root}/cmake/ModuleIdentity.cmake" "${root}/scripts/module_build.py" "${root}/scripts/module-identity.py"
        "${root}/scripts/build-game-module.py")
    execute_process(COMMAND "${Python3_EXECUTABLE}" "${root}/scripts/module-identity.py"
        OUTPUT_VARIABLE identity OUTPUT_STRIP_TRAILING_WHITESPACE COMMAND_ERROR_IS_FATAL ANY)
    set(${output} "${identity}" PARENT_SCOPE)
endfunction()
