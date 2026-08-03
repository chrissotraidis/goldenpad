#include <stdint.h>

#ifdef GOLDENPAD_MGB64_CORE
void randomSetSeed(uint64_t seed);
uint32_t randomGetNext(void);

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
