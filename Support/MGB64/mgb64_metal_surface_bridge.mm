#import <QuartzCore/CAMetalLayer.h>

/* MTKView retains its CAMetalLayer. The renderer bridge observes that layer
 * without taking ownership so teardown remains controlled by the Swift host. */
static __weak CAMetalLayer *goldenpad_mgb64_metal_layer = nil;

extern "C" void goldenpad_mgb64_set_metal_layer(void *layer) {
    goldenpad_mgb64_metal_layer = (__bridge CAMetalLayer *)layer;
}

extern "C" int goldenpad_mgb64_has_metal_layer(void) {
    return goldenpad_mgb64_metal_layer != nil ? 1 : 0;
}

/* Exact symbol consumed by MGB64 gfx_metal.mm. Desktop MGB64 provides it from
 * platform_sdl.c; GoldenPad owns the equivalent mobile surface boundary. */
extern "C" __attribute__((used, retain)) void *platformGetMetalLayer(void) {
    return (__bridge void *)goldenpad_mgb64_metal_layer;
}
