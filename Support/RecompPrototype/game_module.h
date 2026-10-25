#pragma once
#include <cstddef>
#include <cstdint>
#include "recomp.h"
#include "librecomp/rsp.hpp"

// The app owns the runtime and its thread-local state. This table exposes only
// private translated code and ROM-conversion data; never publish that module.
struct GoldenPadGameModule {
    uint32_t version;
    uint32_t size;
    const char* identity;
    gpr (*entrypoint_address)();
    void (*entrypoint)(uint8_t*, recomp_context*);
    RspUcodeFunc* audio;
    void (*register_overlays)();
    void (*register_patches)();
    const uint8_t* conversion_patch;
    size_t conversion_patch_size;
};
constexpr uint32_t goldenpad_game_module_version = 1;
using GoldenPadGetModule = const GoldenPadGameModule*();

extern "C" const char* goldenpad_load_game_module(const char* path);
extern "C" bool goldenpad_game_module_ready();
extern "C" bool goldenpad_module_conversion_patch(const uint8_t** bytes, size_t* size);
