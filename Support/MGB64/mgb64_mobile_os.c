#include <ultra64.h>
#include <pthread.h>
#include <sched.h>
#include <stdatomic.h>

#include <stdio.h>
#include <string.h>
#include <time.h>

/*
 * MGB64's native scheduler is cooperative: its desktop host leaves the N64
 * scheduler thread dormant and delivers retrace messages from the frame loop.
 * This file preserves that model without importing the desktop SDL input and
 * audio stack. UIKit/Metal will own frame delivery; the timed fallback below is
 * only the initial mobile host seam and never runs during scheduler setup.
 */

OSThread shedThread;
OSMesgQueue gfxFrameMsgQ;
OSMesg gfxFrameMsgBuf[32];
OSMesgQueue *sched_cmdQ;

u32 osTvType = OS_TV_NTSC;
OSViMode osViModeTable[64] = {{0}};
u64 osClockRate = 46875000ULL;

static void *goldenpad_vi_framebuffer;
static int goldenpad_scheduler_initialized;
static u32 goldenpad_retrace_count;
static pthread_mutex_t goldenpad_queue_mutex = PTHREAD_MUTEX_INITIALIZER;
static _Atomic int goldenpad_external_retrace_configured;
static _Atomic int goldenpad_external_retrace_active;

#define GOLDENPAD_MAX_TIMERS 16
#define GOLDENPAD_EEPROM_SIZE 2048

typedef struct {
    int active;
    OSTimer *handle;
    u64 expiry_us;
    u64 interval_us;
    OSMesgQueue *mq;
    OSMesg message;
} GoldenPadTimer;

static GoldenPadTimer goldenpad_timers[GOLDENPAD_MAX_TIMERS];
static pthread_mutex_t goldenpad_timer_mutex = PTHREAD_MUTEX_INITIALIZER;
static u8 goldenpad_eeprom[GOLDENPAD_EEPROM_SIZE];
static pthread_mutex_t goldenpad_eeprom_mutex = PTHREAD_MUTEX_INITIALIZER;
static _Atomic u32 goldenpad_eeprom_generation;

static u64 goldenpad_mgb64_monotonic_us(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (u64)now.tv_sec * 1000000ULL + (u64)now.tv_nsec / 1000ULL;
}

void osCreateMesgQueue(OSMesgQueue *mq, OSMesg *messages, s32 count) {
    if (mq == NULL) {
        return;
    }
    pthread_mutex_lock(&goldenpad_queue_mutex);
    memset(mq, 0, sizeof(*mq));
    mq->msg = messages;
    mq->msgCount = count;
    pthread_mutex_unlock(&goldenpad_queue_mutex);
}

s32 osSendMesg(OSMesgQueue *mq, OSMesg message, s32 flags) {
    const struct timespec poll_period = {0, 1000000L};
    for (;;) {
        pthread_mutex_lock(&goldenpad_queue_mutex);
        if (mq == NULL || mq->msg == NULL || mq->msgCount <= 0) {
            pthread_mutex_unlock(&goldenpad_queue_mutex);
            return -1;
        }
        if (mq->validCount < mq->msgCount) {
            s32 index = (mq->first + mq->validCount) % mq->msgCount;
            mq->msg[index] = message;
            mq->validCount++;
            pthread_mutex_unlock(&goldenpad_queue_mutex);
            return 0;
        }
        pthread_mutex_unlock(&goldenpad_queue_mutex);
        if (flags == OS_MESG_NOBLOCK) {
            return -1;
        }
        nanosleep(&poll_period, NULL);
    }
}

static s32 goldenpad_mgb64_take_message(OSMesgQueue *mq, OSMesg *message) {
    s32 result = -1;
    pthread_mutex_lock(&goldenpad_queue_mutex);
    if (mq == NULL || mq->validCount <= 0) {
        goto done;
    }
    if (message != NULL) {
        *message = mq->msg[mq->first];
    }
    mq->first = (mq->first + 1) % mq->msgCount;
    mq->validCount--;
    result = 0;
done:
    pthread_mutex_unlock(&goldenpad_queue_mutex);
    return result;
}

static void goldenpad_mgb64_pump_audio_for_retrace(
    OSMesgQueue *mq, OSMesg message) {
    if (mq == &gfxFrameMsgQ && message != NULL &&
        ((OSScMsg *)message)->type == OS_SC_RETRACE_MSG) {
        extern void portAudioFrame(void);
        portAudioFrame();
    }
}

static int goldenpad_mgb64_queue_is_empty(OSMesgQueue *mq) {
    int empty;
    pthread_mutex_lock(&goldenpad_queue_mutex);
    empty = mq == NULL || mq->validCount == 0;
    pthread_mutex_unlock(&goldenpad_queue_mutex);
    return empty;
}

int goldenpad_mgb64_deliver_retrace(void) {
    OSScClient *client;
    if (!goldenpad_scheduler_initialized ||
        !goldenpad_mgb64_queue_is_empty(&gfxFrameMsgQ)) {
        return 0;
    }
    os_scheduler.frameCount++;
    for (client = os_scheduler.clientList; client != NULL; client = client->next) {
        if (osSendMesg(client->msgQ, (OSMesg)&os_scheduler.retraceMsg,
                       OS_MESG_NOBLOCK) == 0) {
            goldenpad_retrace_count++;
        }
    }
    if (goldenpad_retrace_count == 1) {
        printf("[GoldenPad] MGB64 cooperative retrace delivered\n");
    }
    return 1;
}

void goldenpad_mgb64_set_external_retrace_active(int active) {
    atomic_store(&goldenpad_external_retrace_configured, 1);
    atomic_store(&goldenpad_external_retrace_active, active != 0);
}

void platformCheckTimers(void) {
    u64 now = goldenpad_mgb64_monotonic_us();
    pthread_mutex_lock(&goldenpad_timer_mutex);
    for (int index = 0; index < GOLDENPAD_MAX_TIMERS; ++index) {
        GoldenPadTimer *timer = &goldenpad_timers[index];
        if (!timer->active || now < timer->expiry_us) {
            continue;
        }
        if (timer->mq != NULL) {
            (void)osSendMesg(timer->mq, timer->message, OS_MESG_NOBLOCK);
        }
        if (timer->interval_us != 0) {
            timer->expiry_us = now + timer->interval_us;
        } else {
            timer->active = 0;
            timer->handle = NULL;
            timer->mq = NULL;
        }
    }
    pthread_mutex_unlock(&goldenpad_timer_mutex);
}

s32 osRecvMesg(OSMesgQueue *mq, OSMesg *message, s32 flags) {
    const struct timespec poll_period = {0, 1000000L};
    const struct timespec fallback_period = {0, 16666667L};
    OSMesg local_message = NULL;
    OSMesg *destination = message != NULL ? message : &local_message;

    for (;;) {
        if (goldenpad_mgb64_take_message(mq, destination) == 0) {
            goldenpad_mgb64_pump_audio_for_retrace(mq, *destination);
            return 0;
        }
        if (flags == OS_MESG_NOBLOCK) {
            return -1;
        }

        platformCheckTimers();
        if (goldenpad_mgb64_take_message(mq, destination) == 0) {
            goldenpad_mgb64_pump_audio_for_retrace(mq, *destination);
            return 0;
        }

        if (mq == &gfxFrameMsgQ &&
            !atomic_load(&goldenpad_external_retrace_configured)) {
            nanosleep(&fallback_period, NULL);
            (void)goldenpad_mgb64_deliver_retrace();
        } else {
            /* MTKView is the producer once configured. When it is paused, the
             * game thread remains blocked instead of synthesizing background
             * frames. Other queues poll cooperatively for timers/messages. */
            const struct timespec *period =
                mq == &gfxFrameMsgQ &&
                atomic_load(&goldenpad_external_retrace_configured) &&
                !atomic_load(&goldenpad_external_retrace_active)
                    ? &fallback_period : &poll_period;
            nanosleep(period, NULL);
        }
    }
}

void osSetTimer(OSTimer *handle, u64 countdown, u64 interval,
                OSMesgQueue *mq, OSMesg message) {
    u64 delay_us = (countdown * 1000000ULL) / osClockRate;
    u64 interval_us = (interval * 1000000ULL) / osClockRate;
    int free_index = -1;

    if (handle != NULL) {
        handle->value = countdown;
        handle->interval = interval;
        handle->mq = mq;
        handle->msg = message;
    }
    if (delay_us < 1000) {
        if (mq != NULL) {
            (void)osSendMesg(mq, message, OS_MESG_NOBLOCK);
        }
        return;
    }

    pthread_mutex_lock(&goldenpad_timer_mutex);
    for (int index = 0; index < GOLDENPAD_MAX_TIMERS; ++index) {
        if (goldenpad_timers[index].active &&
            goldenpad_timers[index].handle == handle) {
            goldenpad_timers[index].active = 0;
        }
        if (!goldenpad_timers[index].active && free_index < 0) {
            free_index = index;
        }
    }
    if (free_index >= 0) {
        GoldenPadTimer *timer = &goldenpad_timers[free_index];
        timer->active = 1;
        timer->handle = handle;
        timer->expiry_us = goldenpad_mgb64_monotonic_us() + delay_us;
        timer->interval_us = interval_us;
        timer->mq = mq;
        timer->message = message;
    }
    pthread_mutex_unlock(&goldenpad_timer_mutex);

    if (free_index < 0 && mq != NULL) {
        (void)osSendMesg(mq, message, OS_MESG_NOBLOCK);
    }
}

void osStopTimer(OSTimer *handle) {
    pthread_mutex_lock(&goldenpad_timer_mutex);
    for (int index = 0; index < GOLDENPAD_MAX_TIMERS; ++index) {
        if (goldenpad_timers[index].active &&
            goldenpad_timers[index].handle == handle) {
            goldenpad_timers[index].active = 0;
            goldenpad_timers[index].handle = NULL;
            goldenpad_timers[index].mq = NULL;
        }
    }
    pthread_mutex_unlock(&goldenpad_timer_mutex);
}

void osCreateThread(OSThread *thread, OSId id, void (*entry)(void *),
                    void *arg, void *stack, OSPri priority) {
    (void)entry;
    (void)arg;
    (void)stack;
    if (thread != NULL) {
        memset(thread, 0, sizeof(*thread));
        thread->id = id;
        thread->priority = priority;
    }
}

void osStartThread(OSThread *thread) {
    (void)thread;
}

void osSetEventMesg(OSEvent event, OSMesgQueue *mq, OSMesg message) {
    (void)event;
    (void)mq;
    (void)message;
}

OSIntMask osSetIntMask(OSIntMask mask) {
    (void)mask;
    return 0;
}

u32 osGetCount(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (u32)((u64)now.tv_sec * 46875000ULL +
                 (u64)now.tv_nsec * 46875ULL / 1000000ULL);
}

void osSetTime(u64 value) { (void)value; }
u64 osGetTime(void) { return (u64)osGetCount(); }

void osCreateViManager(OSPri priority) {
    (void)priority;
}

void osViSetEvent(OSMesgQueue *mq, OSMesg message, u32 retrace_count) {
    (void)mq;
    (void)message;
    (void)retrace_count;
}

void osViSetMode(OSViMode *mode) { (void)mode; }
void osViBlack(u32 active) { (void)active; }
void osViSetSpecialFeatures(u32 features) { (void)features; }
void osViSetXScale(f32 scale) { (void)scale; }
void osViSetYScale(f32 scale) { (void)scale; }
void osViRepeatLine(u32 active) { (void)active; }
void osViSwapBuffer(void *framebuffer) { goldenpad_vi_framebuffer = framebuffer; }
void *osViGetCurrentFramebuffer(void) { return goldenpad_vi_framebuffer; }
void *osViGetNextFramebuffer(void) { return goldenpad_vi_framebuffer; }

void osDpSetStatus(u32 value) { (void)value; }
void osDpGetCounters(u32 *counters) {
    if (counters != NULL) {
        memset(counters, 0, sizeof(u32) * 4);
    }
}
s32 osDpSetNextBuffer(void *buffer, u64 size) {
    (void)buffer;
    (void)size;
    return 0;
}

void osSpTaskLoad(OSTask *task) { (void)task; }
void osSpTaskStartGo(OSTask *task) { (void)task; }
void osSpTaskYield(void) {}
OSYieldResult osSpTaskYielded(OSTask *task) {
    (void)task;
    return 0;
}

s32 osPiStartDma(OSIoMesg *message, s32 priority, s32 direction,
                 u32 device_address, void *dram_address, u32 size,
                 OSMesgQueue *queue) {
    extern u8 *g_romData;
    extern u32 g_romSize;
    s32 result = -1;

    (void)message;
    (void)priority;
    if (direction == OS_READ && dram_address != NULL && g_romData != NULL &&
        device_address <= g_romSize && size <= g_romSize - device_address) {
        memcpy(dram_address, g_romData + device_address, size);
        result = 0;
    }
    if (queue != NULL) {
        (void)osSendMesg(queue, NULL, OS_MESG_NOBLOCK);
    }
    return result;
}

static void goldenpad_mgb64_neutral_controller_status(OSContStatus *status) {
    if (status == NULL) {
        return;
    }
    memset(status, 0, sizeof(*status) * MAXCONTROLLERS);
    status[0].type = CONT_TYPE_NORMAL;
    for (int index = 1; index < MAXCONTROLLERS; ++index) {
        status[index].errnum = CONT_NO_RESPONSE_ERROR;
    }
}

extern void goldenpad_mgb64_read_controller_pads(OSContPad *pads);
extern void goldenpad_mgb64_read_controller_status(OSContStatus *status);

s32 osContInit(OSMesgQueue *mq, u8 *bitpattern, OSContStatus *status) {
    int connected = 0;
    OSContStatus current[MAXCONTROLLERS];
    goldenpad_mgb64_read_controller_status(current);
    for (int player = 0; player < MAXCONTROLLERS; ++player) {
        if (current[player].errnum == 0) {
            connected |= 1 << player;
        }
    }
    if (bitpattern != NULL) {
        *bitpattern = (u8)connected;
    }
    if (status != NULL) {
        memcpy(status, current, sizeof(current));
    }
    if (mq != NULL) {
        osSendMesg(mq, NULL, OS_MESG_NOBLOCK);
    }
    return 0;
}

s32 osContStartQuery(OSMesgQueue *mq) {
    return mq == NULL ? 0 : osSendMesg(mq, NULL, OS_MESG_NOBLOCK);
}

s32 osContStartReadData(OSMesgQueue *mq) {
    return mq == NULL ? 0 : osSendMesg(mq, NULL, OS_MESG_NOBLOCK);
}

s32 osContGetQuery(OSContStatus *status) {
    goldenpad_mgb64_read_controller_status(status);
    return 0;
}

s32 osContGetReadData(OSContPad *pads) {
    goldenpad_mgb64_read_controller_pads(pads);
    return 0;
}

s32 osPfsInit(OSMesgQueue *mq, OSPfs *pfs, s32 channel) {
    (void)mq;
    (void)pfs;
    (void)channel;
    return PFS_ERR_NOPACK;
}

s32 osEepromProbe(OSMesgQueue *mq) {
    (void)mq;
    return EEPROM_TYPE_16K;
}

s32 osEepromLongRead(OSMesgQueue *mq, u8 address, u8 *buffer, s32 nbytes) {
    s32 offset = (s32)address * EEPROM_BLOCK_SIZE;
    (void)mq;
    if (buffer == NULL || nbytes <= 0 || offset < 0 ||
        offset >= GOLDENPAD_EEPROM_SIZE) {
        return 0;
    }
    if (nbytes > GOLDENPAD_EEPROM_SIZE - offset) {
        nbytes = GOLDENPAD_EEPROM_SIZE - offset;
    }
    pthread_mutex_lock(&goldenpad_eeprom_mutex);
    memcpy(buffer, goldenpad_eeprom + offset, (size_t)nbytes);
    pthread_mutex_unlock(&goldenpad_eeprom_mutex);
    return 0;
}

s32 osEepromLongWrite(OSMesgQueue *mq, u8 address, u8 *buffer, s32 nbytes) {
    s32 offset = (s32)address * EEPROM_BLOCK_SIZE;
    (void)mq;
    if (buffer == NULL || nbytes <= 0 || offset < 0 ||
        offset >= GOLDENPAD_EEPROM_SIZE) {
        return 0;
    }
    if (nbytes > GOLDENPAD_EEPROM_SIZE - offset) {
        nbytes = GOLDENPAD_EEPROM_SIZE - offset;
    }
    pthread_mutex_lock(&goldenpad_eeprom_mutex);
    memcpy(goldenpad_eeprom + offset, buffer, (size_t)nbytes);
    atomic_fetch_add(&goldenpad_eeprom_generation, 1);
    pthread_mutex_unlock(&goldenpad_eeprom_mutex);
    return 0;
}

int goldenpad_mgb64_eeprom_load(const u8 *bytes, u32 size) {
    if (bytes == NULL || size != GOLDENPAD_EEPROM_SIZE) {
        return 0;
    }
    pthread_mutex_lock(&goldenpad_eeprom_mutex);
    memcpy(goldenpad_eeprom, bytes, GOLDENPAD_EEPROM_SIZE);
    atomic_store(&goldenpad_eeprom_generation, 0);
    pthread_mutex_unlock(&goldenpad_eeprom_mutex);
    return 1;
}

u32 goldenpad_mgb64_eeprom_snapshot(u8 *bytes, u32 size) {
    u32 generation;
    if (bytes == NULL || size != GOLDENPAD_EEPROM_SIZE) {
        return UINT32_MAX;
    }
    pthread_mutex_lock(&goldenpad_eeprom_mutex);
    memcpy(bytes, goldenpad_eeprom, GOLDENPAD_EEPROM_SIZE);
    generation = atomic_load(&goldenpad_eeprom_generation);
    pthread_mutex_unlock(&goldenpad_eeprom_mutex);
    return generation;
}

s32 osEepromRead(OSMesgQueue *mq, u8 address, u8 *buffer) {
    return osEepromLongRead(mq, address, buffer, EEPROM_BLOCK_SIZE);
}

s32 osEepromWrite(OSMesgQueue *mq, u8 address, u8 *buffer) {
    return osEepromLongWrite(mq, address, buffer, EEPROM_BLOCK_SIZE);
}

s32 osMotorInit(OSMesgQueue *mq, OSPfs *pfs, s32 channel) {
    (void)mq;
    (void)pfs;
    (void)channel;
    return 0;
}
s32 osMotorStart(OSPfs *pfs) { (void)pfs; return 0; }
s32 osMotorStop(OSPfs *pfs) { (void)pfs; return 0; }
void platformRumbleStopAll(void) {}

int goldenpad_mgb64_mobile_os_probe(void) {
    OSMesg storage[1];
    OSMesgQueue queue;
    OSTimer timer = {0};
    OSMesg received = NULL;
    OSMesg expected = (OSMesg)(uintptr_t)0x4750;
    u8 original[EEPROM_BLOCK_SIZE];
    u8 written[EEPROM_BLOCK_SIZE] = {0x47, 0x50, 0x4d, 0x47, 0x42, 0x36, 0x34, 0x21};
    u8 readback[EEPROM_BLOCK_SIZE] = {0};

    osCreateMesgQueue(&queue, storage, 1);
    osSetTimer(&timer, OS_USEC_TO_CYCLES(2000), 0, &queue, expected);
    if (osRecvMesg(&queue, &received, OS_MESG_BLOCK) != 0 || received != expected) {
        osStopTimer(&timer);
        return 0;
    }
    osStopTimer(&timer);

    if (osEepromProbe(NULL) != EEPROM_TYPE_16K ||
        osEepromRead(NULL, 255, original) != 0 ||
        osEepromWrite(NULL, 255, written) != 0 ||
        osEepromRead(NULL, 255, readback) != 0) {
        return 0;
    }
    (void)osEepromWrite(NULL, 255, original);
    return memcmp(written, readback, sizeof(written)) == 0;
}

int goldenpad_mgb64_scheduler_initialize(void) {
    if (goldenpad_scheduler_initialized) {
        return 1;
    }
    osCreateMesgQueue(&gfxFrameMsgQ, gfxFrameMsgBuf, 32);
    osCreateScheduler(&os_scheduler, &shedThread, OS_VI_NTSC_LAN1, 1);
    osScAddClient(&os_scheduler, &gfxClient[0], &gfxFrameMsgQ, NULL);
    sched_cmdQ = osScGetCmdQ(&os_scheduler);
    goldenpad_scheduler_initialized = sched_cmdQ != NULL &&
                                      os_scheduler.clientList == &gfxClient[0] &&
                                      gfxFrameMsgQ.msg == gfxFrameMsgBuf &&
                                      gfxFrameMsgQ.msgCount == 32 &&
                                      os_scheduler.retraceMsg.type == OS_SC_RETRACE_MSG;
    return goldenpad_scheduler_initialized;
}
