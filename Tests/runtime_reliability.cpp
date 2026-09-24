#include <array>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include "ultramodern/ultramodern.hpp"
#include "recomp.h"

extern "C" void osContGetReadData_recomp(uint8_t*, recomp_context*);

// Exercise the real runtime queue/input code with an idle scheduler. A test
// that accidentally blocks or schedules a thread fails instead of hanging.
static bool game_thread = true;
namespace ultramodern {
bool is_game_thread() { return game_thread; }
void check_running_queue(uint8_t*) {}
bool thread_queue_empty(uint8_t*, int32_t) { return true; }
void thread_queue_insert(uint8_t*, int32_t, int32_t) { std::abort(); }
int32_t thread_queue_pop(uint8_t*, int32_t) { std::abort(); }
void schedule_running_thread(uint8_t*, int32_t) { std::abort(); }
void run_next_thread_and_wait(uint8_t*) { std::abort(); }
int32_t this_thread() { return 0; }
void send_si_message(uint8_t*) {}
}

static int failures = 0;
static void check(bool ok, const char* name) {
    std::printf("%s: %s\n", ok ? "PASS" : "FAIL", name);
    failures += !ok;
}
static uint8_t connected = 1;
static ultramodern::input::connected_device_info_t device(int port) {
    using namespace ultramodern::input;
    return {connected & (1 << port) ? Device::Controller : Device::None, Pak::None};
}
static bool input(int port, uint16_t* buttons, float* x, float* y) {
    if (!(connected & (1 << port))) return false;
    *buttons = 0x8000 | port;
    *x = 0.5f;
    *y = -0.5f;
    return true;
}

int main() {
    alignas(16) std::array<uint8_t, 0x10000> memory{};
    uint8_t* rdram = memory.data();
    constexpr int32_t status = static_cast<int32_t>(0x80001000u);
    constexpr int32_t pads = static_cast<int32_t>(0x80002000u);
    ultramodern::input::callbacks_t callbacks{};
    callbacks.get_connected_device_info = device;
    callbacks.get_input = input;
    ultramodern::input::set_callbacks(callbacks);
    bool masks_ok = true;
    for (connected = 0; connected < 16; ++connected) {
        uint8_t pattern = 0;
        osContInit(rdram, 0, &pattern, status);
        masks_ok &= pattern == connected;
    }
    check(masks_ok, "all 16 controller connection masks");

    recomp_context ctx{};
    ctx.r4 = pads;
    connected = 1;
    osContGetReadData_recomp(rdram, &ctx);
    const uint16_t old_buttons = MEM_H(0, pads);
    const int8_t old_x = MEM_B(2, pads), old_y = MEM_B(3, pads);
    connected = 0;
    osContGetReadData_recomp(rdram, &ctx);
    check(MEM_B(4, pads) == 8 && static_cast<uint16_t>(MEM_H(0, pads)) == old_buttons &&
        MEM_B(2, pads) == old_x && MEM_B(3, pads) == old_y,
        "disconnect reports no response and preserves previous pad values");
    connected = 1;
    osContGetReadData_recomp(rdram, &ctx);
    check(MEM_B(4, pads) == 0 && static_cast<uint16_t>(MEM_H(0, pads)) == 0x8000,
        "reconnect publishes valid input and clears error");
    connected = 15;
    osContGetReadData_recomp(rdram, &ctx);
    std::array<uint8_t, 32> saved{};
    std::memcpy(saved.data(), TO_PTR(uint8_t, pads), saved.size());
    osContSetCh(rdram, 0);
    osContGetReadData_recomp(rdram, &ctx);
    check(std::memcmp(saved.data(), TO_PTR(uint8_t, pads), saved.size()) == 0,
        "zero poll channels leaves all controller records untouched");
    osContSetCh(rdram, 1);
    connected = 0;
    osContGetReadData_recomp(rdram, &ctx);
    bool unpolled_ok = MEM_B(4, pads) == 8;
    for (int port = 1; port < 4; ++port) {
        unpolled_ok &= MEM_B(6 * port + 4, pads) == 0 &&
            static_cast<uint16_t>(MEM_H(6 * port, pads)) == (0x8000 | port);
    }
    check(unpolled_ok, "limited poll updates only active channels");

    constexpr int32_t queue_a = static_cast<int32_t>(0x80003000u);
    constexpr int32_t queue_b = static_cast<int32_t>(0x80003100u);
    constexpr int32_t buffer_a = static_cast<int32_t>(0x80004000u);
    constexpr int32_t buffer_b = static_cast<int32_t>(0x80004100u);
    constexpr int32_t output = static_cast<int32_t>(0x80005000u);
    osCreateMesgQueue(rdram, queue_a, buffer_a, 1);
    osCreateMesgQueue(rdram, queue_b, buffer_b, 1);
    osSendMesg(rdram, queue_a, 10, OS_MESG_NOBLOCK);
    game_thread = false;
    osSendMesg(rdram, queue_a, 11, OS_MESG_NOBLOCK);
    osSendMesg(rdram, queue_b, 20, OS_MESG_NOBLOCK);
    game_thread = true;
    check(osRecvMesg(rdram, queue_b, output, OS_MESG_NOBLOCK) == 0 &&
        *TO_PTR(OSMesg, output) == 20,
        "full queue A does not block completion delivery to queue B");
    check(osRecvMesg(rdram, queue_a, output, OS_MESG_NOBLOCK) == 0 &&
        *TO_PTR(OSMesg, output) == 10,
        "full queue retains original message");
    check(osRecvMesg(rdram, queue_a, output, OS_MESG_NOBLOCK) == 0 &&
        *TO_PTR(OSMesg, output) == 11,
        "deferred completion survives a full queue");

    osSendMesg(rdram, queue_a, 30, OS_MESG_NOBLOCK);
    for (int i = 0; i < 1000; ++i) {
        ultramodern::enqueue_external_message(queue_a, 99, false, false);
    }
    ultramodern::enqueue_external_message(queue_a, 31, false, true);
    ultramodern::enqueue_external_message(queue_a, 32, false, true);
    ultramodern::enqueue_external_message(queue_b, 40, false, true);
    ultramodern::wait_for_external_message_timed(rdram, 1);
    check(osRecvMesg(rdram, queue_b, output, OS_MESG_NOBLOCK) == 0 &&
        *TO_PTR(OSMesg, output) == 40,
        "retrace burst cannot block another queue during timed wait");
    bool ordered = true;
    for (int expected : {30, 31, 32}) {
        ordered &= osRecvMesg(rdram, queue_a, output, OS_MESG_NOBLOCK) == 0 &&
            *TO_PTR(OSMesg, output) == expected;
    }
    check(ordered && osRecvMesg(rdram, queue_a, output, OS_MESG_NOBLOCK) == -1,
        "retrace backlog expires; reliable completions retain order without duplicates");
    ultramodern::enqueue_external_message(queue_b, 41, false, true);
    ultramodern::wait_for_external_message(rdram);
    check(osRecvMesg(rdram, queue_b, output, OS_MESG_NOBLOCK) == 0 &&
        *TO_PTR(OSMesg, output) == 41,
        "external wait delivers queued completion");
    return failures ? 1 : 0;
}
