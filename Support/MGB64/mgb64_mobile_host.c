#include <ultra64.h>

#include <sched.h>
#include <setjmp.h>
#include <pthread.h>
#include <mach/mach_time.h>
#include <stdio.h>
#include <stdatomic.h>
#include <stdlib.h>
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

static int goldenpad_watchdog_loading;
static int goldenpad_watchdog_paused;
static u32 goldenpad_watchdog_frames;
static pthread_mutex_t goldenpad_controller_mutex = PTHREAD_MUTEX_INITIALIZER;
static _Atomic int goldenpad_crouch_toggle_requested;

#define GOLDENPAD_FRAME_STATS_RING_CAP 1024
#define GOLDENPAD_FRAME_STATS_PUBLISH_MS 250.0
#define GOLDENPAD_FRAME_STATS_LOW_WINDOW_MS 2000.0

static float goldenpad_frame_stats_ring_ms[GOLDENPAD_FRAME_STATS_RING_CAP];
static u64 goldenpad_frame_stats_ring_time[GOLDENPAD_FRAME_STATS_RING_CAP];
static int goldenpad_frame_stats_ring_head;
static int goldenpad_frame_stats_ring_count;
static u64 goldenpad_frame_stats_last_tick;
static u64 goldenpad_frame_stats_window_start;
static float goldenpad_frame_stats_accum_ms;
static int goldenpad_frame_stats_accum_count;
static PlatformFrameStats goldenpad_frame_stats;
static PlatformFrameStats goldenpad_frame_stats_snapshot;
static pthread_mutex_t goldenpad_frame_stats_mutex = PTHREAD_MUTEX_INITIALIZER;

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
static _Atomic u64 goldenpad_audio_read_frame;
static _Atomic u64 goldenpad_audio_write_frame;
static _Atomic u32 goldenpad_audio_dropped_buffers;
static PortAiStats goldenpad_audio_stats;
static _Atomic int goldenpad_audio_started;
static _Atomic u64 goldenpad_audio_callback_count;
static _Atomic u64 goldenpad_audio_callback_requested_frames;
static _Atomic u64 goldenpad_audio_callback_shortfall_frames;
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

void goldenpad_mgb64_request_crouch_toggle(void) {
    atomic_store(&goldenpad_crouch_toggle_requested, 1);
}

int goldenpad_mgb64_consume_crouch_toggle(void) {
    return atomic_exchange(&goldenpad_crouch_toggle_requested, 0);
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

/* AVAudioEngine pulls the real MGB64 sequence/SFX mix from this bounded PCM
 * ring. The game/audio-synth side is the sole producer and AVAudioEngine is the
 * sole consumer, so monotonic atomic cursors avoid ever dropping a render
 * callback merely because the producer briefly owns a mutex. */
void portSynthLockInit(void) {}
void portAiInit(void) {
    atomic_store(&goldenpad_audio_read_frame, 0);
    atomic_store(&goldenpad_audio_write_frame, 0);
    atomic_store(&goldenpad_audio_dropped_buffers, 0);
    memset(&goldenpad_audio_stats, 0, sizeof(goldenpad_audio_stats));
    atomic_store(&goldenpad_audio_started, 0);
    atomic_store(&goldenpad_audio_callback_count, 0);
    atomic_store(&goldenpad_audio_callback_requested_frames, 0);
    atomic_store(&goldenpad_audio_callback_shortfall_frames, 0);
    atomic_store(&goldenpad_audio_rendered_frames, 0);
    atomic_store(&goldenpad_audio_nonzero_samples, 0);
    printf("[GoldenPad] MGB64 audio mixer connected to mobile PCM ring\n");
}

u32 osAiGetStatus(void) { return 0; }
s32 osAiSetFrequency(u32 frequency) { return (s32)frequency; }

s32 osAiSetNextBuffer(void *buffer, u32 size) {
    static int audio_dump_enabled = -1;
    const s16 *source = (const s16 *)buffer;
    u32 incoming_frames = size / (2u * (u32)sizeof(s16));
    u64 read_frame;
    u64 write_frame;
    u64 queued_frames;
    u64 available_frames;
    if (source == NULL || incoming_frames == 0) {
        return 0;
    }
    /* Diagnostic-only final-mix tap. audi_port.c's music dump runs before SFX;
     * this matching tap runs after SFX and master gain, immediately before the
     * mobile PCM transport. With both dumps armed, their difference isolates
     * the effects bus without altering normal device audio. */
    if (audio_dump_enabled < 0) {
        audio_dump_enabled = getenv("GE007_AUDIO_DUMP") != NULL ? 1 : 0;
    }
    if (audio_dump_enabled) {
        extern void portAudioDump(const void *buf, unsigned int bytes);
        portAudioDump(buffer, size);
    }
    if (incoming_frames > GOLDENPAD_AUDIO_RING_FRAMES) {
        source += (incoming_frames - GOLDENPAD_AUDIO_RING_FRAMES) * 2u;
        incoming_frames = GOLDENPAD_AUDIO_RING_FRAMES;
    }

    read_frame = atomic_load_explicit(
        &goldenpad_audio_read_frame, memory_order_acquire);
    write_frame = atomic_load_explicit(
        &goldenpad_audio_write_frame, memory_order_relaxed);
    queued_frames = write_frame >= read_frame ? write_frame - read_frame : 0;
    if (queued_frames > GOLDENPAD_AUDIO_RING_FRAMES) {
        queued_frames = GOLDENPAD_AUDIO_RING_FRAMES;
    }
    available_frames = GOLDENPAD_AUDIO_RING_FRAMES - queued_frames;
    goldenpad_audio_stats.queue_before_bytes =
        (u32)queued_frames * 2u * (u32)sizeof(s16);
    goldenpad_audio_stats.requested_bytes = size;
    if ((u64)incoming_frames > available_frames) {
        u32 discard = incoming_frames - (u32)available_frames;
        source += discard * 2u;
        incoming_frames -= discard;
        atomic_fetch_add(&goldenpad_audio_dropped_buffers, 1);
        goldenpad_audio_stats.dropped_bytes += discard * 2u * (u32)sizeof(s16);
    }
    for (u32 frame = 0; frame < incoming_frames; ++frame) {
        u32 destination = (u32)(
            (write_frame + frame) % GOLDENPAD_AUDIO_RING_FRAMES) * 2u;
        goldenpad_audio_ring[destination] = source[frame * 2u];
        goldenpad_audio_ring[destination + 1u] = source[frame * 2u + 1u];
    }
    atomic_store_explicit(
        &goldenpad_audio_write_frame,
        write_frame + incoming_frames,
        memory_order_release);
    atomic_store_explicit(&goldenpad_audio_started, 1, memory_order_release);
    goldenpad_audio_stats.accepted_bytes = incoming_frames * 2u * (u32)sizeof(s16);
    goldenpad_audio_stats.queue_after_bytes =
        ((u32)queued_frames + incoming_frames) * 2u * (u32)sizeof(s16);
    goldenpad_audio_stats.queue_limit_bytes = sizeof(goldenpad_audio_ring);
    goldenpad_audio_stats.dropped_buffers =
        atomic_load(&goldenpad_audio_dropped_buffers);
    return 0;
}

u32 osAiGetLength(void) {
    u64 read_frame = atomic_load_explicit(
        &goldenpad_audio_read_frame, memory_order_acquire);
    u64 write_frame = atomic_load_explicit(
        &goldenpad_audio_write_frame, memory_order_acquire);
    u64 queued_frames = write_frame >= read_frame ? write_frame - read_frame : 0;
    if (queued_frames > GOLDENPAD_AUDIO_RING_FRAMES) {
        queued_frames = GOLDENPAD_AUDIO_RING_FRAMES;
    }
    return (u32)queued_frames * 2u * (u32)sizeof(s16);
}

int osAiQueueBelowLimit(void) {
    return osAiGetLength() <
        (GOLDENPAD_AUDIO_RING_FRAMES / 2u) * 2u * (u32)sizeof(s16);
}

u32 portAiGetDroppedBufferCount(void) {
    return atomic_load(&goldenpad_audio_dropped_buffers);
}
void portAiGetStats(PortAiStats *stats) {
    if (stats == NULL) {
        return;
    }
    *stats = goldenpad_audio_stats;
}

u32 goldenpad_mgb64_audio_render(float *left, float *right, u32 frames) {
    u64 read_frame;
    u64 write_frame;
    u64 available_frames;
    u32 produced;
    u32 nonzero = 0;
    if (left == NULL || right == NULL) {
        return 0;
    }
    read_frame = atomic_load_explicit(
        &goldenpad_audio_read_frame, memory_order_relaxed);
    write_frame = atomic_load_explicit(
        &goldenpad_audio_write_frame, memory_order_acquire);
    available_frames = write_frame >= read_frame ? write_frame - read_frame : 0;
    if (available_frames > GOLDENPAD_AUDIO_RING_FRAMES) {
        available_frames = GOLDENPAD_AUDIO_RING_FRAMES;
    }
    produced = frames < available_frames ? frames : (u32)available_frames;
    for (u32 frame = 0; frame < produced; ++frame) {
        u32 source = (u32)(
            (read_frame + frame) % GOLDENPAD_AUDIO_RING_FRAMES) * 2u;
        left[frame] = (float)goldenpad_audio_ring[source] / 32768.0f;
        right[frame] = (float)goldenpad_audio_ring[source + 1u] / 32768.0f;
        nonzero += goldenpad_audio_ring[source] != 0;
        nonzero += goldenpad_audio_ring[source + 1u] != 0;
    }
    atomic_store_explicit(
        &goldenpad_audio_read_frame,
        read_frame + produced,
        memory_order_release);
    for (u32 frame = produced; frame < frames; ++frame) {
        left[frame] = 0.0f;
        right[frame] = 0.0f;
    }
    if (atomic_load_explicit(&goldenpad_audio_started, memory_order_acquire)) {
        atomic_fetch_add(&goldenpad_audio_callback_count, 1);
        atomic_fetch_add(&goldenpad_audio_callback_requested_frames, frames);
        atomic_fetch_add(
            &goldenpad_audio_callback_shortfall_frames, frames - produced);
    }
    atomic_fetch_add(&goldenpad_audio_rendered_frames, produced);
    atomic_fetch_add(&goldenpad_audio_nonzero_samples, nonzero);
    return produced;
}

void goldenpad_mgb64_audio_callback_stats(
    u64 *callbacks, u64 *requested_frames, u64 *rendered_frames,
    u64 *shortfall_frames) {
    if (callbacks != NULL) {
        *callbacks = atomic_load(&goldenpad_audio_callback_count);
    }
    if (requested_frames != NULL) {
        *requested_frames = atomic_load(
            &goldenpad_audio_callback_requested_frames);
    }
    if (rendered_frames != NULL) {
        *rendered_frames = atomic_load(&goldenpad_audio_rendered_frames);
    }
    if (shortfall_frames != NULL) {
        *shortfall_frames = atomic_load(
            &goldenpad_audio_callback_shortfall_frames);
    }
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

static double goldenpad_frame_stats_milliseconds(u64 ticks) {
    static mach_timebase_info_data_t timebase;
    if (timebase.denom == 0) {
        mach_timebase_info(&timebase);
    }
    return (double)ticks * (double)timebase.numer /
        (double)timebase.denom / 1000000.0;
}

static int goldenpad_frame_stats_compare_descending(
    const void *left, const void *right) {
    float a = *(const float *)left;
    float b = *(const float *)right;
    return a < b ? 1 : (a > b ? -1 : 0);
}

static float goldenpad_frame_stats_low1(u64 now) {
    float window[GOLDENPAD_FRAME_STATS_RING_CAP];
    int window_count = 0;
    double sum_ms = 0.0;

    for (int i = 0; i < goldenpad_frame_stats_ring_count; ++i) {
        int index = (goldenpad_frame_stats_ring_head - 1 - i +
                     GOLDENPAD_FRAME_STATS_RING_CAP) %
                    GOLDENPAD_FRAME_STATS_RING_CAP;
        if (goldenpad_frame_stats_milliseconds(
                now - goldenpad_frame_stats_ring_time[index]) >
            GOLDENPAD_FRAME_STATS_LOW_WINDOW_MS) {
            break;
        }
        window[window_count++] = goldenpad_frame_stats_ring_ms[index];
    }
    if (window_count == 0) {
        return 0.0f;
    }
    qsort(window, (size_t)window_count, sizeof(window[0]),
          goldenpad_frame_stats_compare_descending);
    int slow_count = window_count / 100;
    if (slow_count < 1) {
        slow_count = 1;
    }
    for (int i = 0; i < slow_count; ++i) {
        sum_ms += window[i];
    }
    double average_ms = sum_ms / (double)slow_count;
    return average_ms > 0.0 ? (float)(1000.0 / average_ms) : 0.0f;
}

static void goldenpad_frame_stats_reset_locked(void) {
    goldenpad_frame_stats_ring_head = 0;
    goldenpad_frame_stats_ring_count = 0;
    goldenpad_frame_stats_last_tick = 0;
    goldenpad_frame_stats_window_start = 0;
    goldenpad_frame_stats_accum_ms = 0.0f;
    goldenpad_frame_stats_accum_count = 0;
}

void goldenpad_mgb64_frame_stats_set_active(int active) {
    pthread_mutex_lock(&goldenpad_frame_stats_mutex);
    goldenpad_frame_stats_reset_locked();
    if (active) {
        u64 now = mach_continuous_time();
        goldenpad_frame_stats_last_tick = now;
        goldenpad_frame_stats_window_start = now;
    }
    pthread_mutex_unlock(&goldenpad_frame_stats_mutex);
}

void platformFrameStatsTick(void) {
    u64 now = mach_continuous_time();
    pthread_mutex_lock(&goldenpad_frame_stats_mutex);
    if (goldenpad_frame_stats_last_tick == 0) {
        goldenpad_frame_stats_last_tick = now;
        goldenpad_frame_stats_window_start = now;
        pthread_mutex_unlock(&goldenpad_frame_stats_mutex);
        return;
    }

    double delta_ms = goldenpad_frame_stats_milliseconds(
        now - goldenpad_frame_stats_last_tick);
    goldenpad_frame_stats_last_tick = now;
    goldenpad_frame_stats_ring_ms[goldenpad_frame_stats_ring_head] =
        (float)delta_ms;
    goldenpad_frame_stats_ring_time[goldenpad_frame_stats_ring_head] = now;
    goldenpad_frame_stats_ring_head =
        (goldenpad_frame_stats_ring_head + 1) % GOLDENPAD_FRAME_STATS_RING_CAP;
    if (goldenpad_frame_stats_ring_count < GOLDENPAD_FRAME_STATS_RING_CAP) {
        goldenpad_frame_stats_ring_count++;
    }
    goldenpad_frame_stats_accum_ms += (float)delta_ms;
    goldenpad_frame_stats_accum_count++;

    if (goldenpad_frame_stats_milliseconds(
            now - goldenpad_frame_stats_window_start) >=
            GOLDENPAD_FRAME_STATS_PUBLISH_MS &&
        goldenpad_frame_stats_accum_count > 0) {
        float average_ms = goldenpad_frame_stats_accum_ms /
            (float)goldenpad_frame_stats_accum_count;
        goldenpad_frame_stats.frame_ms = average_ms;
        goldenpad_frame_stats.fps =
            average_ms > 0.0f ? 1000.0f / average_ms : 0.0f;
        goldenpad_frame_stats.low1_fps = goldenpad_frame_stats_low1(now);
        goldenpad_frame_stats.generation++;
        goldenpad_frame_stats_accum_ms = 0.0f;
        goldenpad_frame_stats_accum_count = 0;
        goldenpad_frame_stats_window_start = now;
    }
    pthread_mutex_unlock(&goldenpad_frame_stats_mutex);
}

const PlatformFrameStats *platformFrameStatsGet(void) {
    pthread_mutex_lock(&goldenpad_frame_stats_mutex);
    goldenpad_frame_stats_snapshot = goldenpad_frame_stats;
    pthread_mutex_unlock(&goldenpad_frame_stats_mutex);
    return &goldenpad_frame_stats_snapshot;
}

int goldenpad_mgb64_frame_stats_snapshot(
    float *fps, float *frame_ms, float *low1_fps, u32 *generation) {
    pthread_mutex_lock(&goldenpad_frame_stats_mutex);
    PlatformFrameStats snapshot = goldenpad_frame_stats;
    pthread_mutex_unlock(&goldenpad_frame_stats_mutex);
    if (fps != NULL) *fps = snapshot.fps;
    if (frame_ms != NULL) *frame_ms = snapshot.frame_ms;
    if (low1_fps != NULL) *low1_fps = snapshot.low1_fps;
    if (generation != NULL) *generation = snapshot.generation;
    return snapshot.generation > 0 && snapshot.fps > 0.0f &&
        snapshot.frame_ms > 0.0f;
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
