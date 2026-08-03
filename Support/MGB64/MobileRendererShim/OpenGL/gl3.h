#ifndef GOLDENPAD_MGB64_MOBILE_RENDERER_OPENGL_H
#define GOLDENPAD_MGB64_MOBILE_RENDERER_OPENGL_H

/* iOS has no desktop OpenGL framework. These diagnostics are unreachable when
 * the required Metal backend is selected; trap if that invariant regresses. */
enum {
    GL_TEXTURE_2D = 0x0DE1,
    GL_RGBA = 0x1908,
    GL_RGB = 0x1907,
    GL_UNSIGNED_BYTE = 0x1401,
};

static inline void glGetTexImage(
    unsigned int target,
    int level,
    unsigned int format,
    unsigned int type,
    void *pixels
) {
    (void)target;
    (void)level;
    (void)format;
    (void)type;
    (void)pixels;
    __builtin_trap();
}

static inline void glReadPixels(
    int x,
    int y,
    int width,
    int height,
    unsigned int format,
    unsigned int type,
    void *pixels
) {
    (void)x;
    (void)y;
    (void)width;
    (void)height;
    (void)format;
    (void)type;
    (void)pixels;
    __builtin_trap();
}

#endif
