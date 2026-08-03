#include <stdint.h>
#include <stddef.h>

#ifdef GOLDENPAD_MGB64_CORE
void randomSetSeed(uint64_t seed);
uint32_t randomGetNext(void);
void guNormalize(float *x, float *y, float *z);
int16_t sins(uint16_t angle);
int16_t coss(uint16_t angle);
int aimBoneArg0Proceeds(int arg0, int legacy);
float watchInvPerspAspect(int legacy);
extern uint32_t _rarewarelogoSegmentRomStart;
int goldenpad_mgb64_mobile_config_probe(void);
int goldenpad_mgb64_mobile_legacy_data_probe(void);
int goldenpad_mgb64_mobile_host_probe(void);
int goldenpad_mgb64_mobile_os_probe(void);
int osEepromLongWrite(void *queue, uint8_t address, uint8_t *buffer, int32_t bytes);
int platformOverlayWantsInput(void);
void modelConvertFreeAll(void);
void platformApplyRadialDeadzone(float *x, float *y, float deadzone, int radial);
uint32_t setupPnamesTableOffset(const uint8_t *base, int index, int legacy);
uint16_t portWeaponEquipCue(int weapon_id);
const char *pcStageSlugForLevelId(int32_t level_id);

#ifndef GOLDENPAD_MGB64_COMMIT
#define GOLDENPAD_MGB64_COMMIT "unknown"
#endif

__attribute__((weak))
void pcRamromObserveUpcomingBlockSeedWindow(const char *source) {
    (void)source;
}

const char *goldenpad_mgb64_core_identity(void) {
    return "MGB64 game core " GOLDENPAD_MGB64_COMMIT;
}

uint32_t goldenpad_mgb64_core_probe(void) {
    float x = 3.0f;
    float y = 4.0f;
    float z = 0.0f;
    guNormalize(&x, &y, &z);
    if (x < 0.599f || x > 0.601f || y < 0.799f || y > 0.801f || z != 0.0f) {
        return 0;
    }
    if (sins(0) != 0 || coss(0) != 32767 ||
        aimBoneArg0Proceeds(0, 0) != 1 ||
        watchInvPerspAspect(0) != 4.0f / 3.0f ||
        _rarewarelogoSegmentRomStart != UINT32_C(0x0029e560) ||
        !goldenpad_mgb64_mobile_config_probe() ||
        !goldenpad_mgb64_mobile_legacy_data_probe() ||
        !goldenpad_mgb64_mobile_host_probe() ||
        !goldenpad_mgb64_mobile_os_probe() ||
        osEepromLongWrite(NULL, 0, NULL, 0) != 0 ||
        platformOverlayWantsInput() != 0) {
        return 0;
    }
    x = 0.0f;
    y = 0.0f;
    platformApplyRadialDeadzone(&x, &y, 0.15f, 1);
    modelConvertFreeAll();
    if (x != 0.0f || y != 0.0f ||
        setupPnamesTableOffset(NULL, 0, 0) != 0 ||
        portWeaponEquipCue(4) != 232 || pcStageSlugForLevelId(-1) != NULL) {
        return 0;
    }
    randomSetSeed(UINT64_C(0x47504d47423634));
    return randomGetNext();
}
#else
const char *goldenpad_mgb64_core_identity(void) {
    return "MGB64 game core not linked";
}

uint32_t goldenpad_mgb64_core_probe(void) {
    return 0;
}
#endif
