#!/usr/bin/env python3
"""Native Mac ABI and patch precedence check using synthetic code only."""
import json
from pathlib import Path
import subprocess
import tempfile
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from module_build import ROOT

RUNTIME = ROOT / "vendor/goldeneye/lib/N64ModernRuntime"
INCLUDES = [ROOT / "Support/RecompPrototype", RUNTIME / "N64Recomp/include",
            RUNTIME / "librecomp/include", RUNTIME / "ultramodern/include",
            RUNTIME / "thirdparty", RUNTIME / "thirdparty/sse2neon"]
FLAGS = ["xcrun", "clang++", "-std=c++20", '-DGOLDENPAD_MODULE_ID="test-contract"',
         *["-I" + str(path) for path in INCLUDES]]
MODULE = r'''
#include "game_module.h"
extern "C" void recomp_entrypoint(uint8_t*, recomp_context*);
extern "C" void test_host_callback(int);
static gpr address() { return 123; }
static RspExitReason audio(uint8_t*, uint32_t n) { return n == 456 ? RspExitReason::Broke : RspExitReason::Invalid; }
static void overlays() { test_host_callback(1); }
static void patches() { test_host_callback(2); }
static const uint8_t conversion[13] = {'G', 'E', 'P', '1'};
extern "C" __attribute__((visibility("default")))
const GoldenPadGameModule* goldenpad_get_game_module() {
    static GoldenPadGameModule table{goldenpad_game_module_version, sizeof(GoldenPadGameModule),
        "test-contract", address, recomp_entrypoint, audio, overlays, patches, conversion, sizeof(conversion)};
    /*MUTATE*/
    return &table;
}
'''
MAIN = r'''
#include "game_module.h"
#include <cstdio>
extern "C" void recomp_entrypoint(uint8_t*, recomp_context*);
gpr get_entrypoint_address();
RspExitReason aspMain(uint8_t*, uint32_t);
namespace zelda64 { void register_overlays(); void register_patches(); }
static int calls = 0;
extern "C" __attribute__((visibility("default"))) void test_host_callback(int n) { calls += n; }
int main(int argc, char** argv) {
    if (goldenpad_game_module_ready() || get_entrypoint_address() != 0) return 10;
    if (argc == 3) {
        if (!goldenpad_load_game_module(argv[1])) return 11;
        ++argv; --argc;
    }
    const char* error = goldenpad_load_game_module(argc > 1 ? argv[1] : nullptr);
    if (error) { std::puts(error); return 2; }
    if (!goldenpad_game_module_ready() || get_entrypoint_address() != 123) return 12;
    uint8_t bytes[1] = {0}; recomp_context ctx{};
    recomp_entrypoint(bytes, &ctx);
    if (bytes[0] != 7) return 13; // The strong patch must beat the weak original.
    if (aspMain(bytes, 456) != RspExitReason::Broke) return 14;
    zelda64::register_overlays(); zelda64::register_patches();
    if (calls != 3) return 15; // Module callbacks resolve to the one app runtime.
    const uint8_t* patch = nullptr; size_t size = 0;
    if (!goldenpad_module_conversion_patch(&patch, &size) || size != 13 || patch[0] != 'G') return 16;
    if (goldenpad_load_game_module("missing-after-success")) return 17;
}
'''


def main():
    cases = {"good": "", "bad_version": "table.version = 99;", "bad_size": "table.size = 0;",
             "bad_identity": 'table.identity = "other-build";', "null_identity": "table.identity = nullptr;",
             "null_address": "table.entrypoint_address = nullptr;", "null_entry": "table.entrypoint = nullptr;",
             "null_audio": "table.audio = nullptr;", "null_overlays": "table.register_overlays = nullptr;",
             "null_patches": "table.register_patches = nullptr;", "null_conversion": "table.conversion_patch = nullptr;",
             "oversized_conversion": "table.conversion_patch_size = 1024 * 1024 + 1;", "null_table": "return nullptr;"}
    results = {}
    with tempfile.TemporaryDirectory(prefix="GoldenPad ABI spaces ") as temporary:
        work = Path(temporary)
        (work / "main.cpp").write_text(MAIN)
        subprocess.run([*FLAGS, ROOT / "Support/RecompPrototype/game_module_loader.cpp", work / "main.cpp",
                        "-Wl,-export_dynamic", "-o", work / "loader"], check=True)
        for name, header, value in (("base", "recomp.h", 1), ("patch", "recomp_patch_attributes.h", 7)):
            path = work / (name + ".c")
            path.write_text(f'#include "{header}"\nRECOMP_FUNC void recomp_entrypoint(uint8_t* rdram, recomp_context* ctx) {{ rdram[0] = {value}; }}\n')
            subprocess.run(["xcrun", "clang", "-fvisibility=hidden", *["-I" + str(p) for p in INCLUDES],
                            "-c", path, "-o", work / (name + ".o")], check=True)
        for name, mutate in {**cases, "no_getter": "", "patch_first": ""}.items():
            path = work / (name + ".cpp")
            path.write_text(MODULE.replace("/*MUTATE*/", mutate) if name != "no_getter" else "int unused;\n")
            objects = [work / "base.o", work / "patch.o"]
            if name == "patch_first":
                objects.reverse()
            subprocess.run([*FLAGS, "-fvisibility=hidden", "-dynamiclib", "-Wl,-undefined,dynamic_lookup",
                            path, *objects, "-o", work / (name + ".dylib")], check=True)
        for name in [*cases, "no_getter", "patch_first", "missing"]:
            result = subprocess.run([work / "loader", work / (name + ".dylib")], capture_output=True, text=True)
            expected = 0 if name in ("good", "patch_first") else 2
            if result.returncode != expected:
                raise RuntimeError(f"{name}: {result.returncode}: {result.stdout} {result.stderr}")
            results[name] = result.returncode
        result = subprocess.run([work / "loader", work / "bad_identity.dylib", work / "good.dylib"], capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError("Loading a correct module after rejection failed")
        results["retry_after_rejection"] = 0
        exports = subprocess.check_output(["xcrun", "nm", "-gU", work / "good.dylib"], text=True)
        if "_recomp_entrypoint" in exports or "_goldenpad_get_game_module" not in exports:
            raise RuntimeError("Private translated functions escaped hidden module visibility")
    evidence = ROOT / "build-module-evidence"
    evidence.mkdir(exist_ok=True)
    report = {"synthetic_native_mac_abi": results, "ios_loading": "not-tested", "gameplay": "not-tested"}
    (evidence / "loader-abi.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
