# Native macOS feasibility spike

Date: 2026-08-21

## Decision

**GO. Native Apple-Silicon macOS support is highly feasible.**

The game/runtime/renderer is not the blocker. GoldenPad's pinned
GoldenEye64Recomp base already contains a working macOS execution path using
N64Recomp, N64ModernRuntime, RT64 and Metal. A clean, temporary copy of the
pinned source configured and compiled on this Mac into a native arm64 Mach-O
with an `LC_BUILD_VERSION` platform of `MACOS`.

GoldenPad now has an opt-in native macOS target sharing the AOT runtime and C
bridges through a small SwiftUI/AppKit host. The internal build target remains
isolated from the accepted mobile target, while the user-facing product, bundle
display name and executable are all `GoldenPad`. It is native arm64 macOS, not
Mac Catalyst.

Current status: **implemented and package-audited Alpha**. The current Release
`GoldenPad.app` builds, signs ad hoc and reaches authentic gameplay. Its final
packaged-source executable SHA-256 is
`7c78b72f4d6fd1697a5fb0572dfe22de6a8680d7df784ceb0752ef7b9527c35d`.
Hands-on review accepted it as an alpha baseline, not as mobile-parity or a
public stable Mac release. Mouse look remains too slow, keyboard/mouse controls
need later tuning, a thin blue strip remains on the far-right render edge, and
sustained performance remains open. The separate arm64 Alpha archive passed its
architecture, signature, dependency, icon, notices, private-path and game-data
audit at SHA-256
`7a9e7342b0ae39518f73807f854b479d9691fd612ae6861ea527f2a19e4450a4`.
Oldest-supported-OS testing and notarization remain open. The detailed rejected
experiments and freeze boundary are in [`TECH_DEBT.md`](TECH_DEBT.md); current
platform status is in [`STATUS.md`](STATUS.md).

Do not use Mac Catalyst and do not replace or destabilize the accepted
iPhone/iPad target while addressing later Mac debt.

## Evidence collected

### Pinned baseline for implementation

| Component | Revision or boundary |
|---|---|
| GoldenPad accepted iOS release | `f512161126c6926ac877d7ffe7512d14d9f0c90c` (`v0.1.0-preview.1`) |
| GoldenEye64Recomp reference | `a787fe0d95e8278fcba5ba2d768fa6a606e75f55` |
| RT64 reference | `5473732a822a4423b5696e7cb18fecc425a59875` |
| N64ModernRuntime source used by the accepted private AOT build | `e75e0de77e8377d4954fe7b511c0d1cf608e7ded` |
| Generated GoldenEye AOT/RSP output, user-derived TLB-free ROM and any retail conversion input | Private, user-supplied build inputs; never tracked or packaged |

Refresh these revisions only in a separate dependency update. The first Mac
slice should prove platform integration against the accepted baseline, not mix
that work with an upstream upgrade.

### Existing upstream macOS route

The pinned `ref/goldeneye64recomp` source at
`a787fe0d95e8278fcba5ba2d768fa6a606e75f55` declares native macOS support and
already contains:

- an SDL/Cocoa window and Metal-layer handoff;
- RT64's Metal renderer;
- native controller, audio, configuration and file-picker paths;
- a macOS build script and `.app` wrapper; and
- both static-AOT and clean live-recompilation modes.

A temporary `LIVE_GAMECODE=ON` build was configured with the macOS SDK and the
installed Metal toolchain. It completed all 768 remaining build actions and
linked:

```text
Mach-O 64-bit executable arm64
platform MACOS
RT64/Metal and N64Recomp live-recompiler symbols present
SHA-256 28a27f59c09d4380d5470559ba19d48d5e6b01e01405f94ee4a61fab4bfd8d02
```

This was a compile/link proof only. It did not launch retail gameplay and is not
a GoldenPad product build.

A second disposable build exercised the more relevant static-AOT path. It used
the pinned upstream checkout, the private generated AOT/RSP outputs already used
by GoldenPad, `LIVE_GAMECODE=OFF`, `macosx`, arm64 and an explicit 13.0
deployment target. No ROM was copied into or used by this build. All 821
remaining actions completed and linked an arm64 macOS executable:

```text
LC_BUILD_VERSION platform MACOS, minos 13.0, SDK 26.5
SHA-256 ec690813bc4c02fe12c267b70ac01bc42872d9650c7d0c893cb306a2cd232437
```

That result proves that GoldenEye's generated static code and RT64 can compile
together for native macOS. It is deliberately **not** a shipping candidate:

- it still links Homebrew SDL2-compat and FreeType dylibs and carries a
  Homebrew `LC_RPATH`;
- those local dylibs were themselves built for macOS 26, despite the
  executable's 13.0 load command; and
- upstream still links its LiveRecomp/SLJIT implementation even when generated
  static game code is selected.

The host build needed three explicit tool roles: Homebrew LLVM/LLD for the N64
MIPS patch object, Apple's separately installed Metal toolchain for shaders, and
Xcode's macOS SDK/Swift toolchain for the app. These are build prerequisites,
not runtime dependencies. A restricted-environment compiler module-cache
failure disappeared when the identical build was rerun with normal host access;
it was not treated as a source defect.

### GoldenPad AOT-only runtime proof

GoldenPad's accepted runtime patch already has the seam the Mac target needs:
`N64MODERNRUNTIME_ENABLE_LIVE_RECOMP=OFF` excludes SLJIT and supplies inert ABI
stubs for unsupported live-code modules. A disposable native build of the
pinned, patched N64ModernRuntime completed all 96 actions and produced these
archives:

```text
libultramodern.a  liblibrecomp.a  libN64Recomp.a
libSymbolLists.a  librabbitizer.a  libfmt.a  libminiz.a
```

Every archive is arm64. All 89 object files report `platform MACOS`, `minos
13.0`, and SDK 26.5. Symbol and string audits found no `sljit`, `MAP_JIT`, or
other JIT-memory entry points. `LiveRecompilerCodeHandle` symbols remain by
design as inert compatibility stubs; their names alone are not evidence of JIT
code. The final verifier must reject SLJIT/JIT machinery and entitlements, not
those harmless ABI names.

The upstream results also identify packaging defects that GoldenPad must not
inherit:

- setting `CMAKE_OSX_DEPLOYMENT_TARGET=13.0` changes the app's load command but
  does not prove every linked dependency actually supports 13.0;
- the binary links `/opt/homebrew` SDL2 and FreeType dylibs, so the upstream app
  wrapper is not self-contained on a clean Mac; and
- static game code does not automatically remove upstream live-recompiler code.

### Current GoldenPad platform seams

| Area | Reusable as-is | Native macOS adaptation |
|---|---|---|
| Generated GoldenEye AOT code | Yes, after compiling for the macOS SDK | Build new macOS archives; iPhoneOS archives cannot be reused |
| N64ModernRuntime bridges | Mostly | Compile for macOS and remove UIKit wording/assumptions |
| RT64/Plume Metal fixes | Mostly | Preserve the existing `TARGET_OS_IPHONE` branches and use the macOS branches |
| Renderer surface | C bridge is reusable | Replace `UIViewRepresentable` with `NSViewRepresentable`; pass `NSWindow` plus `CAMetalLayer` |
| Audio ring and `AVAudioEngine` | Yes | Compile out `AVAudioSession`, which Apple marks unavailable on macOS |
| Controller mapping | Yes | `GameController` supports macOS; add keyboard/mouse without changing controller semantics |
| SwiftUI settings | Mostly | Remove touch-only rows and replace UIKit share/device helpers |
| Graphics/reticle/cheats | Yes | Preserve defaults and restart-required behavior |
| Saves and diagnostics | File formats are reusable | Use `~/Library/Application Support/GoldenPad` and Mac-native reveal/share actions |
| Touch editor | No Mac equivalent needed | Do not show touch controls on macOS |
| ROM setup | Runtime accepts the same user-derived TLB-free input | Select and copy `GoldenEye_TLBFREE.z64` with `NSOpenPanel`; do not add retail conversion to Preview 1 |

Local type-check probes confirmed the expected boundaries:

- `RecompPrototypeTouchLayout.swift` fails because UIKit is not a macOS module;
- `RecompPrototypeMetalCanvas.swift` needs `NSViewRepresentable` and AppKit view
  behavior;
- `RecompPrototypeAudio.swift` reaches macOS-unavailable `AVAudioSession`; and
- the controller model imports only cross-platform Foundation, SwiftUI,
  GameController and SIMD, although its touch view should be split away.

Apple documents that `MTKView` is both an `NSView` and a `UIView`, SwiftUI
provides `NSViewRepresentable`, `GameController` supports Xbox and other
controllers on macOS, `AVAudioEngine` provides native real-time output, and
`NSOpenPanel` provides sandbox-compatible file selection. These are supported
platform seams rather than custom compatibility layers.

## Product parity definition

“Same properties” should mean the same game/runtime behavior and equivalent
native controls, not displaying an iPhone touch overlay on a Mac.

The first accepted Mac build must preserve:

- the same GoldenEye AOT game path and RT64/Metal renderer;
- Native N64, 2x and automatic-high-resolution modes;
- 2x MSAA and N64 three-point filtering;
- the same reticle, invert-aim, controller-look and button-map settings;
- Xbox/MFi controller behavior and clean reconnect handling;
- native audio from the same PCM ring;
- EEP4K saves and the same unlock-all-missions default of Off;
- Return to Main Menu;
- bounded diagnostics and log export; and
- the same ROM-free repository/package boundary.

Mac-specific behavior adds:

- resizable window and native fullscreen;
- keyboard/mouse controls with remapping and relative mouse look;
- a standard Mac Settings window and application menu; and
- Mac-native ROM selection and log/save reveal actions.

Touch layout editing and the touch-as-Player-2 diagnostic are not Mac features.
Multiplayer remains experimental until separately accepted with multiple
physical controllers.

## Route selection

The implementation route is selected; this is not an open-ended architecture
exercise.

| Route | Use | Decision |
|---|---|---|
| Mac Catalyst | Reuse the UIKit shell | Reject. It is not the requested native Mac product, does not remove the unavailable/mobile lifecycle seams, and still requires Mac-platform runtime archives. |
| Upstream SDL/Cocoa host | Compile and behavior oracle | Keep only as a diagnostic baseline. Its current bundle has Homebrew SDL2/FreeType dependencies and does not provide GoldenPad's settings, diagnostics or product UI. |
| SwiftUI/AppKit + GoldenPad's embedded RT64 surface | Shipping architecture | Select. It shares the accepted AOT/runtime/renderer bridge, keeps one owner for the Metal layer, and needs only a small native platform shell. |

If the AppKit embedded-surface spike cannot reach the title screen within the
first bounded implementation slice, use the SDL build to compare window/layer
handoff and runtime sequencing. Do not turn that fallback into the shipped app
unless its external dependencies are removed and all GoldenPad parity gates are
met.

## Selected architecture

```text
GoldenEye AOT + N64ModernRuntime + RT64
                  |
        existing narrow C bridge
          /                    \
 SwiftUI/UIKit host       SwiftUI/AppKit host
   iPhone + iPad            Apple Silicon Mac
```

Keep one runtime core and two small platform shells. Add platform files instead
of filling the accepted iOS files with large conditional blocks:

```text
Sources/RecompShared/          shared settings, input model and diagnostics
Sources/RecompMobile/          UIKit Metal canvas, touch UI, AVAudioSession
Sources/RecompMac/             AppKit Metal canvas, keyboard/mouse, Mac file UI
```

The Mac renderer should use GoldenPad's SDL-free embedded surface. Begin with a
Mac-only overlay so the accepted iOS patch is untouched. After both targets are
green, the duplicate guards can be consolidated into one embedded-Apple option
while retaining `TARGET_OS_IPHONE` only where Plume genuinely differs. This
avoids shipping Homebrew SDL2/FreeType dependencies and keeps the Mac product
aligned with the accepted mobile renderer path.

### Surface and lifetime contract

RT64's native Mac route confirms the required handle pair: an `NSWindow` plus a
`CAMetalLayer`. RT64 stores the window for Cocoa size/fullscreen behavior and
uses the layer as its Metal swap chain. The pinned Plume swap chain only borrows
both pointers—its destructor does not release the layer—so the host ownership
contract is:

- the Swift/AppKit host retains the window and `MTKView` for the entire runtime;
- the bridge passes unretained pointers and transfers no ownership to RT64;
- runtime shutdown completes before the host destroys the view or window; and
- mobile ownership stays unchanged.

The host `MTKView` must not become a second renderer. Use it only to own the
`CAMetalLayer`: pause its internal draw loop, keep automatic drawable resizing,
and let RT64 alone encode and present. Observe drawable-size, backing-scale,
window and display changes and forward only the state RT64 needs. Before ROM
launch, run 50 create/attach/resize/detach cycles with Metal API Validation and
development Zombies or Address Sanitizer. Any over-release, double shutdown or
drawable use after window close is a stop gate.

### Data ownership contract

Preview 1 intentionally has no in-app retail-ROM conversion. The Mac app keeps
the accepted mobile boundary:

1. The user selects an already derived `GoldenEye_TLBFREE.z64` with
   `NSOpenPanel`.
2. The runtime validates the existing TLB-free hash through
   `recomp::select_rom` before launch.
3. The app atomically copies the validated file to
   `~/Library/Application Support/GoldenPad/ROMs/GoldenEye_TLBFREE.z64` and
   releases access to the selected source URL.
4. Neither the source file nor its bytes enter git, logs or a package.

The first direct-download developer build is not sandboxed, so it does not need
to persist security-scoped bookmarks. If AppKit returns a security-scoped URL,
access is balanced only for validation/copy. Sandboxing and retail V64/Z64
conversion are later, separately gated features.

Mac state is independent from the iOS container:

```text
~/Library/Application Support/GoldenPad/
  ROMs/GoldenEye_TLBFREE.z64
  saves/ge007.us.bin
  saves/ge007.us.bin.bak
  Logs/goldenpad-recomp-latest.log
  Logs/goldenpad-recomp-previous.log
  Logs/active-session.marker
```

Preferences use a Mac-specific bundle identifier such as
`com.chrissotraidis.goldenpad.macos`. Do not silently import iOS settings or
saves, and do not claim cross-platform save interchange until an explicit
byte-preserving import test passes.

### Exact change map

The implementation should use these seams. Names may change only when the
existing build requires it; do not create a framework or package hierarchy for
this first target.

| File or directory | Narrow change |
|---|---|
| `CMakeLists.txt` | Keep `GOLDENPAD_RECOMP_MAC=OFF` by default. Replace the global non-iOS fatal with explicit iOS and macOS branches, and add `GoldenPadMac` without changing `GoldenPadRecompPrototype` defaults or accepted mobile link flags. |
| `Config/GoldenPadMacInfo.plist.in` | Native Mac bundle metadata, macOS 13 minimum and no Catalyst/device-family keys. |
| `Sources/RecompShared/` | Extract only settings/defaults, controller action mapping, diagnostics metadata and runtime surface state that both products actually use. |
| `Sources/RecompMobile/` | Move the existing UIKit Metal wrapper, touch views/editor and `AVAudioSession` adapter without behavior changes. |
| `Sources/RecompMac/GoldenPadMacApp.swift` | SwiftUI `App`, one main window, Settings scene and application commands. Preview 1 terminates when the main window closes rather than recreating a second runtime in-process. |
| `Sources/RecompMac/RecompMacMetalCanvas.swift` | `NSViewRepresentable`/`MTKView`, `NSWindow` and `CAMetalLayer` handoff, resize and fullscreen notifications. |
| `Sources/RecompMac/RecompMacInput.swift` | `GCKeyboard`/`GCMouse` values plus the shared `GCController` model; AppKit owns only focus and cursor capture/release. |
| `Sources/RecompMac/RecompMacPlatform.swift` | `NSOpenPanel`, reveal/export actions and Mac Application Support paths. |
| `Sources/RecompPrototypeAudio.swift` | Extract the PCM/`AVAudioEngine` owner; leave `AVAudioSession` in the mobile adapter. Do not change ring size or render behavior during the split. |
| `Sources/RecompPrototypeInput.swift` | Split the controller/input model from touch-only views. Preserve current Xbox/MFi mappings and right-stick behavior byte-for-byte where practical. |
| Mac RT64 patch/overlay | Start with a Mac-only embedded-surface patch so the accepted iOS archive is byte-for-byte unaffected. Consolidate it with `patches/rt64-ios-embedded.patch` only after both platform verifiers pass. |
| `scripts/verify-recomp-macos.sh` | Clean configure/build and Mach-O/dependency assertions. |
| `scripts/package-recomp-macos-alpha.sh` | Assemble and audit an ad-hoc-signed, ROM-free arm64 Alpha archive containing `GoldenPad.app`. |
| `scripts/verify-recomp-macos-app.sh` | Bundle, signing, dependency, private-path, ROM/save and generated-asset audit. |

Expected developer output:

```text
build-recomp-macos/Release/GoldenPad.app
```

The first build contract should be a single opt-in option and explicit Mac
SDK/architecture rather than host-machine defaults:

```sh
cmake -S . -B build-recomp-macos -G Xcode \
  -DGOLDENPAD_RECOMP_MAC=ON \
  -DCMAKE_OSX_SYSROOT=macosx \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0
cmake --build build-recomp-macos --config Release --target GoldenPadMac
scripts/verify-recomp-macos.sh build-recomp-macos/Release/GoldenPad.app
```

The configure call also receives the existing private AOT, runtime, reference
and RT64 path inputs; their contents remain outside git and the app bundle.
The verifier owns the exact path assertions; developers should not have to
manually inspect `otool`, load commands and bundle contents for every build.

Required build tools must be checked up front with actionable failures:

- Xcode/macOS SDK and Swift compiler;
- Apple's separately installed Metal Toolchain selected for shader compilation;
- Homebrew LLVM's MIPS-capable `clang`, `ld.lld` and `llvm-objcopy` for the N64
  patch object only; and
- the existing private generated AOT/RSP source directories.

Homebrew tools may generate objects, but no Homebrew library may become a
runtime dependency. The final executable audit must reject `/opt/homebrew`,
`/usr/local`, user/temp paths and unexpected `LC_RPATH` entries. It must also
reject SLJIT/JIT symbols or strings, `MAP_JIT`, and these entitlements:

```text
com.apple.security.cs.allow-jit
com.apple.security.cs.allow-unsigned-executable-memory
com.apple.security.cs.disable-executable-page-protection
com.apple.security.cs.disable-library-validation
```

GoldenPad should run under Hardened Runtime without any executable-memory or
library-validation exception. Inert live-module ABI stubs are permitted only
when their linked code contains no JIT implementation or executable-memory
path.

## Implementation plan

### Phase 0 — isolated baseline

Status: compile/link proof completed during this spike.

1. Keep the upstream SDL executable only as a behavior oracle; it is not a
   packaging base.
2. Treat the successful static upstream executable and seven successful
   GoldenPad AOT-only runtime archives as recorded evidence, not checked-in
   artifacts.
3. Record the exact upstream/runtime/RT64 revisions used by the iOS release.
4. Create an isolated `codex/macos-native-spike` branch when implementation is
   authorized.

Gate: satisfied. The pinned generated code, patched AOT-only runtime and RT64
compile for native arm64 macOS; the remaining work is GoldenPad product
integration and acceptance.

### Phase 1 — build-system and runtime closure

1. Replace the global iOS-only CMake fatal error with explicit iOS and macOS
   product branches.
2. Add a `GoldenPadMac` bundle target with an explicit Apple-Silicon architecture
   and macOS 13 minimum.
3. Compile N64ModernRuntime, generated AOT sources and RT64 for `macosx`; never
   link the existing iPhoneOS/Simulator archives into the Mac target.
4. Add a Mac-only embedded RT64 overlay first. Defer shared-patch cleanup until
   both platform builds pass.
5. Add a verifier that requires `platform MACOS`, arm64, Metal/RT64/runtime
   symbols and AOT-only runtime behavior; it rejects UIKit, Catalyst, SDL,
   FreeType, SLJIT/JIT machinery, unsafe entitlements, Homebrew paths, private
   paths and unexpected dynamic libraries or rpaths.

Gate: `GoldenPad.app` builds from a clean build directory and has no
`/opt/homebrew`, `/usr/local`, `/Users`, or temporary-path runtime dependencies.
Every bundled Mach-O/object has a minimum OS no newer than the declared app
minimum. The declared minimum remains provisional until run on that OS.

### Phase 2 — first vertical slice

This slice proves the selected architecture before shared-code extraction or
desktop feature work:

1. Build an unsigned or ad-hoc-signed native `GoldenPad.app` containing a
   black `MTKView`; prove that it is arm64/Mac, not Catalyst.
2. Attach the embedded RT64 bridge to the `NSWindow` and `CAMetalLayer`; resolve
   the explicit retain/release contract and pass the 50-cycle surface stress
   test without a ROM.
3. Link newly built macOS AOT/runtime/RT64 archives and start the same private
   TLB-free GoldenEye input used by mobile.
4. Make the smallest audio split required to reuse the PCM ring/source node
   while excluding `AVAudioSession`; do not retune buffering in this phase.
5. Use the existing `GCController` mapping to reach the GoldenEye title/menu
   and start a mission with a physical controller.
6. Record render, audio and input evidence separately. Do not refactor settings
   or add keyboard/mouse until this gate passes.

Gate: the native AppKit-hosted build reaches authentic GoldenEye title/menu and
mission rendering through RT64/Metal with audible audio and controller input.
If it fails, stop at the failing window/layer/runtime seam and compare against
the upstream SDL oracle; do not broaden the rewrite.

### Phase 3 — native desktop input and lifecycle

1. Keep the validated SwiftUI/AppKit host and Metal wrapper from Phase 2 small;
   move them into the selected `Sources/RecompMac/` files without changing the
   layer handoff.
2. Split only the cross-platform input/settings model from the mobile
   touch-control views, running the mobile regression gate after each move.
3. Reuse the unchanged `GCController` mappings. Use `GCKeyboardInput` and
   `GCMouseInput` for key/button/motion values; use AppKit only to focus the game
   view and capture/release the cursor.
4. Keep `AVAudioEngine`, the existing source node and PCM ring behavior; make
   `AVAudioSession` an iOS-only lifecycle adapter.
5. Add scene phase and window notifications for pause/resume, minimize,
   fullscreen and termination.
6. Keep mouse capture inside the Metal view and expose an unconditional Escape
   release path.

Initial keyboard/mouse defaults:

| Input | Action |
|---|---|
| `W A S D` | Move |
| Mouse | Relative look |
| Left click | Fire |
| Right click | Aim |
| `E` | Action/reload |
| `Q` | Change weapon |
| `C` or Control | Duck |
| Return or Tab | Start/watch |
| Escape | Release mouse and recover the app menu |

Mouse capture begins only after clicking the game view. The cursor is hidden
only while captured; Escape, resign-active, minimize and opening Settings always
release it, and uncaptured motion produces no look delta. Controller and
keyboard/mouse both address player 1; the most recently active source owns
analog axes, and focus loss or disconnect clears every held axis/button to
prevent stuck input. Multiplayer remains out of this phase.

The audio implementation must preserve the accepted mobile constants and
behavior: 22,050 Hz stereo PCM, 65,536-frame ring, 1,024-frame producer reserve,
32-frame fades and the established stereo-pair correction. The real-time source
callback performs no allocation, locking or logging. Test default-device and
sample-rate changes, sleep/wake and engine restart separately from gameplay.

The runtime currently starts on a detached C++ thread, while
`goldenpad_recomp_rt64_shutdown()` only releases the surface record. The runtime
does expose `ultramodern::quit()` and joins its internal game/event/save threads,
so the Mac bridge must own a joinable outer worker and expose an idempotent
stop-and-join operation before it supports view destruction. Preview 1 has one
main window and terminates the app when that window closes; it does not destroy
and recreate a second runtime in-process. Temporary inactive/minimized states
pause presentation and clear input without tearing RT64 down.

Gate: controller behavior still matches mobile; keyboard/mouse can complete
aim, fire, action, duck and weapon interactions; Escape always releases capture;
resize, fullscreen, minimize/restore and quit do not strand the game thread or
leave a diagnostics session marker after a clean exit.

### Phase 4 — GoldenPad feature parity

1. Reuse the Graphics, Controller, Shared Controls and Cheats & Testing models.
2. Present them through a standard Mac Settings scene and keep the small
   in-game utility menu for Settings, diagnostics and Return to Main Menu.
3. Preserve clean defaults: high-resolution renderer settings as currently
   documented and Unlock all missions Off.
4. Store settings, EEP saves and bounded logs beneath
   `~/Library/Application Support/GoldenPad`.
5. Add the native TLB-free ROM picker/import flow defined by the data contract.
   Do not add retail V64/Z64 conversion to this milestone.
6. Add save/log reveal or export actions without exposing the ROM.

Gate: graphics settings survive relaunch, controller remapping works, a save
at `saves/ge007.us.bin` survives quit/reopen with its backup behavior,
diagnostics export works, and Return to Main Menu works. A clean install has
Unlock all missions Off and no inherited mobile preferences.

### Phase 5 — physical Mac acceptance

Run hands-on tests on Apple Silicon hardware. Treat each evidence layer as a
separate gate:

1. **Runtime/data:** missing input, wrong input, valid TLB-free import, logos,
   title, file select and at least Dam, Facility and Bunker.
2. **Input:** controller, keyboard/mouse, capture/release, focus loss,
   disconnect/reconnect and absence of stuck buttons or axes.
3. **Audio:** speaker/headphones listening for static, device/sample-rate
   changes, underrun/drop counters and at least 15 minutes of continuous play.
4. **Window/lifecycle:** resize, native fullscreen, hide/show,
   minimize/restore, Settings, display/backing-scale changes, screenshot,
   sleep/wake and clean quit.
5. **State:** save, flush, quit, relaunch, resume, readback hash and backup
   behavior after a deliberately missing/corrupt test copy.
6. **Graphics:** Native N64, 2x and automatic resolution plus MSAA/filtering,
   with their documented restart semantics and comparison screenshots.
7. **Stability:** 30-minute warm gameplay with frame pacing, CPU, memory and
   diagnostics observations.

Gate: authentic single-player gameplay, audio, input, save/relaunch and
lifecycle behavior are accepted by a person. Build/launch/PID evidence alone is
not acceptance. Test on the oldest OS intended for the support claim as well as
the current development OS. If macOS 13 cannot be run on hardware or a suitable
VM, raise the public minimum to the oldest OS actually tested; a 13.0 load
command alone is insufficient evidence.

### Phase 6 — distributable app

1. Package a self-contained `GoldenPad.app` with icon and the same notices and
   license set as the accepted IPA.
2. Audit the bundle for ROM formats, saves, generated AOT source/assets, symbols,
   signing material, Homebrew paths, private paths and Legacy MGB64/SDL desktop
   dependencies.
3. Produce an ad-hoc-signed local developer zip first; do not call it a public
   Mac release.
4. For public direct distribution, sign with Developer ID under Hardened
   Runtime, notarize with `notarytool`, staple, run Gatekeeper assessment and
   verify the signature/entitlements again.
5. Download the hosted artifact into a clean temporary directory, repeat the
   package audit and publish/verify its SHA-256.
6. Update the README only after physical acceptance and the public artifact
   audits pass.

The required notice payload is explicit: `ThirdPartyNotices.txt`, GPL-3.0,
RT64, Plume, re-spirv, Zstandard, N64Recomp, fmt and Rabbitizer license texts.
The dependency audit should allow only expected Apple system frameworks and
`/usr/lib` libraries plus deliberately bundled, signed libraries (none are
currently expected); it should not rely on a blacklist alone.

Gate for the public claim: only then say **“GoldenPad runs natively on Apple
Silicon macOS.”** Do not claim Intel, notarization, multiplayer stability or
App Store readiness without separate evidence.

## Regression gates for the accepted mobile build

The Mac target stays isolated. After each shared-file extraction or RT64 patch
change, re-run the existing mobile verification before continuing:

1. iOS Simulator and signed iPhoneOS builds still compile from their existing
   commands.
2. Current iPhone and iPad touch-layout defaults, editor behavior and opacity
   remain unchanged.
3. Controller mapping, modern right-stick look, aim/fire and reconnect behavior
   remain unchanged.
4. `Unlock all missions` still defaults to Off for a clean install.
5. The existing IPA verifier remains green and detects no new ROM, save,
   generated proprietary code, signing material or private paths.
6. No existing preference key or save path changes without an explicit
   migration test.

Any failure is a stop gate: repair or revert the shared extraction before doing
more Mac work. Published Preview 1 behavior is not a refactoring test bed.

## Scope of the first implementation change

The first reviewable implementation should include Phase 1 and only enough of
Phase 2 to prove the native window/layer/runtime path. It should not include the
settings redesign, keyboard remapping, packaging, notarization or README support
claim. That keeps the highest-risk seam small and makes rollback straightforward.

### First implementation task graph

Execute these packets in order. Commit boundaries are recommended only after
each gate is green; do not push or publish without separate authorization.

1. **Mac build closure**
   - Add the opt-in Mac CMake branch, plist template and empty native app bundle.
   - Compile the patched AOT-only runtime archives with the explicit tool roles.
   - Link a black `MTKView` app with no ROM and no RT64 surface yet.
   - Gate: clean arm64 build, expected bundle ID, no Catalyst/JIT/Homebrew/private
     dependency or entitlement.
2. **Mac-only RT64 surface**
   - Add the isolated RT64 Mac embedded-surface overlay.
   - Establish the layer retain contract and run the 50-cycle no-ROM test.
   - Gate: resize/backing scale/display movement with no Metal validation or
     lifetime error.
3. **Runtime launch**
   - Link the existing private generated AOT/RSP outputs without copying them
     into the bundle.
   - For developer validation only, point the bridge at the existing compatible
     private TLB-free input; the UI importer comes later.
   - Gate: logos, title/menu and one mission with separate render/audio/input
     evidence.
4. **Clean runtime exit**
   - Replace the Mac outer detached worker with a joinable owner and idempotent
     `ultramodern::quit()`/join bridge.
   - Gate: 20 launch/quit application cycles with clean marker removal and no
     stranded GoldenPad process/thread.
5. **Mobile non-regression checkpoint**
   - Run existing iOS host/IPA verification without changing mobile behavior.
   - Gate: no generated diff in accepted mobile archives or app package. If a
     shared patch made one, split the Mac change back out before proceeding.

The first review stops here. Only after it is accepted should shared Swift
model extraction, Mac keyboard/mouse, ROM import UI, Settings and distribution
be layered on.

### Stop and rollback rules

- `GOLDENPAD_RECOMP_MAC` remains Off by default; deleting the Mac-only target and
  overlay restores the prior build graph.
- A failed mobile verifier stops the Mac work immediately. Revert or isolate the
  shared change before adding another feature.
- A surface lifetime failure is fixed at the ownership boundary; it is not a
  reason to rewrite RT64 or change the accepted iOS handoff speculatively.
- If the native host cannot reach the title/mission gate, compare the exact
  window/layer/runtime sequencing with the upstream SDL oracle, then stop at the
  first divergence.
- If macOS 13 runtime testing is unavailable or fails, raise the minimum OS.
  Do not work around it with unsupported Homebrew dylibs or JIT entitlements.
- Multiplayer, retail-ROM conversion, Intel, Catalyst and touch controls remain
  outside the first milestone even if their adjacent code is visible.

## Evidence and claim ladder

| Evidence reached | Allowed statement |
|---|---|
| Clean arm64/Mac compile and dependency audit | “The native Mac target builds.” |
| Signed bundle opens a native window | “The Mac build launches.” |
| Authentic mission plus audible audio and accepted input | “GoldenEye gameplay works in the Mac development build.” |
| Save/relaunch, lifecycle, graphics settings and package audit pass on physical Apple Silicon hardware | “GoldenPad supports Apple Silicon macOS.” |
| Hosted artifact is downloaded, re-audited and checksum-verified | “A Mac download is available.” |

Do not collapse these stages. None of them establishes Intel support,
notarization, App Store readiness or stable multiplayer.

## Risks and non-goals

| Risk | Handling |
|---|---|
| Mac window/layer ownership differs from UIKit | Pass `NSWindow` + `CAMetalLayer`; define the +1 retain contract and pass the no-ROM lifetime stress gate before gameplay |
| Detached outer runtime outlives a destroyed window | Give the Mac bridge a joinable worker and idempotent quit/join; keep Preview 1 to one window/process lifetime |
| Audio static may carry over | Reuse the same ring, but require Mac speaker/output listening |
| Mouse look can fight cursor/window focus | Implement capture/release explicitly and always provide Escape recovery |
| Settings drift between platforms | Share models/defaults; keep only presentation adapters platform-specific |
| Upstream SDL baseline hides packaging debt | Do not ship it; reject Homebrew/SDL dependencies in the GoldenPadMac audit |
| A 13.0 load command overstates compatibility | Inspect every shipped Mach-O and run on the oldest claimed OS; otherwise raise the minimum |
| ROM setup silently broadens the legal/data boundary | Import only user-derived TLB-free input in Preview 1; keep retail conversion out and audit the bundle/logs |
| Public AOT/runtime rights boundary | Apply the same explicit legal review and ROM-free audit used for the IPA |
| Multiplayer is already unstable | Exclude it from the first Mac support claim |

Not in the first Mac milestone: Intel support, Mac Catalyst, iCloud save sync,
multiplayer completion, App Store packaging, Developer ID notarization, or a
redesign of the accepted iPhone/iPad controls.

## Feasibility conclusion

This proved to be a **moderate product-integration project with low core-runtime
risk**. The isolated Apple-Silicon SwiftUI/AppKit target now shares GoldenPad's
accepted runtime bridges, reaches real Mac gameplay and passes its separate
Alpha package audit. The remaining work is product-quality validation and the
disclosed Mac input, far-right edge, sustained-performance, oldest-OS and
notarization debt. No renderer rewrite and no game-code rewrite are required.

## Primary references

- [GoldenEye64Recomp](https://github.com/cblock85/GoldenEye64Recomp) — existing
  macOS/N64Recomp/RT64 implementation used by the pinned reference checkout.
- [Apple: MTKView](https://developer.apple.com/documentation/metalkit/mtkview/)
- [Apple: NSViewRepresentable](https://developer.apple.com/documentation/swiftui/nsviewrepresentable)
- [Apple: SwiftUI App](https://developer.apple.com/documentation/swiftui/app)
- [Apple: Game Controller](https://developer.apple.com/documentation/gamecontroller)
- [Apple: GCKeyboard](https://developer.apple.com/documentation/gamecontroller/gckeyboard)
- [Apple: GCMouse](https://developer.apple.com/documentation/gamecontroller/gcmouse)
- [Apple: AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Apple: NSOpenPanel](https://developer.apple.com/documentation/appkit/nsopenpanel)
- [Apple: Hardened Runtime](https://developer.apple.com/documentation/security/hardened-runtime)
- [Apple: Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Apple: Preparing an app for distribution](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution)
- [CMake: CMAKE_OSX_SYSROOT](https://cmake.org/cmake/help/latest/variable/CMAKE_OSX_SYSROOT.html)
