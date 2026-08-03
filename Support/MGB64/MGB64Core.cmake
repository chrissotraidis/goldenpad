set(GOLDENPAD_MGB64_COMMIT "cd9b58f5f91291579b8e551aa925aab000d311cf")

if(NOT GOLDENPAD_MGB64_SOURCE_DIR)
    return()
endif()

if(NOT EXISTS "${GOLDENPAD_MGB64_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "GOLDENPAD_MGB64_SOURCE_DIR is not an MGB64 checkout")
endif()

execute_process(
    COMMAND git -C "${GOLDENPAD_MGB64_SOURCE_DIR}" rev-parse HEAD
    OUTPUT_VARIABLE goldenpad_mgb64_actual_commit
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE goldenpad_mgb64_git_result
)
if(NOT goldenpad_mgb64_git_result EQUAL 0 OR
   NOT goldenpad_mgb64_actual_commit STREQUAL GOLDENPAD_MGB64_COMMIT)
    message(FATAL_ERROR
        "MGB64 must be pinned at ${GOLDENPAD_MGB64_COMMIT}; got ${goldenpad_mgb64_actual_commit}")
endif()

file(GLOB goldenpad_mgb64_game_sources CONFIGURE_DEPENDS
    "${GOLDENPAD_MGB64_SOURCE_DIR}/src/game/*.c")

set(goldenpad_mgb64_system_sources
    src/boss.c
    src/init.c
    src/memp.c
    src/mema.c
    src/sched.c
    src/fr.c
    src/vi.c
    src/joy.c
    src/music.c
    src/snd.c
    src/deb.c
    src/debugmenu.c
    src/speed_graph.c
    src/random.c
    src/token.c
    src/ramrom.c
    src/crash.c
    src/cfb.c
    src/stacks.c
    src/rmon.c
    src/pi.c
    src/tlb_manage.c
    src/tlb_random.c
    src/c_data_filler.c
    src/platform/rom_offsets.c
    src/platform/asset_stubs.c
    assets/font_dl.c
    assets/GlobalImageTable.c
)

set(goldenpad_mgb64_portable_leaf_sources
    src/platform/aimbone_dispatch.c
    src/platform/ammo_icon_anchor.c
    src/platform/autoaim_score.c
    src/platform/bg_impact_guard.c
    src/platform/chrobj_detonate.c
    src/platform/chrobj_impact_suppress.c
    src/platform/fire_rate_authentic.c
    src/platform/fp_weapon_perspnorm.c
    src/platform/frame_clamp.c
    src/platform/glass_shot_depth.c
    src/platform/gu_trig.c
    src/platform/hull_vertex_clamp.c
    src/platform/mp_beam_rawcast.c
    src/platform/mp_healthbar_gate.c
    src/platform/mp_respawn_tail.c
    src/platform/platform_stdio.c
    src/platform/projectile_endpoint_clamp.c
    src/platform/segment_stubs.c
    src/platform/spectrum_settile.c
    src/platform/stan_roomset.c
    src/platform/watch_ammo_switchstate.c
    src/platform/watch_inv_aspect.c
    src/platform/watch_joypad_page.c
    src/platform/watch_scene_render.c
    src/platform/watch_scroll_gate.c
    src/platform/watchmenu_hand_lifecycle.c
    src/platform/weapon_bullet_type.c
    src/platform/weapon_cycle_queue.c
)

set(goldenpad_mgb64_portable_service_sources
    src/app/cli_stage_tables.c
    src/platform/model_convert.c
    src/platform/radial_deadzone.c
    src/platform/setup_pnames.c
    src/platform/weapon_action_sfx.c
)
list(TRANSFORM goldenpad_mgb64_system_sources
    PREPEND "${GOLDENPAD_MGB64_SOURCE_DIR}/")
list(TRANSFORM goldenpad_mgb64_portable_leaf_sources
    PREPEND "${GOLDENPAD_MGB64_SOURCE_DIR}/")
list(TRANSFORM goldenpad_mgb64_portable_service_sources
    PREPEND "${GOLDENPAD_MGB64_SOURCE_DIR}/")

foreach(goldenpad_mgb64_source IN LISTS
        goldenpad_mgb64_game_sources goldenpad_mgb64_system_sources
        goldenpad_mgb64_portable_leaf_sources
        goldenpad_mgb64_portable_service_sources)
    if(goldenpad_mgb64_source MATCHES "/src/libultra(re)?/")
        message(FATAL_ERROR
            "SDK-lineage implementation source entered MGB64 core: ${goldenpad_mgb64_source}")
    endif()
endforeach()

function(goldenpad_configure_mgb64_target target)
    target_compile_definitions(${target} PRIVATE
        NONMATCHING
        NATIVE_PORT
        PORT_FIXME_STUBS
        _LANGUAGE_C
        VERSION_US
        LANG_US
        REFRESH_NTSC
        LEFTOVERDEBUG
        LEFTOVERSPECTRUM
        BUGFIX_R0
        BYTEMATCH
    )

    target_include_directories(${target} PRIVATE
        "${GOLDENPAD_MGB64_SOURCE_DIR}/include"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/include/PR"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/src"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/src/game"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/fast3d"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/src/libultra/audio"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/assets"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/lib/stb"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/lib/cgltf"
        "${GOLDENPAD_MGB64_SOURCE_DIR}"
    )

    target_compile_options(${target} PRIVATE
        -Wall
        -Wno-unused-variable
        -Wno-unused-function
        -Wno-unused-but-set-variable
        -Wno-missing-braces
        -Wno-parentheses
        -Wno-unknown-pragmas
        -Wno-implicit-function-declaration
        -Wno-missing-declarations
        -Wno-int-conversion
        -Wno-incompatible-pointer-types
        -Wno-empty-body
        -Wno-switch
        -Wno-macro-redefined
        -Wno-initializer-overrides
        -Wno-flexible-array-extensions
        -Wno-gnu-flexible-array-initializer
        -Wno-invalid-token-paste
        -Wno-microsoft-anon-tag
        -fms-extensions
        -fno-strict-aliasing
        -ferror-limit=0
    )
endfunction()

add_library(goldenpad_mgb64_core STATIC
    ${goldenpad_mgb64_game_sources}
    ${goldenpad_mgb64_system_sources}
    ${goldenpad_mgb64_portable_leaf_sources}
    ${goldenpad_mgb64_portable_service_sources}
    Support/MGB64/mgb64_mobile_config.c
    Support/MGB64/mgb64_mobile_gu.c
    Support/MGB64/mgb64_mobile_legacy_data.c
    Support/MGB64/mgb64_mobile_os.c
)
goldenpad_configure_mgb64_target(goldenpad_mgb64_core)
target_include_directories(goldenpad_mgb64_core BEFORE PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/Support/MGB64/CoreSDLShim")

add_library(goldenpad_mgb64_metal STATIC
    "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/fast3d/gfx_metal.mm"
    "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/fast3d/gfx_cc.c"
    "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/fast3d/gfx_backend.c"
    "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/fast3d/gfx_msaa_util.c"
)
goldenpad_configure_mgb64_target(goldenpad_mgb64_metal)
set_source_files_properties(
    "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/fast3d/gfx_metal.mm"
    PROPERTIES COMPILE_OPTIONS "-fobjc-arc")

add_library(goldenpad_mgb64_fast3d STATIC
    "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/fast3d/gfx_pc.c"
    "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/fast3d/gfx_room_normals.c"
)
goldenpad_configure_mgb64_target(goldenpad_mgb64_fast3d)
target_compile_definitions(goldenpad_mgb64_fast3d PRIVATE
    MGB64_APPLE_MOBILE)
target_include_directories(goldenpad_mgb64_fast3d BEFORE PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/Support/MGB64/MobileRendererShim")

target_compile_definitions(GoldenPad PRIVATE
    GOLDENPAD_MGB64_CORE
    GOLDENPAD_MGB64_COMMIT="${GOLDENPAD_MGB64_COMMIT}"
)
target_link_libraries(GoldenPad PRIVATE goldenpad_mgb64_core)

if(GOLDENPAD_MGB64_RENDERER)
    set_source_files_properties(
        Support/MGB64/mgb64_renderer_bridge.c
        PROPERTIES INCLUDE_DIRECTORIES
        "${GOLDENPAD_MGB64_SOURCE_DIR}/include;${GOLDENPAD_MGB64_SOURCE_DIR}/include/PR")
    target_sources(GoldenPad PRIVATE
        Support/MGB64/mgb64_renderer_defaults.c
        "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/port_env.c")
    target_include_directories(GoldenPad PRIVATE
        "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform"
        "${GOLDENPAD_MGB64_SOURCE_DIR}/src/platform/fast3d")
    target_compile_definitions(GoldenPad PRIVATE GOLDENPAD_MGB64_RENDERER)
    target_link_libraries(GoldenPad PRIVATE
        goldenpad_mgb64_fast3d
        goldenpad_mgb64_metal)
endif()
