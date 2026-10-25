#!/usr/bin/env python3
"""Build the pinned native generators and check callback names without a ROM."""
import argparse
import os
import platform
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from module_build import ROOT, generator_environment, prepare_source, run

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--jobs", type=int, choices=range(1, 17), default=4)
args = parser.parse_args()
prepare_source()
env = generator_environment()
folder = ROOT / "build-host-generator-check"
run("cmake", "--fresh", "-S", ROOT / "cmake/host-tools", "-B", folder, "-G", "Ninja",
    "-DCMAKE_BUILD_TYPE=Release", env=env)
run("cmake", "--build", folder, "--target", "N64RecompCLI", "RSPRecomp", "GoldenPadGeneratorTest",
    "--parallel", args.jobs, env=env)
run(folder / ("GoldenPadGeneratorTest.exe" if os.name == "nt" else "GoldenPadGeneratorTest"), env=env)
print(f"Native generators and callback test passed: {platform.system()} {platform.machine()}")
