#include "game_module.h"
#include <cstdio>
#include <cstring>
#include <dlfcn.h>

namespace {
const GoldenPadGameModule* module = nullptr;
void* library = nullptr;
}

extern "C" const char* goldenpad_load_game_module(const char* path) {
    if (module) return nullptr;
    if (!path || !*path) return "This copy is missing its game module. Build it with PadMint again.";
    void* candidate = dlopen(path, RTLD_NOW | RTLD_LOCAL);
    if (!candidate) {
        std::fprintf(stderr, "[game module] %s\n", dlerror());
        return "The game module could not load. Build this copy with PadMint and install it again.";
    }
    auto getter = reinterpret_cast<GoldenPadGetModule*>(dlsym(candidate, "goldenpad_get_game_module"));
    const auto* value = getter ? getter() : nullptr;
    const bool valid = value && value->version == goldenpad_game_module_version &&
        value->size == sizeof(GoldenPadGameModule) && value->identity &&
        std::strcmp(value->identity, GOLDENPAD_MODULE_ID) == 0 &&
        value->entrypoint_address && value->entrypoint && value->audio &&
        value->register_overlays && value->register_patches && value->conversion_patch &&
        value->conversion_patch_size >= 13 && value->conversion_patch_size <= 1024 * 1024;
    if (!valid) {
        dlclose(candidate);
        return "The game module belongs to a different app build. Build this copy with PadMint again.";
    }
    library = candidate; // Keep translated functions and overlay pointers alive.
    module = value;
    return nullptr;
}

extern "C" bool goldenpad_game_module_ready() { return module != nullptr; }
extern "C" bool goldenpad_module_conversion_patch(const uint8_t** bytes, size_t* size) {
    if (!module || !bytes || !size) return false;
    *bytes = module->conversion_patch;
    *size = module->conversion_patch_size;
    return true;
}
gpr get_entrypoint_address() { return module ? module->entrypoint_address() : 0; }
extern "C" void recomp_entrypoint(uint8_t* rdram, recomp_context* ctx) { module->entrypoint(rdram, ctx); }
RspExitReason aspMain(uint8_t* rdram, uint32_t address) { return module->audio(rdram, address); }
namespace zelda64 {
void register_overlays() { module->register_overlays(); }
void register_patches() { module->register_patches(); }
}
