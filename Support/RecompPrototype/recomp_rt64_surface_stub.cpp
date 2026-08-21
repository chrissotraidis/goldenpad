#include <algorithm>
#include <cstdint>

extern "C" const char *goldenpad_recomp_rt64_initialize(void *window, void *view) {
    (void)window;
    (void)view;
    return nullptr;
}

extern "C" void goldenpad_recomp_rt64_shutdown() {}

extern "C" void goldenpad_recomp_set_msaa_enabled(int32_t) {}
extern "C" void goldenpad_recomp_set_resolution_mode(int32_t) {}
extern "C" void goldenpad_recomp_set_three_point_filtering(int32_t) {}
extern "C" void goldenpad_recomp_set_controller_state(int32_t, uint32_t, int32_t, int32_t) {}
extern "C" void goldenpad_recomp_set_right_analog(int32_t, int32_t, int32_t) {}
extern "C" void goldenpad_recomp_set_controller_connected(int32_t) {}
extern "C" void goldenpad_recomp_set_two_player_test_mode(int32_t) {}
extern "C" void goldenpad_recomp_set_app_active(int32_t) {}
extern "C" void goldenpad_recomp_note_transient_inactive() {}
extern "C" void goldenpad_recomp_queue_touch_look(int32_t, int32_t, int32_t) {}
extern "C" void goldenpad_recomp_request_crouch_toggle(int32_t) {}
extern "C" void goldenpad_recomp_set_invert_aim_y(int32_t) {}
extern "C" void goldenpad_recomp_set_unlock_all_missions(int32_t) {}
extern "C" void goldenpad_recomp_request_return_to_title() {}
extern "C" int32_t goldenpad_recomp_previous_session_ended_unexpectedly() { return 0; }

extern "C" uint32_t goldenpad_recomp_audio_render(
    float *left, float *right, uint32_t frames) {
    if (left != nullptr) {
        std::fill(left, left + frames, 0.0f);
    }
    if (right != nullptr) {
        std::fill(right, right + frames, 0.0f);
    }
    return 0;
}

extern "C" void goldenpad_recomp_audio_stats(
    uint64_t *queuedFrames, uint64_t *renderedFrames,
    uint64_t *nonzeroSamples, uint64_t *droppedFrames,
    uint64_t *underrunFrames, uint64_t *underrunCallbacks) {
    uint64_t *outputs[] = {
        queuedFrames, renderedFrames, nonzeroSamples,
        droppedFrames, underrunFrames, underrunCallbacks,
    };
    for (uint64_t *output : outputs) {
        if (output != nullptr) {
            *output = 0;
        }
    }
}
