#include "game_module.h"
#include "goldenpad_conversion_patch.h"

extern "C" void recomp_entrypoint(uint8_t*, recomp_context*);
gpr get_entrypoint_address();
extern RspUcodeFunc aspMain;
namespace zelda64 { void register_overlays(); void register_patches(); }

extern "C" __attribute__((visibility("default")))
const GoldenPadGameModule* goldenpad_get_game_module() {
    static const GoldenPadGameModule module{
        goldenpad_game_module_version, sizeof(GoldenPadGameModule), GOLDENPAD_MODULE_ID,
        get_entrypoint_address, recomp_entrypoint, aspMain,
        zelda64::register_overlays, zelda64::register_patches,
        reinterpret_cast<const uint8_t*>(goldenpad_conversion_patch), sizeof(goldenpad_conversion_patch)
    };
    return &module;
}
