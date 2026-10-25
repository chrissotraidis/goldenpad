#!/usr/bin/env python3
"""Build a private GoldenPad iOS module using PadMint's open-source toolchain."""
import argparse
import os
from pathlib import Path
import subprocess
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from module_build import ROOT, check_patch_tools, configure_cli_streams, generate, generator_environment, normalize_rom, prepare_source, run


def main():
    configure_cli_streams()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rom", type=Path, required=True)
    parser.add_argument("--toolchain", type=Path)
    parser.add_argument("--llvm", type=Path, default=os.environ.get("PADMINT_LLVM_ROOT"))
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build-game-module")
    parser.add_argument("--generate-only", action="store_true")
    parser.add_argument("--jobs", type=int, choices=range(1, 17), default=4)
    args = parser.parse_args()
    if not args.generate_only and (not args.toolchain or not args.toolchain.is_file()):
        parser.error("--toolchain must name PadMint's existing iOS module toolchain")
    if not args.llvm or not args.llvm.is_dir():
        parser.error("PadMint must supply PADMINT_LLVM_ROOT, or pass --llvm with its LLVM folder")
    if args.rom.stat().st_size != 0xC00000:
        parser.error("Supply your supported 12 MiB US retail GoldenEye 007 ROM.")
    rom = normalize_rom(args.rom.read_bytes())
    check_patch_tools(args.llvm.resolve(), os.environ)
    env = generator_environment()
    source = prepare_source()
    work = args.build_dir.resolve()
    work.mkdir(parents=True, exist_ok=True)
    generated = generate(source, rom, work, args.llvm.resolve(), args.jobs, env)
    if args.generate_only:
        return
    run("cmake", "--fresh", "-S", ROOT / "cmake/game-module", "-B", work / "module", "-G", "Ninja",
        f"-DCMAKE_TOOLCHAIN_FILE={args.toolchain.resolve()}", "-DCMAKE_BUILD_TYPE=Release",
        f"-DGOLDENPAD_GENERATED={generated}", f"-DPython3_EXECUTABLE={sys.executable}")
    run("cmake", "--build", work / "module", "--parallel", args.jobs)
    print(f"Private module: {work / 'module/GoldenPadGame.dylib'}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
