#ifndef GOLDENPAD_MGB64_MOBILE_RENDERER_SDL_H
#define GOLDENPAD_MGB64_MOBILE_RENDERER_SDL_H

/* The Fast3D frontend only reaches these APIs from its desktop OpenGL paths.
 * GoldenPad selects Metal, so the mobile archive keeps the declarations local
 * and deliberately traps if desktop window ownership is ever selected. */
typedef struct SDL_Window SDL_Window;

static inline void SDL_GL_GetDrawableSize(SDL_Window *window, int *width, int *height) {
    (void)window;
    (void)width;
    (void)height;
    __builtin_trap();
}

static inline void SDL_GL_SwapWindow(SDL_Window *window) {
    (void)window;
    __builtin_trap();
}

#endif
