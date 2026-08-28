#include <algorithm>
#include <cstdint>

#if !defined(GOLDENPAD_RECOMP_RT64_INIT_EXTERNAL)
extern "C" const char *goldenpad_recomp_rt64_initialize(void *window, void *view) {
    (void)window;
    (void)view;
    return nullptr;
}

extern "C" void goldenpad_recomp_rt64_shutdown() {}
#endif

extern "C" void goldenpad_recomp_set_msaa_enabled(int32_t) {}
extern "C" void goldenpad_recomp_set_resolution_mode(int32_t) {}
extern "C" void goldenpad_recomp_set_three_point_filtering(int32_t) {}
extern "C" void goldenpad_recomp_set_controller_state(int32_t, uint32_t, int32_t, int32_t) {}
extern "C" void goldenpad_recomp_set_right_analog(int32_t, int32_t, int32_t) {}
extern "C" void goldenpad_recomp_set_controller_connected(int32_t) {}
extern "C" void goldenpad_recomp_set_two_player_test_mode(int32_t) {}
extern "C" void goldenpad_recomp_set_four_player_test_mode(int32_t) {}
extern "C" void goldenpad_recomp_set_fire_rate_probe_enabled(int32_t) {}
extern "C" void goldenpad_recomp_set_sidestep_probe_enabled(int32_t) {}
extern "C" void goldenpad_recomp_set_lifecycle_probe_enabled(int32_t) {}
extern "C" void goldenpad_recomp_set_audio_probe_enabled(int32_t) {}
extern "C" void goldenpad_recomp_set_depth_rebuild_probe_enabled(int32_t) {}
extern "C" void goldenpad_recomp_netplay_configure(int32_t, int32_t, uint64_t) {}
extern "C" void goldenpad_recomp_netplay_submit_frame(uint64_t, const uint8_t *, int32_t) {}
extern "C" void goldenpad_recomp_netplay_status(
    uint64_t *consumed, uint64_t *received, uint64_t *missing,
    uint64_t *checksumFrame, uint64_t *checksum) {
    uint64_t *outputs[] = {consumed, received, missing, checksumFrame, checksum};
    for (uint64_t *output : outputs) {
        if (output != nullptr) { *output = 0; }
    }
}
extern "C" int32_t goldenpad_recomp_netplay_match_active() { return 0; }
extern "C" void goldenpad_recomp_netplay_pause() {}
extern "C" void goldenpad_recomp_performance_counters(
    uint64_t *displayLists, uint64_t *screenUpdates,
    uint64_t *presented, uint64_t *vis) {
    uint64_t *outputs[] = {displayLists, screenUpdates, presented, vis};
    for (uint64_t *output : outputs) {
        if (output != nullptr) { *output = 0; }
    }
}
extern "C" void goldenpad_recomp_note_audio_host_rates(uint32_t, uint32_t, uint32_t) {}
extern "C" int32_t goldenpad_recomp_frontend_input_active() { return 1; }
extern "C" int32_t goldenpad_recomp_gameplay_input_active() { return 0; }
extern "C" void goldenpad_recomp_get_input_context(
    int32_t, int32_t *gameplay, int32_t *style, int32_t *aiming,
    int32_t *tankState, int32_t *nativeLookUpright) {
    if (gameplay != nullptr) { *gameplay = 0; }
    if (style != nullptr) { *style = -1; }
    if (aiming != nullptr) { *aiming = 0; }
    if (tankState != nullptr) { *tankState = -1; }
    if (nativeLookUpright != nullptr) { *nativeLookUpright = 0; }
}
extern "C" void goldenpad_recomp_set_app_active(int32_t) {}
extern "C" void goldenpad_recomp_note_transient_inactive() {}
extern "C" void goldenpad_recomp_queue_touch_look(int32_t, int32_t, int32_t) {}
extern "C" void goldenpad_recomp_queue_mouse_look(int32_t, int64_t, int64_t) {}
extern "C" void goldenpad_recomp_set_mouse_camera_aim_active(int32_t, int32_t) {}
extern "C" void goldenpad_recomp_request_crouch_toggle(int32_t) {}
extern "C" void goldenpad_recomp_request_inventory_slot(int32_t, int32_t) {}
extern "C" void goldenpad_recomp_request_reload(int32_t) {}
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
