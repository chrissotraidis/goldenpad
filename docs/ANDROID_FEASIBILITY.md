# GoldenPad Android feasibility and shared-platform plan

- **Assessment date:** 2026-08-22
- **GoldenPad source assessed:** `13c07bacf5645ac8fe2addd6613f264d874498c1`
- **GoldenEye64Recomp reference:** `a787fe0d95e8278fcba5ba2d768fa6a606e75f55` plus GoldenPad's maintained patches
- **Accepted N64ModernRuntime build reference:** `e75e0de77e8377d4954fe7b511c0d1cf608e7ded` plus `patches/n64modernruntime-ios-aot.patch`
- **RT64 reference:** `5473732a822a4423b5696e7cb18fecc425a59875`
- **Plume reference:** `d890ac899e505fb30040e037a4037cdeca68f033`
- **Assessment type:** source, architecture, and current upstream documentation review
- **Evidence boundary:** no Android NDK build, APK, installation, Vulkan frame, audio playback, input, or gameplay run was performed

## Executive verdict

GoldenPad is a credible candidate for a native Android port. The game should
not be rewritten in Kotlin and does not need Kotlin/Native. The generated
GoldenEye code, N64ModernRuntime, GoldenPad's runtime bridge, and RT64 remain
native C/C++ compiled ahead of time by the Android NDK. Kotlin owns only the
Android product shell and communicates with the native runtime through a small
JNI/C boundary.

The port is not a build-target toggle. GoldenPad's primary target is currently
an Apple bundle, the product UI and device services are Swift, RT64 does not
officially list Android as a supported product platform, and the upstream
GoldenEye/RT64 window path contains explicit Android `Unimplemented` branches.
The positive counterweight is substantial: RT64's Plume Vulkan layer already
defines Android render windows as `ANativeWindow*`, creates
`VK_KHR_android_surface`, and reads Android surface dimensions. The game and
runtime already converge on narrow input, audio, renderer, filesystem, and
lifecycle seams.

The recommended product architecture is one GoldenPad runtime with several
thin hosts, not independent Apple, Android, and Linux ports:

```text
                    Shared GoldenPad runtime
  GoldenEye AOT + game patches + N64ModernRuntime + RT64 policy
       ROM/import + saves + input semantics + audio ring + diagnostics
                              |
             +----------------+----------------+
             |                |                |
             v                v                v
       Apple host        Android host       SDL desktop host
   SwiftUI/AppKit/UIKit  Kotlin/GameActivity SDL2 initially
   Metal/CAMetalLayer    Vulkan/ANativeWindow Vulkan/SDL window
   AVAudioEngine         Oboe/AAudio          SDL audio
```

A gameplay, ROM, save, controller-semantics, multiplayer, diagnostics, or
renderer-policy repair should land in the shared runtime or shared game patch
first. Platform branches should contain only the operating-system code required
to expose a surface, files, audio device, input events, lifecycle, UI, and
logging. API-specific renderer defects remain backend-specific, but every
backend should run the same feature contract and acceptance scenarios.

Estimated cumulative effort for one experienced Android NDK/C++/Vulkan
engineer working full time on the recommended shared-runtime route:

| Outcome | Estimated effort | What it proves |
| --- | ---: | --- |
| Shared host contract with Apple regression gates | 2-4 weeks | Existing iPhone/iPad and Mac products use a documented common native boundary without changing accepted behavior |
| Android foreground technical proof | 6-10 weeks | An `arm64-v8a` APK imports the supported ROM, initializes real RT64/Vulkan, renders title/Dam, produces audio, and accepts one controller on physical hardware |
| Usable Android alpha | 12-20 weeks | Touch, settings, saves, audio focus, controller reconnect, background/foreground, and surface recreation work on representative phone and tablet hardware |
| Android release quality | 20-32 person-weeks | Reproducible AAB/APK packaging, 16 KB native libraries, broad GPU/controller testing, accessibility, update preservation, legal/source delivery, and audits are complete |
| First Linux GoldenPad host after shared extraction | Add 3-6 weeks | The same runtime launches through an SDL/Vulkan desktop shell without a separate game fork |

These are planning ranges, not promises or Android runtime evidence. A developer
learning JNI, Gradle, GameActivity, Android Vulkan, or RT64 internals during the
port should add roughly 30-50 percent. Two engineers can parallelize the product
shell and native runtime, but surface/renderer debugging and physical acceptance
will remain partly sequential.

## Goals

1. Build the current primary N64Recomp/N64ModernRuntime/RT64 product for
   Android `arm64-v8a` without introducing a JIT or emulator wrapper.
2. Keep one source of truth for game patches, input semantics, graphics
   settings, ROM validation, saves, audio production, diagnostics, and feature
   flags.
3. Preserve the accepted Apple builds while extracting the common runtime.
4. Make a future Linux host incremental after Android, not another port from
   scratch.
5. Keep the application data-free: users provide the supported original ROM,
   which is converted and validated privately on their device.
6. Establish explicit gates that distinguish compilation, loading, rendering,
   gameplay, lifecycle, performance, and release quality.

## Non-goals

- Do not rewrite GoldenEye, N64ModernRuntime, or RT64 in Kotlin.
- Do not use Kotlin/Native for the game core.
- Do not add an Android-only gameplay fork.
- Do not move the MGB64 Legacy runtime to Android as part of the primary plan.
- Do not solve network multiplayer while establishing the Android platform.
- Do not claim the current experimental four-player rendering is complete
  controller or multiplayer parity on Android.
- Do not broaden the first proof to `armeabi-v7a`, x86, x86_64, Chromebooks,
  Android TV, Google Play Games on PC, or every Vulkan-capable device.
- Do not refactor the entire repository before the first physical Vulkan gate.

## Current source findings

### The primary game/runtime is already native and ahead of time

The primary target gathers generated `RecompiledFuncs/*.c`, generated patch
code, the GoldenEye RSP audio microcode implementation, N64ModernRuntime
archives, GoldenPad's native runtime bridge, and GoldenEye's RT64 render
context. The current generated game is approximately 766,000 lines split across
60 C translation units, but that is a compiler/build-size concern rather than
code that must be rewritten for Android.

Android NDK Clang is expected to compile this C/C++ for `arm64-v8a`; that has
not yet been tested in this repository. Generation remains a host-side build
step. The Android device executes the compiled ARM64 code and must not generate
or download executable game code at runtime.

`patches/n64modernruntime-ios-aot.patch` already provides the important
mobile-safe policy: disable the SLJIT live-recompiler path, retain the static
mod/runtime ABI through AOT shims, and canonicalize guest RDRAM addresses. Most
of that patch is platform-neutral despite its current filename.

### The native host seam is useful but undocumented

`Support/RecompPrototype/recomp_game_start.cpp` already exports functions for:

- runtime launch and ROM validation;
- resolution, MSAA, filtering, and game flags;
- up to four controller snapshots;
- right-stick and accumulated touch-look input;
- crouch and return-to-title actions;
- lifecycle state;
- runtime status and health counters; and
- PCM audio rendering and underrun statistics.

Swift currently imports these symbols with `_silgen_name`. Android JNI can call
the same native functions, but the project should first place the supported
surface in a real C header with versioned structs and documented ownership.
That header becomes the host contract for Swift, Kotlin/JNI, and an SDL desktop
shell.

### ROM conversion is portable

`Support/RecompPrototype/recomp_rom_import.cpp` is bounded C++ filesystem code.
It accepts common N64 byte orders, requires the exact supported retail hash,
applies the pinned GEP1 conversion, validates the exact TLB-free result, clears
sensitive buffers, and writes only the requested output path.

The Android picker returns a content URI rather than a normal path. Kotlin
should stream the selected URI into an app-private staging file, then invoke
the existing native importer. The runtime should never play directly from a
provider URI or depend on a cloud provider remaining mounted.

### Audio production is already shared

The game/runtime produces 22.05 kHz interleaved stereo PCM into a bounded native
ring. Apple consumes it with `AVAudioSourceNode`. Android can consume the same
ring with an Oboe data callback and use Oboe's resampler when the device's
native stream rate is 48 kHz. The producer, channel-order repair, prebuffer,
fade, dropped-frame counters, and underrun counters remain shared.

### The current product host is substantial

The primary iPhone/iPad host is approximately 2,500 lines of Swift across app
state/settings, audio, controller/touch input, Metal hosting, ROM setup, and the
editable touch layout. The behavior should be reproduced, not translated line
by line. UIKit, SwiftUI, MetalKit, GameController, AVFAudio, and `UserDefaults`
do not enter the Android build.

The largest opportunity for cross-platform value is input policy. Today the
Swift host owns N64 button mapping, dead zone, response curve, classic versus
analog right-stick behavior, touch accumulation, and Player 1/2 routing. Those
policies should move behind the shared runtime contract after baseline tests
freeze the current Apple behavior. Platform hosts should collect raw device
events and semantic actions, not independently reinvent GoldenEye controls.

### The repository is Apple-only at the top level

The root `CMakeLists.txt` declares Swift, C, C++, and Objective-C++ and rejects
any system other than iOS or the explicit Apple-Silicon Mac target. The Android
port needs a Gradle application and an NDK CMake shared-library target. It
should consume a common CMake source fragment rather than force the Android
toolchain through the Apple bundle branches.

### Dependency identity needs one accepted source of truth

The checked-out N64ModernRuntime research reference is newer than the runtime
used by the accepted mobile and Mac builds. The accepted build caches and Mac
dependency script use `e75e0de77e8377d4954fe7b511c0d1cf608e7ded`, while
`docs/RT64_N64RECOMP_PROTOTYPE.md` also records the later research checkout
`589bbf018a3e6d3646ddf7de1e7919f1b7e99bb1`.

Android work must start from the accepted `e75e0d` runtime plus the exact AOT
patch and advance all platforms together only after the common tests pass. It
must not quietly build Android against one runtime revision while Apple ships
another.

## Renderer feasibility

### What already exists

RT64's Plume RHI contains real Android Vulkan substrate at the assessed pin:

- Android `RenderWindow` is `ANativeWindow*`;
- `VkAndroidSurfaceCreateInfoKHR` is populated with that window;
- `vkCreateAndroidSurfaceKHR` creates the presentation surface;
- `ANativeWindow_getWidth/Height` supplies swapchain dimensions;
- Android is excluded from the desktop SDL link at the final RT64 link step;
  and
- RT64 includes an Android CMake variant targeting `arm64-v8a` and API 24.

This makes the first renderer task an integration/validation project, not a
new Vulkan backend.

### What is still explicitly missing

The higher layers are incomplete:

1. N64ModernRuntime includes `<android/native_window.h>` but currently aliases
   Android `WindowHandle` to `SDL_Window*` alongside Linux and has a TODO for a
   native Android handle.
2. GoldenEye64Recomp's `create_window` branch is an Android compile-time
   `Unimplemented` assertion.
3. GoldenEye64Recomp's RT64 context is also an Android `Unimplemented`
   assertion where it should assign the supplied native window into
   `RT64::Application::Core`.
4. RT64's desktop `ApplicationWindow` has Android `Unimplemented` branches.
   GoldenPad's existing embedded-host patch avoids the desktop owner for Apple;
   it should become a renderer-agnostic embedded-host option with small Apple
   and Android surface implementations.
5. GoldenPad hardcodes `GraphicsApi::Metal` and Apple logging/data paths in the
   otherwise portable runtime bridge.
6. RT64 skips the final SDL link on Android but still discovers SDL during
   configuration. The embedded Android build must remove that unused desktop
   configure dependency rather than provision SDL only to satisfy CMake.

### Initial surface versus replaceable surface

Plume can create an initial Vulkan surface, but that does not prove Android
lifecycle correctness. `VulkanSwapChain` stores its original render-window
descriptor and `resize()` reuses it. Android may destroy and replace the
`ANativeWindow` when the app backgrounds, rotates, changes configuration, or
recreates its Activity.

The Android plan therefore has two separate renderer gates:

1. **Initial-surface gate:** a valid physical `ANativeWindow` creates a Vulkan
   surface/swapchain and renders real GoldenEye frames continuously in the
   foreground.
2. **Replacement-surface gate:** presentation stops before the old window is
   released, RT64 destroys or replaces every surface-dependent object, a new
   window is attached, the swapchain is recreated, and the existing simulation
   resumes without a duplicate runtime, stale window access, save loss, or
   audio/input latch.

A release-quality Android port cannot work around the second gate by merely
killing the process whenever the surface disappears.

### Recommended graphics floor

The first product profile should be deliberately narrow:

| Setting | Initial decision |
| --- | --- |
| ABI | `arm64-v8a` only |
| Minimum Android | Android 10 / API 29 |
| Graphics API | Vulkan only |
| Vulkan floor | Vulkan 1.1 plus the Android 2022 baseline profile where available |
| Presentation rate | GoldenEye original rate first; no HFR/interpolation gate |
| Internal resolution | 1x or 2x proof, then Auto after thermal/performance evidence |
| MSAA | Off for first frame, then 2x after capability validation |
| Orientation | Landscape only for the first proof |
| First GPU families | One recent Adreno device and one recent Mali/Google Tensor or Samsung-class device |

RT64's CMake API-24 value shows that an NDK configuration was contemplated; it
does not prove product support on every Android 7 device. Google's current
native-engine guidance recommends Android 10, Vulkan 1.1, and a baseline
profile for a practical modern Vulkan floor.

Android Frame Pacing/Swappy and Vulkan pre-rotation should be evaluated after
RT64's ordinary presentation is correct. They should not be inserted before a
measured cadence or rotation defect identifies the need, because Swappy takes
ownership of parts of queue presentation and would widen the first debugging
surface.

## One shared runtime, several platform hosts

### Shared ownership rule

Code belongs in the shared runtime when changing it should alter game behavior
on every platform. Code belongs in a platform host only when it talks to an OS
API or renders platform-native UI.

| Concern | Shared runtime | Platform host |
| --- | --- | --- |
| Generated game/AOT and game patches | Yes | No |
| N64ModernRuntime/librecomp/RSP | Yes | No |
| ROM byte-order conversion, GEP1 application, exact hashes | Yes | Picker streams URI/file into staging |
| Save format, backup rules, flush requests | Yes | Chooses private durable directory and lifecycle moments |
| Semantic action to N64 mapping | Yes | Collects device/touch events and preferences |
| Dead zone, response curve, right-stick mode | Yes | UI exposes settings |
| Relative touch-look accumulation | Yes | UI reports normalized deltas |
| Multiplayer player/port rules | Yes | Enumerates physical devices and reports connection identity |
| PCM production/ring/counters | Yes | AVAudioEngine, Oboe, or SDL consumes PCM |
| Graphics options and game-facing renderer policy | Yes | Selects Metal or Vulkan and supplies a native surface |
| RT64 game/display-list fixes | Yes | No |
| Metal, Vulkan, or driver-specific backend repair | Backend-specific | Host supplies capability and lifecycle information |
| Diagnostics schema and health counters | Yes | OS logger and share/export UI |
| File picker, permissions, paths, share sheet | No | Yes |
| Touch-control visuals and accessibility nodes | Behavior/schema shared | Native Swift/Kotlin UI implementation |
| Surface/window ownership | No | Yes |

### Proposed host contract

Add a small C header, for example `include/goldenpad/runtime.h`. The exact API
should be implemented only after tests cover the existing symbols, but its
shape should remain narrow:

```c
typedef int32_t GoldenPadResult;

typedef enum GoldenPadGraphicsAPI {
    GOLDENPAD_GRAPHICS_METAL,
    GOLDENPAD_GRAPHICS_VULKAN
} GoldenPadGraphicsAPI;

typedef enum GoldenPadSurfaceKind {
    GOLDENPAD_SURFACE_APPLE,
    GOLDENPAD_SURFACE_ANDROID,
    GOLDENPAD_SURFACE_SDL
} GoldenPadSurfaceKind;

typedef struct GoldenPadPaths {
    const char *rom;
    const char *data;
    const char *cache;
    const char *logs;
} GoldenPadPaths;

typedef struct GoldenPadRuntimeConfig {
    uint32_t abi_version;
    GoldenPadGraphicsAPI graphics;
    GoldenPadPaths paths;
} GoldenPadRuntimeConfig;

typedef struct GoldenPadSurface {
    uint32_t abi_version;
    GoldenPadSurfaceKind kind;
    void *window;
    void *view;
} GoldenPadSurface;

typedef struct GoldenPadPlayerInput {
    float move_x;
    float move_y;
    float look_x;
    float look_y;
    uint32_t actions;
    uint32_t flags;
} GoldenPadPlayerInput;

GoldenPadResult goldenpad_runtime_prepare(const GoldenPadRuntimeConfig *config);
GoldenPadResult goldenpad_surface_attach(const GoldenPadSurface *surface);
void goldenpad_surface_resize(uint32_t width, uint32_t height);
void goldenpad_surface_detach(void);
GoldenPadResult goldenpad_runtime_start(void);
void goldenpad_runtime_set_active(bool active);
void goldenpad_runtime_submit_input(uint32_t player,
                                    const GoldenPadPlayerInput *input);
uint32_t goldenpad_runtime_render_audio(float *left, float *right,
                                        uint32_t frames);
```

This is a source-level host contract, not a promise that one binary library is
copied between operating systems. Each product compiles the same common source
for its target ABI.

The surface calls are intentionally separate from runtime start. Android can
replace a presentation surface without creating a second GoldenEye simulation.
Apple can attach once and reuse the same contract. Linux can supply an SDL
window without leaking SDL into the game/runtime layer.

### Shared input semantics

Hosts should report semantic actions such as fire, aim, action, weapon, crouch,
pause, D-pad, and menu navigation plus normalized move/look axes. The common
runtime should own:

- N64 button masks;
- classic C-button versus modern analog look;
- dead-zone and response curves;
- rising-edge crouch toggle;
- aim inversion semantics;
- relative-touch consumption;
- Player 1-4 routing rules; and
- neutralization when UI/lifecycle modes change.

Physical controller enumeration, Android key/axis quirks, Apple
`GCController`, mouse events, and touch pointer ownership stay in each host.
The existing Swift implementation is the behavioral oracle until shared unit
tests reproduce it exactly.

### Shared settings schema

Use stable semantic names and versioned JSON/data structures for settings. Each
host may store them using `UserDefaults`, Android DataStore/SharedPreferences,
or a desktop file, but the schema and defaults should be shared:

- resolution mode;
- MSAA;
- three-point filtering;
- touch sensitivity and aim behavior;
- controller look mode and action mapping;
- unlock-all-missions flag;
- phone/tablet layout profile version; and
- diagnostics opt-ins.

Do not attempt to share raw Apple screen coordinates with Android. Store touch
placements as normalized positions inside the current safe content rectangle,
with independent phone and tablet profiles. Native hosts render and constrain
those placements for their own density, insets, cutouts, and accessibility
systems.

## Patch and dependency strategy

The current filenames reflect the path by which the iOS prototype was built,
not the proper long-term ownership. Classify the existing changes before adding
Android logic:

| Current patch | Long-term classification |
| --- | --- |
| `n64modernruntime-ios-aot.patch` | Mostly shared AOT/mobile runtime; split or rename only after all current builds pass |
| `goldeneye64recomp-ios-modern-controls.patch` | Shared GoldenPad game/input behavior |
| `goldeneye64recomp-ios-prototype-render-trace.patch` | Split shared render diagnostics/lifecycle from Apple logging and data paths |
| `rt64-ios-embedded.patch` | General embedded-host and pregenerated-shader support plus an Apple-specific source selection |
| `rt64-ios-sdk.patch` | Apple SDK/toolchain only |
| `plume-ios-metal.patch` | Apple Metal backend only |
| `plume-macos-main-queue-coalescing.patch` | macOS host/backend only |

Expected Android additions:

- an N64ModernRuntime native-Android `WindowHandle` patch;
- a GoldenEye RT64 Android window/Vulkan context patch;
- an RT64 embedded-Android source selection and no-desktop-UI patch;
- a Plume/RT64 replaceable Android surface patch if the initial source cannot
  safely recreate its swapchain;
- an Android logger/data-path adapter; and
- build-only patches for host-generated SPIR-V and Android static archives.

Apply shared patches first, then platform patches. Every script should verify
the exact upstream commit, refuse unexpected local changes, apply patches in a
temporary or controlled checkout, build, and reverse them. Do not carry a
hand-edited Android-only `ref/` tree as the product source.

## Build architecture

### Two-stage generation is mandatory

RT64 generates shader sources using host executables such as DXC and
`file_to_c`. N64Recomp also runs on the development host to create the AOT C
sources. An NDK cross-build must not try to build an Android executable and
then run it on macOS as a shader generator.

Use two explicit stages:

```text
Stage A: host tools and private generation
  N64Recomp -> generated GoldenEye AOT C
  patch generator -> matched patches.c + patches_bin.c
  DXC -> SPIR-V
  file_to_c -> embedded SPIR-V C blobs
  manifest -> source commits + patch hashes + artifact hashes

Stage B: target compilation
  AppleClang -> iOS/macOS runtime + Metal shader blobs
  Android NDK Clang -> libgoldenpad.so + SPIR-V blobs
  Linux Clang/GCC -> GoldenPad executable + SPIR-V blobs
```

The existing Mac dependency script already demonstrates the correct pattern by
building RT64 shader artifacts with a native host build before compiling the
target archives. Generalize that behavior rather than adding a second ad hoc
Android generator.

### Recommended targets

The long-term CMake graph should expose logical libraries rather than duplicate
source lists:

```text
goldenpad_game_aot          generated game and matched patches
goldenpad_runtime_common    ROM, input policy, audio ring, lifecycle, diagnostics
goldenpad_n64runtime        pinned AOT-only N64ModernRuntime closure
goldenpad_rt64_common       RT64 renderer core and shared GoldenEye context
goldenpad_rt64_metal        Apple/Plume Metal adapter
goldenpad_rt64_vulkan       Android/Linux Plume Vulkan adapter

GoldenPadRecompPrototype    iPhone/iPad Swift host
GoldenPadMac                native Mac Swift/AppKit host
goldenpad_android           libgoldenpad.so loaded by GameActivity
GoldenPadLinux              SDL desktop host
```

The first Android spike should not move every existing file. Add the shared
CMake fragment and Android target alongside the accepted Apple targets, prove
the source list is identical where intended, then perform mechanical moves in
a separately reviewable cleanup.

### Suggested repository shape

```text
include/goldenpad/
  runtime.h
cmake/
  GoldenPadRuntime.cmake
  GoldenPadDependencies.cmake
Support/Runtime/
  Runtime.cpp
  InputPolicy.cpp
  AudioRing.cpp
  Diagnostics.cpp
  ROMImport.cpp
Support/Platform/
  Apple/
  Android/
  SDL/
platform/android/
  settings.gradle.kts
  build.gradle.kts
  gradle/wrapper/
  app/
    build.gradle.kts
    src/main/AndroidManifest.xml
    src/main/java/.../GoldenPadActivity.kt
    src/main/java/.../GoldenPadTouchView.kt
    src/main/cpp/CMakeLists.txt
    src/main/cpp/GoldenPadJNI.cpp
scripts/
  generate-recomp-inputs.sh
  build-recomp-dependencies.sh
  build-android.sh
  verify-android-package.sh
```

This is a target organization, not a request to perform a large initial rename.

## Android product host

### Activity and surface

Use a Kotlin subclass of Android `GameActivity`. GameActivity is designed for
C/C++-intensive games, integrates native lifecycle/input through
`android_native_app_glue`, and renders into a `SurfaceView` that can coexist
with Android UI elements.

The Activity owns:

- a `SurfaceView`/GameActivity surface;
- a touch-overlay `View`;
- first-run ROM setup and error UI;
- settings and touch-layout editing;
- Android file picker and diagnostic sharing;
- system bars, cutouts, insets, and accessibility; and
- native library loading.

The native Android adapter obtains and retains `ANativeWindow*` only while the
surface is valid. It reports surface creation, size change, destruction, app
start/stop, focus, and audio focus to the shared runtime. The game simulation
continues on N64ModernRuntime's native threads, not on the Android UI thread.

### ROM import and private storage

Use the Storage Access Framework with `ACTION_OPEN_DOCUMENT`. No broad storage
permission is required. The flow is:

1. User chooses a supported `.z64`, `.v64`, `.n64`, or `.rom` document.
2. Kotlin opens the returned URI and streams it into a random app-private
   staging file.
3. Native code runs the existing bounded conversion into a second staging
   output.
4. Native code verifies the exact final TLB-free hash.
5. The host fsyncs/commits and atomically replaces the active private ROM.
6. Failure or cancellation removes staging files and leaves the prior valid ROM
   untouched.

Recommended locations:

- active ROM: app-private files or no-backup storage according to the desired
  backup policy;
- save and configuration: app-private durable files;
- RT64 cache: cache/no-backup directory, safe to recreate;
- logs: app-private files, exported only through a user action; and
- staging: app cache on the same volume as the destination when atomic rename
  is required.

ROM, converted ROM, saves, preferences, logs, private paths, and signing
material must never enter the APK/AAB.

### Audio

Use Oboe linked into the Android native library. Request game usage and
low-latency performance, prefer the device's natural rate, and use Oboe's
sample-rate conversion for the 22.05 kHz game stream. The callback performs
only the existing ring read and format copy. It must not allocate, log, lock a
contended mutex, access files, or call Java.

Track both GoldenPad's existing audio counters and Oboe/AAudio xrun counters.
Audio focus loss pauses output and neutralizes latched game audio state;
regaining focus discards stale queued PCM before a short fade-in, matching the
current Apple safety behavior.

### Controllers and touch

For the first proof, Android `KeyEvent`/`MotionEvent` through GameActivity is
sufficient. The Game Controller library/Paddleboat is a reasonable follow-up
for controller database normalization, lights, vibration, and multiple devices
if direct handling shows material compatibility gaps.

Require controller tests across Xbox-style, PlayStation-style, and Switch-style
devices where available. Android axes can report triggers through both trigger
and brake/gas identities, and mappings vary by device; de-duplicate at the host
adapter before submitting semantic actions.

The touch overlay should be a custom Android `View` above the render surface,
not a web layer. It needs stable pointer-ID ownership, real simultaneous
multi-touch, pass-through outside controls, normalized placement storage,
phone/tablet profiles, cutout/navigation inset handling, and complete held-input
neutralization when settings, backgrounding, or surface loss occurs.

The first touch milestone may use a fixed complete layout. Editable placement,
size, opacity, reset, and accessibility parity belong to the usable-alpha gate,
not the first Vulkan gate.

### Lifecycle state machine

The shared runtime should reduce platform notifications into explicit state:

```text
Prepared, no surface
        |
        v
Surface attached -> Renderer ready -> Running
        |                                 |
        | app inactive/audio focus lost   |
        +------------------------------> Suspended
                                          |
surface destroyed -> detach/recreate <----+
        |
new surface attached -> Renderer ready -> Running
```

On suspension:

- neutralize all controller and touch sources;
- stop presentation before releasing the window;
- pause/stop the audio stream and discard stale queued PCM;
- request a durable save/config flush;
- retain only GPU objects proven safe without a surface; and
- mark diagnostics clean only after required writes complete.

Do not create a second runtime after Activity recreation. The Android owner
must reject duplicate start requests just as the current native bridge does.
The existing shutdown path is not yet a safe general-purpose teardown/restart
contract, so repeatable renderer/surface attachment must be solved without
pretending full process-lifetime teardown is already available.

## How Apple and Linux benefit

### Apple

The existing products retain SwiftUI/UIKit/AppKit, Metal, AVAudioEngine, and
GameController. They change only at the native boundary:

- Swift imports the supported header instead of undeclared `_silgen_name`
  functions;
- input policy moves into shared C++ after parity tests pass;
- renderer selection becomes `Metal` through common graphics configuration;
- paths and logging are supplied by an Apple adapter; and
- the shared lifecycle reducer replaces host-specific duplicated state rules.

Android work must not weaken the accepted iPhone/iPad or Mac gates. Every common
runtime change builds and runs on Apple before it is considered reusable.

### Linux

Linux is lower platform risk than Android after common extraction because the
assessed upstream GoldenEye host already has SDL/Linux window, audio, input, and
RT64 Vulkan paths, and RT64 officially lists Linux support. GoldenPad should
still use its own small SDL host so its ROM flow, input policy, settings,
diagnostics, and patches match the mobile products.

The first Linux host can own:

- SDL window and Vulkan surface;
- keyboard, mouse, and SDL controller events;
- SDL audio consumption of the shared ring;
- native file picker or command-line ROM import; and
- XDG-compliant data/config/cache paths.

Linux should not be implemented by reviving a separate upstream executable
whose GoldenPad patches and behavior drift independently.

## Implementation phases and hard gates

### Phase 0: freeze the common baseline (1-2 weeks)

Deliverables:

- record exact accepted dependency commits and patch hashes;
- resolve the accepted-versus-research N64ModernRuntime pin in one manifest;
- add host-neutral tests for ROM conversion, input mapping, touch accumulation,
  audio ring behavior, graphics config mapping, and lifecycle neutralization;
- define `runtime.h` around the existing native functions; and
- build unchanged Apple targets through the new common source fragment.

Gate:

- current iPhone/iPad and Mac source/package gates pass with no behavior or
  artifact-scope regression.

### Phase 1: Android native compile and package skeleton (1-2 additional weeks)

Deliverables:

- Gradle wrapper and one app module;
- pinned SDK/NDK/CMake/JDK inputs;
- NDK `arm64-v8a` `libgoldenpad.so`;
- host-generated SPIR-V embedded into the Android native library;
- GameActivity loads the library and reports native version/source identity;
- SAF selection, staging, conversion, and hash validation; and
- debug APK content audit.

Gate:

- the APK installs and loads on a 64-bit physical device;
- no ROM, converted ROM, save, local path, signing secret, live recompiler, or
  writable executable module is packaged; and
- every packaged `.so` has the expected ABI and 16 KB-compatible ELF alignment.

This is build evidence, not rendering or gameplay evidence.

### Phase 2: first real Vulkan gameplay (3-6 additional weeks)

Deliverables:

- native `ANativeWindow` boundary in N64ModernRuntime;
- Android embedded RT64 host;
- GoldenEye RT64 context selects Vulkan and receives the native window;
- first real display list and VI presentation;
- one controller; and
- Oboe audio output.

Gate:

- title and Dam render on one recent Adreno device;
- the game reaches interactive first-person play through the real controller
  callback;
- audio contains non-zero output with bounded underruns;
- renderer/game health counters continue advancing for at least ten minutes;
  and
- no Vulkan validation error, native crash, process death, or private-data leak
  is observed.

If this gate fails because RT64's Android Vulkan path requires a broad renderer
rewrite, stop and reassess before building the full Android UI.

### Phase 3: surface and lifecycle proof (2-4 additional weeks)

Deliverables:

- Android surface detach/replace/recreate implementation;
- activity pause/resume and audio-focus handling;
- save/config flush and input neutralization;
- fixed complete touch controls; and
- phone/tablet layout foundations.

Gate:

- at least 20 background/foreground cycles;
- repeated lock/unlock, app switch, Bluetooth audio route, and controller
  reconnect cycles;
- no duplicate runtime or stale-window access;
- the exact save and imported ROM survive process recreation and in-place app
  update; and
- gameplay resumes coherently after every supported surface transition.

### Phase 4: usable Android alpha (3-6 additional weeks)

Deliverables:

- editable touch layout with normalized phone/tablet profiles;
- controller mapping and right-stick modes;
- display/settings parity;
- diagnostic export;
- accessibility labels/actions;
- Android back/menu behavior; and
- representative Adreno and Mali/Tensor validation.

Gate:

- complete single-player hands-on acceptance with touch and controller;
- audio, save/load, pause/resume, settings persistence, and update preservation;
- stable performance and thermals for a representative 30-minute session; and
- all known limitations documented without claiming multiplayer parity.

### Phase 5: release hardening (4-8 additional weeks)

Deliverables:

- reproducible release APK and AAB;
- source/license manifest for the primary recomp/RT64 product;
- 16 KB page-size validation for every native dependency;
- symbols and native crash diagnostics;
- broader GPU/controller/OS matrix;
- package/private-data audit; and
- release/install/update documentation.

Gate:

- clean-runner build from pinned inputs;
- package contents and native dependencies audited;
- fresh install and in-place update both preserve the intended data boundary;
- public artifact downloads and checksums verified; and
- physical hands-on acceptance remains distinct from automated proof.

## Shared validation matrix

Every platform should report the same feature contract even when its host code
differs:

| Contract | iPhone/iPad | macOS | Android | Linux |
| --- | --- | --- | --- | --- |
| Exact supported ROM and conversion identity | Required | Required | Required | Required |
| Same AOT/game patch manifest | Required | Required | Required | Required |
| No live CPU recompiler/JIT in product | Required | Required | Required | Required |
| Title and Dam gameplay | Physical | Hands-on | Physical | Hands-on |
| Shared input mapping tests | Required | Required | Required | Required |
| Touch controls | Required | N/A | Required | N/A |
| Controller input | Required | Required | Required | Required |
| PCM counters and audible output | Required | Required | Required | Required |
| Save compatibility and atomic writes | Required | Required | Required | Required |
| Background/surface lifecycle | Required | Window lifecycle | Required | Window lifecycle |
| Renderer health counters | Metal | Metal | Vulkan | Vulkan |
| Package contains no user data | IPA | ZIP/app | APK/AAB | Archive/package |

Renderer screenshots should be compared by scene and perceptual tolerances, not
required to hash identically across Metal and Vulkan. Game state, controller
semantics, save bytes, ROM identity, patch identity, and health-counter meaning
can be exact across platforms.

## Risk register

| Risk | Likelihood | Impact | Mitigation/gate |
| --- | --- | --- | --- |
| RT64 initial Android application path is incomplete | High | High | Bypass desktop ownership through an embedded Android host; prove real frames before UI parity |
| Android surface replacement is absent | High | High | Separate initial-surface and replacement-surface gates; add explicit detach/recreate contract |
| Vulkan behavior varies across Adreno and Mali/Tensor drivers | High | High | Start API 29/Vulkan 1.1; validate two GPU families early; log capabilities and validation output |
| Host shader tools are accidentally cross-compiled | Medium | High | Mandatory host-generation stage and hashed pregenerated SPIR-V inputs |
| Runtime pins drift between Apple and Android | Medium | High | One dependency manifest; all platforms advance together through CI and physical gates |
| Shared extraction regresses accepted Apple behavior | Medium | High | Characterization tests first; small patches; Apple gates on every shared change |
| Swift and Kotlin duplicate input/game policy | High without refactor | Medium | Move semantic mapping/dead-zone/routing into common C++ after freezing Swift behavior |
| Current runtime shutdown cannot safely restart | High | High | One simulation per process; surface replacement without duplicate runtime; treat teardown separately |
| Audio callback blocks or resampling glitches | Medium | Medium | Oboe callback only reads ring; native-rate stream; xrun and GoldenPad underrun counters |
| 16 KB pages break a prebuilt native library | Medium | High | NDK r28+ or explicit alignment; verify every `.so`; test a 16 KB Android image/device |
| Current source-license inventory covers Legacy, not the primary product | High | High for release | Generate a new recomp/RT64 primary source and notice manifest before public Android packaging |
| Existing multiplayer debt expands the Android scope | Medium | Medium | Single-player first; preserve current experimental status; no network play in platform milestone |
| Retail/private data enters an Android artifact | Low with audits | Critical | SAF staging, app-private paths, ignored build inputs, content and string/path audits |

## Legal, source, and distribution boundary

Android does not change the project's underlying source and retail-data
obligations. The application remains an unofficial native port and must not
contain the retail ROM, converted ROM, saves, preferences, logs, signing
material, or private paths.

The current `docs/source-license-manifest.tsv` is generated for the MGB64 Legacy
source surface. It is not sufficient evidence for the primary
GoldenEye64Recomp/N64ModernRuntime/RT64 Android product. Before release, produce
a machine-generated manifest from the actual Android native target, classify
every source and generated input, stage the required GPL/MIT/third-party source
and notices, and verify the public artifact's corresponding-source route.

Google Play or another store's IP/policy acceptance is a separate release and
legal question from whether the native APK works. Do not let technical
feasibility language imply store approval.

## Recommended next implementation decision

Proceed only with a bounded shared-core plus Android foreground spike:

1. Freeze the accepted runtime/dependency identity.
2. Add characterization tests and the supported C host header.
3. Build the unchanged Apple products through the shared source fragment.
4. Add the Android module and cross-compile the complete AOT/runtime closure.
5. Prove ROM validation and the first real RT64/Vulkan frame on physical
   Adreno hardware.
6. Stop and review evidence before implementing editable touch controls or
   broad product polish.

This creates the reusable foundation the user wants while keeping the most
uncertain Android renderer work early, isolated, and measurable.

## Research sources

### GoldenPad source

- [`../CMakeLists.txt`](../CMakeLists.txt)
- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`BUILDING.md`](BUILDING.md)
- [`RT64_N64RECOMP_PROTOTYPE.md`](RT64_N64RECOMP_PROTOTYPE.md)
- [`SOURCE_LICENSES.md`](SOURCE_LICENSES.md)
- [`../Support/RecompPrototype/recomp_game_start.cpp`](../Support/RecompPrototype/recomp_game_start.cpp)
- [`../Support/RecompPrototype/recomp_rom_import.cpp`](../Support/RecompPrototype/recomp_rom_import.cpp)
- [`../Sources/RecompPrototypeApp.swift`](../Sources/RecompPrototypeApp.swift)
- [`../Sources/RecompPrototypeInput.swift`](../Sources/RecompPrototypeInput.swift)
- [`../Sources/RecompPrototypeAudio.swift`](../Sources/RecompPrototypeAudio.swift)
- [`../Sources/RecompPrototypeTouchLayout.swift`](../Sources/RecompPrototypeTouchLayout.swift)
- [`../patches/n64modernruntime-ios-aot.patch`](../patches/n64modernruntime-ios-aot.patch)
- [`../patches/rt64-ios-embedded.patch`](../patches/rt64-ios-embedded.patch)

### Upstream and platform documentation

- [N64ModernRuntime](https://github.com/N64Recomp/N64ModernRuntime)
- [N64Recomp](https://github.com/N64Recomp/N64Recomp)
- [RT64](https://github.com/rt64/rt64)
- [GoldenEye64Recomp](https://github.com/cblock85/GoldenEye64Recomp)
- [Android NDK overview](https://developer.android.com/ndk/guides)
- [Android NDK CMake](https://developer.android.com/ndk/guides/cmake)
- [GameActivity](https://developer.android.com/games/agdk/game-activity/get-started)
- [Android Vulkan native-engine guidance](https://developer.android.com/games/develop/vulkan/native-engine-support)
- [Android Vulkan pre-rotation](https://developer.android.com/games/optimize/vulkan-prerotation)
- [Android Vulkan frame pacing](https://developer.android.com/games/sdk/frame-pacing/vulkan/add-functions)
- [Android low-latency audio with Oboe](https://developer.android.com/games/sdk/oboe/low-latency-audio)
- [Android game-controller input](https://developer.android.com/games/sdk/game-controller/controller-input)
- [Android Storage Access Framework](https://developer.android.com/guide/topics/providers/document-provider)
- [Android 16 KB page-size support](https://developer.android.com/guide/practices/page-sizes)
