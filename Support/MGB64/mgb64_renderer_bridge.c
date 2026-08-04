#include <stdbool.h>
#include <stdint.h>

#ifdef GOLDENPAD_MGB64_RENDERER
#include "gfx_pc.h"
#include "gfx_rendering_api.h"

extern struct GfxRenderingAPI gfx_metal_api;
extern int goldenpad_mgb64_deliver_retrace(void);
extern void goldenpad_mgb64_set_renderer_ready(int ready);
extern int goldenpad_mgb64_game_state(void);

int goldenpad_mgb64_renderer_initialize(void) {
    static int initialized = 0;
    if (initialized) {
        return 1;
    }
    gfx_init();
    goldenpad_mgb64_set_renderer_ready(1);
    initialized = 1;
    return 1;
}

int goldenpad_mgb64_renderer_draw_frame(uint32_t width, uint32_t height) {
    if (width == 0 || height == 0 || !goldenpad_mgb64_renderer_initialize()) {
        return 0;
    }
    gfx_current_dimensions.width = width;
    gfx_current_dimensions.height = height;
    gfx_current_dimensions.aspect_ratio = (float)width / (float)height;
    if (goldenpad_mgb64_game_state() != 0) {
        (void)goldenpad_mgb64_deliver_retrace();
        return 1;
    }
    gfx_metal_api.start_frame();
    gfx_metal_api.end_frame();
    (void)goldenpad_mgb64_deliver_retrace();
    return 1;
}
#else
int goldenpad_mgb64_renderer_initialize(void) {
    return 0;
}

int goldenpad_mgb64_renderer_draw_frame(uint32_t width, uint32_t height) {
    (void)width;
    (void)height;
    return 0;
}
#endif
