#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define GOLDENPAD_RETAIL_ROM_SIZE 0x00c00000u

uint8_t *g_romData = NULL;
uint32_t g_romSize = 0;

#ifdef GOLDENPAD_MGB64_CORE
typedef struct fileentry {
    int32_t index;
    const char *filename;
    uint8_t *hw_address;
} fileentry_t;

extern fileentry_t file_resource_table[];
extern int32_t file_entry_max;
void platformPatchFileTable(uint8_t *rom_data);

static void goldenpad_clear_file_table(void) {
    for (int32_t index = 1; index < file_entry_max; ++index) {
        file_resource_table[index].hw_address = NULL;
    }
}
#endif

static void goldenpad_clear_owned_rom(void) {
#ifdef GOLDENPAD_MGB64_CORE
    goldenpad_clear_file_table();
#endif
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

int goldenpad_mgb64_file_table_ready(void) {
#ifdef GOLDENPAD_MGB64_CORE
    return g_romData != NULL && g_romSize == GOLDENPAD_RETAIL_ROM_SIZE &&
        file_entry_max > 14 &&
        file_resource_table[1].hw_address == g_romData + 0x00438660u &&
        file_resource_table[14].hw_address == g_romData + 0x005ffc50u;
#else
    return 0;
#endif
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
    platformPatchFileTable(g_romData);
    if (!goldenpad_mgb64_file_table_ready()) {
        goldenpad_clear_owned_rom();
        return 0;
    }
    return 1;
#else
    (void)source;
    (void)size;
    return 0;
#endif
}
