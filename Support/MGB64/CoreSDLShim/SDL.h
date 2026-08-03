#ifndef GOLDENPAD_MGB64_CORE_SDL_SHIM_H
#define GOLDENPAD_MGB64_CORE_SDL_SHIM_H

#include <stdint.h>
#include <stdlib.h>

/* The decompiled core has one optional desktop level-selector dependency on
 * SDL keyboard state. GoldenPad supplies gameplay input through its normalized
 * host API, so the core-only archive keeps that selector inert. This header is
 * intentionally visible only to the core target; the future renderer/platform
 * target will use the real mobile platform adapter. */
enum {
    SDL_SCANCODE_W = 26,
    SDL_SCANCODE_S = 22,
    SDL_SCANCODE_RETURN = 40,
    SDL_SCANCODE_ESCAPE = 41,
    SDL_SCANCODE_SPACE = 44,
    SDL_SCANCODE_UP = 82,
    SDL_SCANCODE_DOWN = 81,
    SDL_NUM_SCANCODES = 512
};

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
