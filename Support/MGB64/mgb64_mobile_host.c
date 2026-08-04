#include <ultra64.h>

#include <sched.h>
#include <setjmp.h>
#include <pthread.h>
#include <stdio.h>
#include <stdatomic.h>
#include <string.h>

#include "frame_stats.h"
#include "audi.h"

/*
 * UIKit and GameController own the mobile host. These definitions deliberately
 * start neutral and contain no SDL window/event state. The Swift input bridge
 * can replace the accessors without changing GoldenEye simulation code.
 */

int g_deterministic = 0;
int g_freezeInput = 0;
int g_audioSynthLockActive = 0;
int g_screenshotFrameSessionActive = 0;
const char *g_traceStatePath = NULL;
int g_crashRecoveryCount = 0;

sigjmp_buf g_gfxRecoveryJmp;
volatile int g_gfxRecoveryActive = 0;

volatile int g_portWatchdogAiChrnum = -1;
volatile int g_portWatchdogAiOpcode = -1;
volatile int g_portWatchdogDynVtxUsed = 0;

static PlatformFrameStats goldenpad_frame_stats;
static int goldenpad_watchdog_loading;
static int goldenpad_watchdog_paused;
static u32 goldenpad_watchdog_frames;
static pthread_mutex_t goldenpad_controller_mutex = PTHREAD_MUTEX_INITIALIZER;

typedef struct {
    int connected;
    s8 stick_x;
    s8 stick_y;
    u16 buttons;
    int right_x;
    int right_y;
} GoldenPadControllerState;

static GoldenPadControllerState goldenpad_controllers[MAXCONTROLLERS];
static u16 goldenpad_controller_queued_buttons[MAXCONTROLLERS];

#define GOLDENPAD_AUDIO_RING_FRAMES 65536u
static s16 goldenpad_audio_ring[GOLDENPAD_AUDIO_RING_FRAMES * 2];
static u32 goldenpad_audio_read_frame;
static u32 goldenpad_audio_frame_count;
static u32 goldenpad_audio_dropped_buffers;
static PortAiStats goldenpad_audio_stats;
static pthread_mutex_t goldenpad_audio_mutex = PTHREAD_MUTEX_INITIALIZER;
static _Atomic u64 goldenpad_audio_rendered_frames;
static _Atomic u64 goldenpad_audio_nonzero_samples;

void goldenpad_mgb64_set_controller_state(
    int player, int stick_x, int stick_y, u32 buttons,
    int right_x, int right_y, int connected) {
    if (player < 0 || player >= MAXCONTROLLERS) {
        return;
    }
    if (stick_x < -80) stick_x = -80;
    if (stick_x > 80) stick_x = 80;
    if (stick_y < -80) stick_y = -80;
    if (stick_y > 80) stick_y = 80;
    if (right_x < -32767) right_x = -32767;
    if (right_x > 32767) right_x = 32767;
    if (right_y < -32767) right_y = -32767;
    if (right_y > 32767) right_y = 32767;

    pthread_mutex_lock(&goldenpad_controller_mutex);
    goldenpad_controllers[player] = (GoldenPadControllerState) {
        .connected = connected != 0,
        .stick_x = connected ? (s8)stick_x : 0,
        .stick_y = connected ? (s8)stick_y : 0,
        .buttons = connected ? (u16)buttons : 0,
        .right_x = connected ? right_x : 0,
        .right_y = connected ? right_y : 0,
    };
    pthread_mutex_unlock(&goldenpad_controller_mutex);
}

void goldenpad_mgb64_queue_controller_buttons(int player, u32 buttons) {
    if (player < 0 || player >= MAXCONTROLLERS) {
        return;
    }
    pthread_mutex_lock(&goldenpad_controller_mutex);
    goldenpad_controller_queued_buttons[player] |= (u16)buttons;
    pthread_mutex_unlock(&goldenpad_controller_mutex);
}

void goldenpad_mgb64_read_controller_pads(OSContPad *pads) {
    if (pads == NULL) {
        return;
    }
    pthread_mutex_lock(&goldenpad_controller_mutex);
    for (int player = 0; player < MAXCONTROLLERS; ++player) {
        GoldenPadControllerState state = goldenpad_controllers[player];
        memset(&pads[player], 0, sizeof(pads[player]));
        if (state.connected) {
            pads[player].stick_x = state.stick_x;
            pads[player].stick_y = state.stick_y;
            pads[player].button = state.buttons |
                goldenpad_controller_queued_buttons[player];
            goldenpad_controller_queued_buttons[player] = 0;
        } else {
            pads[player].errnum = CONT_NO_RESPONSE_ERROR;
        }
    }
    pthread_mutex_unlock(&goldenpad_controller_mutex);
}

void goldenpad_mgb64_read_controller_status(OSContStatus *status) {
    if (status == NULL) {
        return;
    }
    pthread_mutex_lock(&goldenpad_controller_mutex);
    for (int player = 0; player < MAXCONTROLLERS; ++player) {
        memset(&status[player], 0, sizeof(status[player]));
        if (goldenpad_controllers[player].connected) {
            status[player].type = CONT_TYPE_NORMAL;
        } else {
            status[player].errnum = CONT_NO_RESPONSE_ERROR;
        }
    }
    pthread_mutex_unlock(&goldenpad_controller_mutex);
}

int goldenpad_mgb64_controller_input_probe(void) {
    int passed;
    pthread_mutex_lock(&goldenpad_controller_mutex);
    passed = goldenpad_controllers[0].connected &&
        goldenpad_controllers[0].stick_x != 0 &&
        goldenpad_controllers[0].stick_y != 0 &&
        goldenpad_controllers[0].right_x != 0 &&
        goldenpad_controllers[0].right_y != 0 &&
        goldenpad_controllers[0].buttons == (B_BUTTON | Z_TRIG);
    printf("[GoldenPad] Input bridge state: connected=%d stick=%d,%d right=%d,%d buttons=0x%04x\n",
           goldenpad_controllers[0].connected,
           goldenpad_controllers[0].stick_x,
           goldenpad_controllers[0].stick_y,
           goldenpad_controllers[0].right_x,
           goldenpad_controllers[0].right_y,
           goldenpad_controllers[0].buttons);
    pthread_mutex_unlock(&goldenpad_controller_mutex);
    return passed;
}

void platformDrainEvents(void) {}

/* Audio synthesis remains single-threaded on mobile. AVAudioEngine pulls the
 * real MGB64 sequence/SFX mix from this bounded PCM ring. */
void portSynthLockInit(void) {}
void portAiInit(void) {
    pthread_mutex_lock(&goldenpad_audio_mutex);
    goldenpad_audio_read_frame = 0;
    goldenpad_audio_frame_count = 0;
    goldenpad_audio_dropped_buffers = 0;
    memset(&goldenpad_audio_stats, 0, sizeof(goldenpad_audio_stats));
    atomic_store(&goldenpad_audio_rendered_frames, 0);
    atomic_store(&goldenpad_audio_nonzero_samples, 0);
    pthread_mutex_unlock(&goldenpad_audio_mutex);
    printf("[GoldenPad] MGB64 audio mixer connected to mobile PCM ring\n");
}

u32 osAiGetStatus(void) { return 0; }
s32 osAiSetFrequency(u32 frequency) { return (s32)frequency; }

s32 osAiSetNextBuffer(void *buffer, u32 size) {
    const s16 *source = (const s16 *)buffer;
    u32 incoming_frames = size / (2u * (u32)sizeof(s16));
    if (source == NULL || incoming_frames == 0) {
        return 0;
    }
    if (incoming_frames > GOLDENPAD_AUDIO_RING_FRAMES) {
        source += (incoming_frames - GOLDENPAD_AUDIO_RING_FRAMES) * 2u;
        incoming_frames = GOLDENPAD_AUDIO_RING_FRAMES;
    }

    pthread_mutex_lock(&goldenpad_audio_mutex);
    goldenpad_audio_stats.queue_before_bytes =
        goldenpad_audio_frame_count * 2u * (u32)sizeof(s16);
    goldenpad_audio_stats.requested_bytes = size;
    if (incoming_frames > GOLDENPAD_AUDIO_RING_FRAMES - goldenpad_audio_frame_count) {
        u32 discard = incoming_frames -
            (GOLDENPAD_AUDIO_RING_FRAMES - goldenpad_audio_frame_count);
        goldenpad_audio_read_frame =
            (goldenpad_audio_read_frame + discard) % GOLDENPAD_AUDIO_RING_FRAMES;
        goldenpad_audio_frame_count -= discard;
        goldenpad_audio_dropped_buffers++;
        goldenpad_audio_stats.dropped_bytes += discard * 2u * (u32)sizeof(s16);
    }
    u32 write_frame =
        (goldenpad_audio_read_frame + goldenpad_audio_frame_count) %
        GOLDENPAD_AUDIO_RING_FRAMES;
    for (u32 frame = 0; frame < incoming_frames; ++frame) {
        u32 destination = ((write_frame + frame) % GOLDENPAD_AUDIO_RING_FRAMES) * 2u;
        goldenpad_audio_ring[destination] = source[frame * 2u];
        goldenpad_audio_ring[destination + 1u] = source[frame * 2u + 1u];
    }
    goldenpad_audio_frame_count += incoming_frames;
    goldenpad_audio_stats.accepted_bytes = incoming_frames * 2u * (u32)sizeof(s16);
    goldenpad_audio_stats.queue_after_bytes =
        goldenpad_audio_frame_count * 2u * (u32)sizeof(s16);
    goldenpad_audio_stats.queue_limit_bytes = sizeof(goldenpad_audio_ring);
    goldenpad_audio_stats.dropped_buffers = goldenpad_audio_dropped_buffers;
    pthread_mutex_unlock(&goldenpad_audio_mutex);
    return 0;
}

u32 osAiGetLength(void) {
    u32 bytes;
    pthread_mutex_lock(&goldenpad_audio_mutex);
    bytes = goldenpad_audio_frame_count * 2u * (u32)sizeof(s16);
    pthread_mutex_unlock(&goldenpad_audio_mutex);
    return bytes;
}

int osAiQueueBelowLimit(void) {
    int below;
    pthread_mutex_lock(&goldenpad_audio_mutex);
    below = goldenpad_audio_frame_count < GOLDENPAD_AUDIO_RING_FRAMES / 2u;
    pthread_mutex_unlock(&goldenpad_audio_mutex);
    return below;
}

u32 portAiGetDroppedBufferCount(void) {
    u32 count;
    pthread_mutex_lock(&goldenpad_audio_mutex);
    count = goldenpad_audio_dropped_buffers;
    pthread_mutex_unlock(&goldenpad_audio_mutex);
    return count;
}
void portAiGetStats(PortAiStats *stats) {
    if (stats == NULL) {
        return;
    }
    pthread_mutex_lock(&goldenpad_audio_mutex);
    *stats = goldenpad_audio_stats;
    pthread_mutex_unlock(&goldenpad_audio_mutex);
}

u32 goldenpad_mgb64_audio_render(float *left, float *right, u32 frames) {
    u32 produced = 0;
    u32 nonzero = 0;
    if (left == NULL || right == NULL) {
        return 0;
    }
    if (pthread_mutex_trylock(&goldenpad_audio_mutex) == 0) {
        produced = frames < goldenpad_audio_frame_count
            ? frames : goldenpad_audio_frame_count;
        for (u32 frame = 0; frame < produced; ++frame) {
            u32 source =
                ((goldenpad_audio_read_frame + frame) % GOLDENPAD_AUDIO_RING_FRAMES) * 2u;
            left[frame] = (float)goldenpad_audio_ring[source] / 32768.0f;
            right[frame] = (float)goldenpad_audio_ring[source + 1u] / 32768.0f;
            nonzero += goldenpad_audio_ring[source] != 0;
            nonzero += goldenpad_audio_ring[source + 1u] != 0;
        }
        goldenpad_audio_read_frame =
            (goldenpad_audio_read_frame + produced) % GOLDENPAD_AUDIO_RING_FRAMES;
        goldenpad_audio_frame_count -= produced;
        pthread_mutex_unlock(&goldenpad_audio_mutex);
    }
    for (u32 frame = produced; frame < frames; ++frame) {
        left[frame] = 0.0f;
        right[frame] = 0.0f;
    }
    atomic_fetch_add(&goldenpad_audio_rendered_frames, produced);
    atomic_fetch_add(&goldenpad_audio_nonzero_samples, nonzero);
    return produced;
}

int goldenpad_mgb64_audio_output_probe(void) {
    return atomic_load(&goldenpad_audio_rendered_frames) > 0 &&
        atomic_load(&goldenpad_audio_nonzero_samples) > 0;
}

/* Desktop keyboard/tape diagnostics have no mobile activation path. Keeping
 * their frame hooks inert is an explicit platform policy, not game behavior. */
void debugDumpExecute(void) {}
void debugDumpOverlayTick(void) {}
void inputTapeInstallHooks(void) {}

void portLoadYield(void) {
    if (!g_deterministic) {
        sched_yield();
    }
}

int pcStableDeterministicCountEnabled(void) { return 0; }
void pcAdvanceDeterministicCountForFrame(void) {}

void platformGetMouseDelta(int *dx, int *dy) {
    if (dx != NULL) {
        *dx = 0;
    }
    if (dy != NULL) {
        *dy = 0;
    }
}

int platformGetPadCount(void) {
    int count = 0;
    pthread_mutex_lock(&goldenpad_controller_mutex);
    for (int player = 0; player < MAXCONTROLLERS; ++player) {
        count += goldenpad_controllers[player].connected != 0;
    }
    pthread_mutex_unlock(&goldenpad_controller_mutex);
    return count;
}
unsigned int platformGetPadButtons(int player) {
    (void)player;
    return 0;
}

static void goldenpad_neutral_axes(int *x, int *y) {
    if (x != NULL) {
        *x = 0;
    }
    if (y != NULL) {
        *y = 0;
    }
}

void platformGetPadLeftStick(int player, int *x, int *y) {
    (void)player;
    goldenpad_neutral_axes(x, y);
}

void platformGetPadRightStick(int player, int *x, int *y) {
    if (player < 0 || player >= MAXCONTROLLERS) {
        goldenpad_neutral_axes(x, y);
        return;
    }
    pthread_mutex_lock(&goldenpad_controller_mutex);
    if (x != NULL) *x = goldenpad_controllers[player].right_x;
    if (y != NULL) *y = goldenpad_controllers[player].right_y;
    pthread_mutex_unlock(&goldenpad_controller_mutex);
}

void platformGetPadTriggers(int player, int *left, int *right) {
    (void)player;
    goldenpad_neutral_axes(left, right);
}

void platformRumblePlayer(s32 player, f32 duration) {
    (void)player;
    (void)duration;
}

void platformFrameStatsTick(void) {}
const PlatformFrameStats *platformFrameStatsGet(void) {
    return &goldenpad_frame_stats;
}

void portWatchdogInit(void) {
    goldenpad_watchdog_loading = 0;
    goldenpad_watchdog_paused = 0;
    goldenpad_watchdog_frames = 0;
}

void portWatchdogLoadBegin(void) { goldenpad_watchdog_loading = 1; }
void portWatchdogLoadEnd(void) { goldenpad_watchdog_loading = 0; }
void portWatchdogSetPaused(int paused) { goldenpad_watchdog_paused = paused != 0; }
void portWatchdogFrameTick(void) {
    if (!goldenpad_watchdog_loading && !goldenpad_watchdog_paused) {
        goldenpad_watchdog_frames++;
    }
}

int goldenpad_mgb64_mobile_host_probe(void) {
    int x = 1;
    int y = 1;
    PlatformFrameStats expected = {0};

    platformGetMouseDelta(&x, &y);
    if (x != 0 || y != 0 ||
        platformGetPadButtons(0) != 0 ||
        memcmp(platformFrameStatsGet(), &expected, sizeof(expected)) != 0) {
        return 0;
    }

    portWatchdogInit();
    portWatchdogLoadBegin();
    portWatchdogFrameTick();
    if (goldenpad_watchdog_frames != 0) {
        return 0;
    }
    portWatchdogLoadEnd();
    portWatchdogFrameTick();
    if (goldenpad_watchdog_frames != 1) {
        return 0;
    }
    portWatchdogSetPaused(1);
    portWatchdogFrameTick();
    if (goldenpad_watchdog_frames != 1) {
        return 0;
    }
    portWatchdogInit();
    return 1;
}
