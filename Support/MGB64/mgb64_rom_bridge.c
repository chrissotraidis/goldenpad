#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdatomic.h>

#ifdef GOLDENPAD_MGB64_RENDERER
#include <pthread.h>
#include <stdio.h>
#endif

#define GOLDENPAD_RETAIL_ROM_SIZE 0x00c00000u

uint8_t *g_romData = NULL;
uint32_t g_romSize = 0;
static _Atomic int goldenpad_renderer_ready;
static _Atomic int goldenpad_game_state;

#ifdef GOLDENPAD_MGB64_CORE
typedef struct fileentry {
    int32_t index;
    const char *filename;
    uint8_t *hw_address;
} fileentry_t;

extern fileentry_t file_resource_table[];
extern int32_t file_entry_max;
void platformPatchFileTable(uint8_t *rom_data);
int goldenpad_mgb64_scheduler_initialize(void);

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

void goldenpad_mgb64_set_renderer_ready(int ready) {
    atomic_store(&goldenpad_renderer_ready, ready != 0);
}

int goldenpad_mgb64_game_state(void) {
    return atomic_load(&goldenpad_game_state);
}

void goldenpad_mgb64_clear_rom(void) {
    if (atomic_load(&goldenpad_game_state) != 0) {
        return;
    }
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

int goldenpad_mgb64_prepare_scheduler(void) {
#ifdef GOLDENPAD_MGB64_CORE
    static int scheduler_ready = 0;
    if (scheduler_ready) {
        return 1;
    }
    if (!goldenpad_mgb64_file_table_ready()) {
        return 0;
    }
    if (!goldenpad_mgb64_scheduler_initialize()) {
        return 0;
    }
    scheduler_ready = 1;
    return 1;
#else
    return 0;
#endif
}

int goldenpad_mgb64_install_validated_rom(const uint8_t *source, uint32_t size) {
#ifdef GOLDENPAD_MGB64_CORE
    if (atomic_load(&goldenpad_game_state) != 0 ||
        source == NULL || size != GOLDENPAD_RETAIL_ROM_SIZE ||
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

#if defined(GOLDENPAD_MGB64_CORE) && defined(GOLDENPAD_MGB64_RENDERER)
extern void bossEntry(void);
extern void portAudioInit(void);
extern void portWatchdogInit(void);

static void *goldenpad_mgb64_game_thread(void *unused) {
    (void)unused;
    pthread_setname_np("GoldenEye game");
    portAudioInit();
    portWatchdogInit();
    atomic_store(&goldenpad_game_state, 2);
    printf("[GoldenPad] Entering MGB64 bossEntry on background thread\n");
    bossEntry();
    atomic_store(&goldenpad_game_state, -1);
    return NULL;
}
#endif

int goldenpad_mgb64_start_game(void) {
#if defined(GOLDENPAD_MGB64_CORE) && defined(GOLDENPAD_MGB64_RENDERER)
    int expected = 0;
    pthread_t thread;

    if (!goldenpad_mgb64_file_table_ready() ||
        !atomic_load(&goldenpad_renderer_ready) ||
        !goldenpad_mgb64_prepare_scheduler() ||
        !atomic_compare_exchange_strong(&goldenpad_game_state, &expected, 1)) {
        return 0;
    }
    if (pthread_create(&thread, NULL, goldenpad_mgb64_game_thread, NULL) != 0) {
        atomic_store(&goldenpad_game_state, 0);
        return 0;
    }
    pthread_detach(thread);
    return 1;
#else
    return 0;
#endif
}
