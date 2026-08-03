#include <stdint.h>

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
        !goldenpad_mgb64_mobile_config_probe()) {
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
