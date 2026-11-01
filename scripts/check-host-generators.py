#!/usr/bin/env python3
"""Build the pinned native generators and check callback names without a ROM."""
import argparse
import json
import os
import platform
from pathlib import Path
import sys
import struct
import tempfile
sys.path.insert(0, str(Path(__file__).resolve().parent))
from module_build import ROOT, generator_environment, prepare_source, run


def check_paths(folder):
    """Exercise real CLI, TOML and output paths using public instructions only."""
    suffix = ".exe" if os.name == "nt" else ""
    with tempfile.TemporaryDirectory(prefix="GoldenPad paths \u96ea ") as temporary:
        work = Path(temporary).resolve()
        name = lambda filename: json.dumps(str(work / filename), ensure_ascii=False)
        # addiu v0,zero,7; jr ra; addiu v0,v0,1.
        (work / "cpu \u96ea.bin").write_bytes(bytes(0x1000) + struct.pack(">3I", 0x24020007, 0x03E00008, 0x24420001))
        (work / "symbols \u96ea.toml").write_text('''[[section]]
name = ".text"
rom = 0x1000
vram = 0x80001000
size = 12
functions = [{ name = "recomp_entrypoint", vram = 0x80001000, rom = 0x1000, size = 12 }]
''', encoding="utf-8")
        config = work / "cpu \u96ea.toml"
        config.write_text('[input]\nentrypoint = 0x80001000\nsymbols_file_path = ' + name("symbols \u96ea.toml")
                          + '\nrom_file_path = ' + name("cpu \u96ea.bin")
                          + '\noutput_func_path = ' + name("output \u96ea") + '\n', encoding="utf-8")
        run(folder / ("N64Recomp" + suffix), config, cwd=work)
        generated = list((work / "output \u96ea").glob("funcs_*.c"))
        if len(generated) != 1 or b"recomp_entrypoint" not in generated[0].read_bytes():
            raise RuntimeError("The public CPU path probe did not produce its function")
        (work / "rsp \u96ea.bin").write_bytes(struct.pack(">I", 13))  # RSP BREAK.
        config = work / "rsp \u96ea.toml"
        config.write_text('text_offset = 0\ntext_size = 4\ntext_address = 0x04001000\nrom_file_path = '
                          + name("rsp \u96ea.bin") + '\noutput_file_path = ' + name("rsp \u96ea.cpp")
                          + '\noutput_function_name = "synthetic_audio"\n', encoding="utf-8")
        run(folder / ("RSPRecomp" + suffix), config, cwd=work)
        if b"RspExitReason::Broke" not in (work / "rsp \u96ea.cpp").read_bytes():
            raise RuntimeError("The public RSP path probe did not emit BREAK")


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--jobs", type=int, choices=range(1, 17), default=4)
parser.add_argument("--build", type=Path, help="Use a separate local build directory")
args = parser.parse_args()
prepare_source()
os.environ["GOLDENPAD_UNICODE_ENV_PROBE"] = "public \u96ea value"
env = generator_environment()
if env.get("GOLDENPAD_UNICODE_ENV_PROBE") != "public \u96ea value":
    raise RuntimeError("Visual Studio setup corrupted a non-English environment value")
folder = (args.build or ROOT / "build-host-generator-check").resolve()
run("cmake", "--fresh", "-S", ROOT / "cmake/host-tools", "-B", folder, "-G", "Ninja",
    "-DCMAKE_BUILD_TYPE=Release", env=env)
run("cmake", "--build", folder, "--target", "N64RecompCLI", "RSPRecomp", "GoldenPadGeneratorTest",
    "--parallel", args.jobs, env=env)
run(folder / ("GoldenPadGeneratorTest.exe" if os.name == "nt" else "GoldenPadGeneratorTest"), env=env)
check_paths(folder)
print(f"Native generators and callback test passed: {platform.system()} {platform.machine()}")
