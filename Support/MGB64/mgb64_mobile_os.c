#include <ultra64.h>
#include <sched.h>

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

static void *goldenpad_vi_framebuffer;
static int goldenpad_scheduler_initialized;
static u32 goldenpad_retrace_count;

void osCreateMesgQueue(OSMesgQueue *mq, OSMesg *messages, s32 count) {
    if (mq == NULL) {
        return;
    }
    memset(mq, 0, sizeof(*mq));
    mq->msg = messages;
    mq->msgCount = count;
}

s32 osSendMesg(OSMesgQueue *mq, OSMesg message, s32 flags) {
    (void)flags;
    if (mq == NULL || mq->msg == NULL || mq->msgCount <= 0 ||
        mq->validCount >= mq->msgCount) {
        return -1;
    }
    s32 index = (mq->first + mq->validCount) % mq->msgCount;
    mq->msg[index] = message;
    mq->validCount++;
    return 0;
}

static s32 goldenpad_mgb64_take_message(OSMesgQueue *mq, OSMesg *message) {
    if (mq == NULL || mq->validCount <= 0) {
        return -1;
    }
    if (message != NULL) {
        *message = mq->msg[mq->first];
    }
    mq->first = (mq->first + 1) % mq->msgCount;
    mq->validCount--;
    return 0;
}

int goldenpad_mgb64_deliver_retrace(void) {
    OSScClient *client;
    if (!goldenpad_scheduler_initialized || gfxFrameMsgQ.validCount != 0) {
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

s32 osRecvMesg(OSMesgQueue *mq, OSMesg *message, s32 flags) {
    if (goldenpad_mgb64_take_message(mq, message) == 0) {
        return 0;
    }
    if (flags == OS_MESG_NOBLOCK || mq != &gfxFrameMsgQ) {
        return -1;
    }

    /* Temporary cadence fallback until MTKView drives this callback directly. */
    struct timespec period = {0, 16666667L};
    nanosleep(&period, NULL);
    (void)goldenpad_mgb64_deliver_retrace();
    return goldenpad_mgb64_take_message(mq, message);
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

s32 osContInit(OSMesgQueue *mq, u8 *bitpattern, OSContStatus *status) {
    if (bitpattern != NULL) {
        *bitpattern = 1;
    }
    goldenpad_mgb64_neutral_controller_status(status);
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
    goldenpad_mgb64_neutral_controller_status(status);
    return 0;
}

s32 osContGetReadData(OSContPad *pads) {
    if (pads != NULL) {
        memset(pads, 0, sizeof(*pads) * MAXCONTROLLERS);
    }
    return 0;
}

s32 osPfsInit(OSMesgQueue *mq, OSPfs *pfs, s32 channel) {
    (void)mq;
    (void)pfs;
    (void)channel;
    return PFS_ERR_NOPACK;
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

/* These are link seams only until the AVAudio bridge owns sequence output. */
s32 portAudioGetMusicBusVolumeQ15(void) { return 32767; }
void alCSPStop(ALCSPlayer *player) { (void)player; }
void alCSPSetVol(ALCSPlayer *player, s16 volume) {
    (void)player;
    (void)volume;
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
