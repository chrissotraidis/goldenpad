#ifndef GOLDENPAD_MGB64_CORE_SDL_SHIM_H
#define GOLDENPAD_MGB64_CORE_SDL_SHIM_H

#include <stdint.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>

/* The decompiled core has one optional desktop level-selector dependency on
 * SDL keyboard state. GoldenPad supplies gameplay input through its normalized
 * host API, so the core-only archive keeps that selector inert. This header is
 * intentionally visible only to the core target; the future renderer/platform
 * target will use the real mobile platform adapter. */
enum {
    SDL_INIT_AUDIO = 0x00000010,
    SDL_SCANCODE_W = 26,
    SDL_SCANCODE_S = 22,
    SDL_SCANCODE_RETURN = 40,
    SDL_SCANCODE_ESCAPE = 41,
    SDL_SCANCODE_SPACE = 44,
    SDL_SCANCODE_UP = 82,
    SDL_SCANCODE_DOWN = 81,
    SDL_NUM_SCANCODES = 512
};

typedef uint32_t SDL_AudioDeviceID;
typedef pthread_mutex_t SDL_mutex;
typedef struct SDL_sem SDL_sem;

typedef struct SDL_AudioSpec {
    int freq;
    uint16_t format;
    uint8_t channels;
    uint8_t silence;
    uint16_t samples;
    uint16_t padding;
    uint32_t size;
    void (*callback)(void *userdata, uint8_t *stream, int len);
    void *userdata;
} SDL_AudioSpec;

#define AUDIO_S16SYS 0x8010

static inline int SDL_InitSubSystem(uint32_t flags) {
    (void)flags;
    return 0;
}

static inline const char *SDL_GetError(void) { return "mobile host"; }

static inline SDL_mutex *SDL_CreateMutex(void) {
    SDL_mutex *mutex = (SDL_mutex *)malloc(sizeof(*mutex));
    if (mutex != NULL && pthread_mutex_init(mutex, NULL) != 0) {
        free(mutex);
        return NULL;
    }
    return mutex;
}

static inline void SDL_DestroyMutex(SDL_mutex *mutex) {
    if (mutex != NULL) {
        pthread_mutex_destroy(mutex);
        free(mutex);
    }
}

static inline int SDL_LockMutex(SDL_mutex *mutex) {
    return mutex == NULL ? -1 : pthread_mutex_lock(mutex);
}

static inline int SDL_UnlockMutex(SDL_mutex *mutex) {
    return mutex == NULL ? -1 : pthread_mutex_unlock(mutex);
}

static inline SDL_AudioDeviceID SDL_OpenAudioDevice(
    const char *device, int capture, const SDL_AudioSpec *want,
    SDL_AudioSpec *have, int allowed_changes) {
    (void)device;
    (void)capture;
    (void)allowed_changes;
    if (want == NULL) {
        return 0;
    }
    if (have != NULL) {
        *have = *want;
    }
    return 1;
}

static inline void SDL_CloseAudioDevice(SDL_AudioDeviceID device) {
    (void)device;
}

static inline void SDL_PauseAudioDevice(SDL_AudioDeviceID device, int pause) {
    (void)device;
    (void)pause;
}

static inline int SDL_QueueAudio(SDL_AudioDeviceID device,
                                 const void *data, uint32_t bytes) {
    (void)device;
    (void)data;
    (void)bytes;
    return 0;
}

static inline const uint8_t *SDL_GetKeyboardState(int *count) {
    static const uint8_t keys[SDL_NUM_SCANCODES] = {0};
    if (count != NULL) {
        *count = SDL_NUM_SCANCODES;
    }
    return keys;
}

static inline int SDL_atoi(const char *text) {
    return atoi(text);
}

#endif
