#!/usr/bin/env python3
"""Build the opt-in empty iOS shell on a Mac; no ROM or generated game input."""
import argparse
import json
from pathlib import Path
import platform
import subprocess
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from module_build import ROOT, check_source, prepare_source, run


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jobs", type=int, choices=range(1, 17), default=4)
    args = parser.parse_args()
    if platform.system() != "Darwin" or platform.machine() != "arm64":
        parser.error("The Swift/Metal shell requires an Apple Silicon Mac with Xcode")
    run("xcodebuild", "-version")
    run("xcrun", "--sdk", "iphoneos", "metal", "--version")
    source = prepare_source()
    pin = json.loads((ROOT / "sources.lock.json").read_text())["components"]["rt64-ios"]
    renderer = ROOT / pin["path"]
    if not (renderer / ".git").exists():
        if renderer.exists() and any(renderer.iterdir()):
            raise ValueError(f"Preserving existing non-Git renderer directory: {renderer}")
        run("git", "-c", f"submodule.vendor/rt64-ios.url={pin['url']}", "submodule", "update", "--init", "--", pin["path"])
    check_source(renderer, pin["commit"])
    run("git", "submodule", "update", "--init", "--recursive", cwd=renderer)
    import os
    env = dict(os.environ, CMAKE_BUILD_PARALLEL_LEVEL=str(args.jobs))
    run("/bin/bash", ROOT / "scripts/build-recomp-runtime.sh", "iphoneos", env=env)
    run("/bin/bash", ROOT / "scripts/verify-rt64-ios-static.sh",
        env=dict(env, GOLDENPAD_RT64_ARTIFACT_DIR=str(ROOT / "build-module-rt64")))
    build = ROOT / "build-module-shell"
    run("cmake", "-S", ROOT, "-B", build, "-G", "Xcode", "-DCMAKE_SYSTEM_NAME=iOS",
        "-DCMAKE_OSX_SYSROOT=iphoneos", "-DCMAKE_OSX_ARCHITECTURES=arm64",
        "-DGOLDENPAD_RECOMP_PROTOTYPE=ON", "-DGOLDENPAD_MODULE_SHELL=ON",
        "-DGOLDENPAD_RECOMP_AOT_DIR=", f"-DGOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR={source}",
        f"-DGOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR={source / 'lib/N64ModernRuntime'}",
        f"-DGOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR={ROOT / 'build-runtime-iphoneos'}",
        f"-DGOLDENPAD_RECOMP_RT64_SOURCE_DIR={renderer}",
        f"-DGOLDENPAD_RECOMP_RT64_ARCHIVE_DIR={ROOT / 'build-module-rt64/iphoneos'}",
        f"-DPython3_EXECUTABLE={sys.executable}")
    run("xcodebuild", "-quiet", "-project", build / "GoldenPad.xcodeproj", "-target", "GoldenPadRecompPrototype",
        "-configuration", "Release", "-sdk", "iphoneos", "-jobs", args.jobs,
        "CODE_SIGNING_ALLOWED=NO", "CODE_SIGNING_REQUIRED=NO")
    app = build / "Release-iphoneos/GoldenPadRecompPrototype.app"
    if list(app.rglob("*.gep1")):
        raise ValueError("The empty shell contains private conversion data")
    print(f"Empty shell (release audits and device validation still required): {app}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
