#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define GOLDENPAD_RETAIL_ROM_SIZE 0x00c00000u

uint8_t *g_romData = NULL;
uint32_t g_romSize = 0;

static void goldenpad_clear_owned_rom(void) {
    if (g_romData != NULL) {
        volatile uint8_t *bytes = g_romData;
        for (uint32_t index = 0; index < g_romSize; ++index) {
            bytes[index] = 0;
        }
        free(g_romData);
    }
    g_romData = NULL;
    g_romSize = 0;
}

int goldenpad_mgb64_core_accepts_rom(void) {
#ifdef GOLDENPAD_MGB64_CORE
    return 1;
#else
    return 0;
#endif
}

void goldenpad_mgb64_clear_rom(void) {
    goldenpad_clear_owned_rom();
}

int goldenpad_mgb64_install_validated_rom(const uint8_t *source, uint32_t size) {
#ifdef GOLDENPAD_MGB64_CORE
    if (source == NULL || size != GOLDENPAD_RETAIL_ROM_SIZE ||
        source[0] != 0x80 || source[1] != 0x37 ||
        source[2] != 0x12 || source[3] != 0x40) {
        return 0;
    }

    int has_title = 0;
    for (uint32_t index = 0x20; index + 9 <= 0x34; ++index) {
        if (memcmp(source + index, "GOLDENEYE", 9) == 0) {
            has_title = 1;
            break;
        }
    }
    if (!has_title) {
        return 0;
    }

    uint8_t *copy = malloc(size);
    if (copy == NULL) {
        return 0;
    }
    memcpy(copy, source, size);
    goldenpad_clear_owned_rom();
    g_romData = copy;
    g_romSize = size;
    return 1;
#else
    (void)source;
    (void)size;
    return 0;
#endif
}
