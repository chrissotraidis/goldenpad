"""ROM-free actual-entrypoint argv fixtures; compatible with Apple Python 3.9.

Every build tool is fake. The RT64 fixture may traverse device proof with
synthetic files to reach the simulator, whose fake build always stops. No
fixture result establishes compilation, source-pin, shader or IPA acceptance.
"""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
STOP = 86
VALIDATION = """build_jobs=${CMAKE_BUILD_PARALLEL_LEVEL:-DEFAULT}
case "$build_jobs" in
    0*|*[!0-9]*) echo 'CMAKE_BUILD_PARALLEL_LEVEL must be a positive integer.' >&2; exit 2;;
esac
"""

# This deliberately narrow dispatcher has no fallback to real build tools.
FAKE_TOOL = r'''import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

tool = Path(sys.argv[0]).name
args = sys.argv[1:]
root = Path(os.environ["FIXTURE_ROOT"])
with (root / "calls.jsonl").open("a") as log:
    log.write(json.dumps([tool] + args) + "\n")

def output(path, data="synthetic fixture; never executable\n"):
    path = Path(path)
    if root not in path.resolve().parents:
        raise SystemExit("fixture output escaped root")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(data)

def stop():
    print("FIXTURE_COMPILATION_STOP", file=sys.stderr)
    raise SystemExit(86)

if tool == "python3":
    if args != [str(root / "scripts/check-sources.py")] and args not in (
        [str(root / "scripts/check-sources.py"), "--component", "goldeneye"],
        [str(root / "scripts/check-sources.py"), "--component", "rt64-ios"],
        [str(root / "scripts/check-sources.py"), "--component", "goldeneye", "--component", "rt64-ios"],
    ):
        raise SystemExit("unexpected Python action")
    raise SystemExit(subprocess.call([sys.executable, "-B"] + args))
elif tool == "cmake":
    if args[0] == "--build":
        build = Path(args[1])
        if build.name != "build-iphoneos" or os.environ["FIXTURE_MODE"] != "rt64-both":
            stop()
        for name in ("rt64.a", "src/contrib/plume/libplume.a",
                     "src/contrib/re-spirv/libre-spirv.a", "src/contrib/zstd/build/cmake/lib/libzstd.a"):
            output(build / name)
    elif args[0] == "-S":
        Path(args[args.index("-B") + 1]).mkdir(parents=True, exist_ok=True)
    else:
        raise SystemExit("unexpected CMake action")
elif tool == "ninja":
    if args[-3:] == ["-t", "targets", "all"]:
        for kind, count in (("metal", 56), ("spirv", 56), ("rw", 1)):
            for i in range(count):
                print("src/shaders/fixture%d.%s.c: CUSTOM_COMMAND" % (i, kind))
    else:
        if os.environ["FIXTURE_MODE"] == "rt64-host-stop":
            stop()
        host = Path(args[args.index("-C") + 1])
        for kind, count in (("metal", 56), ("spirv", 56), ("rw", 1)):
            for i in range(count):
                base = host / "src/shaders" / ("fixture%d.%s" % (i, kind))
                output(str(base) + ".c", "extern const char fixture_array[];\n")
                if kind == "metal":
                    output(base)
        generator = host / "src/tools/file_to_c/file_to_c"
        generator.parent.mkdir(parents=True, exist_ok=True)
        generator.symlink_to(root / "bin/file_to_c")
elif tool == "rsync":
    source, dest = map(Path, args[-2:])
    for kind in ("spirv", "rw"):
        for path in source.rglob("*." + kind + ".c"):
            output(dest / path.relative_to(source), path.read_text())
elif tool == "xcrun":
    sdk = args[args.index("-sdk") + 1]
    action = args[args.index("-sdk") + 2]
    if action == "metal":
        output(args[args.index("-o") + 1])
    elif action == "metallib":
        suffix = "-simulator" if sdk == "iphonesimulator" else ""
        output(args[args.index("-o") + 1], "air64_vfixtureapple-ios17.0.0" + suffix + "\n")
    elif action == "nm":
        if "-gU" in args:
            print("_goldenpad_rt64_depth_format_rebuild_stats")
    elif action == "ar":
        count = 210 if Path(args[-1]).name == "rt64.a" else 12
        print("fixture.o\n" * count, end="")
    elif action == "clang++":
        output(args[args.index("-o") + 1])
    else:
        raise SystemExit("unexpected xcrun action")
elif tool == "file_to_c":
    output(args[2])
    output(args[3])
elif tool == "lipo":
    print("arm64")
elif tool == "otool":
    print(args[-1] + ":\n /fixture/Foundation (fixture)")
elif tool == "shasum":
    path = Path(args[-1])
    digest = ("7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959"
              if path == root / "fixture-rom.txt" and os.environ["FIXTURE_MODE"] != "bad-rom"
              else hashlib.sha256(path.read_bytes()).hexdigest())
    print(digest + "  " + str(path))
elif tool == "xcodebuild":
    stop()
elif tool in ("brew", "clang", "ld.lld", "git", "make", "patch"):
    raise SystemExit("unexpected dependency/source/compiler action: " + tool)
else:
    raise SystemExit("unknown fixture tool: " + tool)
'''


class BuildParallelTests(unittest.TestCase):
    def setUp(self):
        # Keep all writes inside the authorized sidecar, including shell mktemp.
        self.temporary = tempfile.TemporaryDirectory(prefix=".parallel-fixture-", dir=ROOT)
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for name in ("scripts", "bin", "tmp", "inputs", "vendor/rt64-ios", "Support/RT64"):
            (self.root / name).mkdir(parents=True)
        for name in ("generate-recomp-inputs.sh", "build-recomp-runtime.sh",
                     "verify-rt64-ios-static.sh", "build-recomp-apple.sh",
                     "mips-llvm.sh", "check-sources.py"):
            shutil.copy2(ROOT / "scripts" / name, self.root / "scripts" / name)
        token = b"public synthetic source fixture\n"
        (self.root / "source-token.txt").write_bytes(token)
        (self.root / "source-manifest.json").write_text(json.dumps({
            "app_commit": "synthetic-argv-fixture",
            "files": {"source-token.txt": {"sha256": hashlib.sha256(token).hexdigest()}},
        }))
        (self.root / "fixture-rom.txt").write_text("dummy text, not a ROM\n")
        dispatcher = self.root / "bin/fixture-tool"
        dispatcher.write_text("#!" + sys.executable + "\n" + FAKE_TOOL)
        dispatcher.chmod(0o755)
        for name in ("python3", "cmake", "ninja", "rsync", "xcrun", "file_to_c",
                     "lipo", "otool", "shasum", "xcodebuild", "brew", "clang",
                     "ld.lld", "git", "make", "patch"):
            (self.root / "bin" / name).symlink_to(dispatcher)

    def run_entrypoint(self, name, limit=None, mode="stop", args=None, extra=None):
        # No os.environ inheritance: exclude user build paths, toolchains, SDK,
        # diagnostic switches, job settings, Python hooks and shell startup files.
        env = {"PATH": str(self.root / "bin") + ":/usr/bin:/bin", "LC_ALL": "C",
               "TMPDIR": str(self.root / "tmp"), "PYTHONDONTWRITEBYTECODE": "1",
               "FIXTURE_ROOT": str(self.root), "FIXTURE_MODE": mode,
               "GOLDENPAD_MIPS_CC": str(self.root / "bin/clang"),
               "GOLDENPAD_MIPS_LD": str(self.root / "bin/ld.lld")}
        if limit is not None:
            env["CMAKE_BUILD_PARALLEL_LEVEL"] = limit
        env.update(extra or {})
        if args is None:
            args = {"generate-recomp-inputs.sh": [str(self.root / "fixture-rom.txt"), str(self.root / "private-output")],
                    "build-recomp-runtime.sh": ["iphoneos"],
                    "build-recomp-apple.sh": ["ios", str(self.root / "inputs")],
                    "verify-rt64-ios-static.sh": []}[name]
        log = self.root / "calls.jsonl"
        log.write_text("")
        # The RT64 fixture starts many Apple Python processes; allow startup
        # overhead on busy hosts without changing any command or output checks.
        result = subprocess.run(["/bin/bash", str(self.root / "scripts" / name)] + args,
                                cwd=self.root, env=env, text=True, capture_output=True, timeout=120)
        calls = [json.loads(line) for line in log.read_text().splitlines()]
        self.assertFalse((self.root / "private-output").exists(), "must stop before private input generation")
        self.assertFalse(list((self.root / "tmp").iterdir()), "RT64 probe trap must clean fixture outputs")
        return result, calls

    def assert_stop(self, result, rt64=False):
        self.assertEqual(result.returncode, 1 if rt64 else STOP, result.stdout + result.stderr)
        self.assertIn("FIXTURE_COMPILATION_STOP", result.stderr)

    def assert_jobs(self, call, flag, value):
        if value is None:
            self.assertNotIn(flag, call)
        else:
            self.assertEqual(call.count(flag), 1, call)
            self.assertEqual(call[call.index(flag) + 1], value, call)

    def check_limits(self, limit):
        selected = limit or "8"
        for name, arguments in (
            ("generate-recomp-inputs.sh", None),
            ("build-recomp-runtime.sh", ["iphoneos"]),
            ("build-recomp-runtime.sh", ["iphonesimulator"]),
            ("build-recomp-runtime.sh", ["macosx"]),
            ("build-recomp-apple.sh", ["ios", str(self.root / "inputs")]),
            ("build-recomp-apple.sh", ["macos", str(self.root / "inputs")]),
        ):
            with self.subTest(name=name, args=arguments, limit=limit):
                result, calls = self.run_entrypoint(name, limit, args=arguments)
                self.assert_stop(result)
                build = [c for c in calls if c[0] == "xcodebuild" or c[:2] == ["cmake", "--build"]]
                self.assertEqual(len(build), 1, calls)
                self.assert_jobs(build[0], "-jobs" if build[0][0] == "xcodebuild" else "--parallel",
                                 (limit or None) if build[0][0] == "xcodebuild" else selected)
                self.assertLess(next(i for i, c in enumerate(calls) if c[0] == "python3"),
                                next(i for i, c in enumerate(calls) if c[0] == "cmake"))
                if build[0][0] == "xcodebuild":
                    platform = arguments[0]
                    expected = ["xcodebuild", "-quiet"] + (["-jobs", limit] if limit else [])
                    expected += ["-project", str(self.root / ("build-maintained-" + platform) / "GoldenPad.xcodeproj"),
                                 "-target", "GoldenPadRecompPrototype" if platform == "ios" else "GoldenPadMac",
                                 "-configuration", "Release", "-sdk", "iphoneos" if platform == "ios" else "macosx",
                                 "CODE_SIGNING_ALLOWED=NO", "build"]
                    self.assertEqual(build[0], expected)
        with self.subTest(name="verify-rt64-ios-static.sh", limit=limit):
            result, calls = self.run_entrypoint("verify-rt64-ios-static.sh", limit, "rt64-both")
            self.assert_stop(result, rt64=True)
            ninja = [c for c in calls if c[0] == "ninja" and "-t" not in c]
            self.assertEqual(len(ninja), 1)
            with self.subTest(tool="shader-ninja"):
                self.assert_jobs(ninja[0], "-j", limit or None)
                host = ninja[0][ninja[0].index("-C") + 1]
                targets = sorted("src/shaders/fixture%d.%s.c" % (i, kind)
                                 for kind, count in (("metal", 56), ("spirv", 56), ("rw", 1))
                                 for i in range(count))
                self.assertEqual(ninja[0], ["ninja"] + (["-j", limit] if limit else []) + ["-C", host] + targets)
            builds = [c for c in calls if c[:2] == ["cmake", "--build"]]
            self.assertEqual([Path(c[2]).name for c in builds], ["build-iphoneos", "build-iphonesimulator"])
            for build in builds:
                with self.subTest(sdk=Path(build[2]).name):
                    self.assert_jobs(build, "--parallel", selected)
            # Device proof is synthetic; simulator stops before proof or copying.
            self.assertEqual(len([c for c in calls if c[0] == "xcrun" and "clang++" in c]), 1)
            self.assertEqual(len([c for c in calls if c[0] == "file_to_c"]), 112)

    def test_requested_limits(self):
        self.check_limits("3")

    def test_unset_defaults(self):
        self.check_limits(None)

    def test_empty_defaults(self):
        self.check_limits("")

    def test_single_and_multi_digit_limits(self):
        for value in ("1", "12"):
            with self.subTest(value=value):
                result, calls = self.run_entrypoint("build-recomp-runtime.sh", value)
                self.assert_stop(result)
                self.assert_jobs(calls[-1], "--parallel", value)

    def test_invalid_limits_fail_before_tools_or_outputs(self):
        for value in ("0", "00", "03", "-1", "+3", "1.5", " 3", "3 ", "two", "3\n", "3;false"):
            for name in ("generate-recomp-inputs.sh", "build-recomp-runtime.sh",
                         "verify-rt64-ios-static.sh", "build-recomp-apple.sh"):
                with self.subTest(value=value, name=name):
                    # Deliberately invalid inputs to demonstrate job validation wins.
                    args = ["ios", str(self.root / "missing")] if name == "build-recomp-apple.sh" else None
                    result, calls = self.run_entrypoint(name, value, args=args)
                    self.assertEqual(result.returncode, 2, result.stderr)
                    self.assertIn("CMAKE_BUILD_PARALLEL_LEVEL must be a positive integer.", result.stderr)
                    self.assertEqual(calls, [])
                    self.assertFalse(list(self.root.glob("build-*")))

    def test_shader_compilation_error_stops_before_sdk_builds(self):
        result, calls = self.run_entrypoint("verify-rt64-ios-static.sh", "4", "rt64-host-stop")
        self.assert_stop(result, rt64=True)
        self.assert_jobs(calls[-1], "-j", "4")
        self.assertFalse(any(c[0] == "xcrun" or c[:2] == ["cmake", "--build"] for c in calls))

    def test_device_compilation_error_stops_before_simulator(self):
        result, calls = self.run_entrypoint("verify-rt64-ios-static.sh", "4", "rt64-device-stop")
        self.assert_stop(result, rt64=True)
        builds = [c for c in calls if c[:2] == ["cmake", "--build"]]
        self.assertEqual(len(builds), 1)
        self.assertEqual(Path(builds[0][2]).name, "build-iphoneos")
        self.assert_jobs(builds[0], "--parallel", "4")
        self.assertFalse(any(c[0] == "xcrun" and "clang++" in c for c in calls))

    def test_usage_and_sdk_errors(self):
        for name, args, message in (
            ("generate-recomp-inputs.sh", [], "Usage:"),
            ("build-recomp-apple.sh", [], "Usage:"),
            ("build-recomp-runtime.sh", ["invalid-sdk"], "SDK must be"),
        ):
            with self.subTest(name=name):
                result, calls = self.run_entrypoint(name, "3", args=args)
                self.assertEqual(result.returncode, 2)
                self.assertIn(message, result.stderr)
                self.assertEqual(calls, [])

    def test_existing_output_and_wrong_rom_are_rejected(self):
        for args, mode, message, tools in (
            ([str(self.root / "fixture-rom.txt"), str(self.root / "inputs")], "stop", "Output must be new", []),
            (None, "bad-rom", "Unsupported prepared ROM", ["shasum"]),
        ):
            result, calls = self.run_entrypoint("generate-recomp-inputs.sh", "3", mode, args)
            self.assertEqual(result.returncode, 1)
            self.assertIn(message, result.stderr)
            self.assertEqual([c[0] for c in calls], tools)

    def test_missing_inputs_and_bad_platform_preserve_early_errors(self):
        for args, code, tools in (
            (["ios", str(self.root / "missing")], 1, []),
            (["invalid-platform", str(self.root / "inputs")], 2, ["python3"]),
        ):
            result, calls = self.run_entrypoint("build-recomp-apple.sh", "3", args=args)
            self.assertEqual(result.returncode, code)
            self.assertEqual([c[0] for c in calls], tools)

    def test_real_source_guard_failure_precedes_configure(self):
        (self.root / "source-token.txt").write_text("corrupted fixture source\n")
        for name in ("generate-recomp-inputs.sh", "build-recomp-runtime.sh",
                     "verify-rt64-ios-static.sh", "build-recomp-apple.sh"):
            with self.subTest(name=name):
                result, calls = self.run_entrypoint(name, "3")
                self.assertEqual(result.returncode, 1)
                self.assertIn("Source content mismatch: source-token.txt", result.stderr)
                self.assertFalse(any(c[0] in ("cmake", "ninja", "xcrun", "xcodebuild") for c in calls))


class ProductionByteTests(unittest.TestCase):
    def test_non_job_bytes_match_initial_head(self):
        # SHA256 of the complete original scripts at 90160c54. Undo only the
        # exact permitted job edits; every other byte, including guards, source
        # checks, helper order, configure, proof and packaging, must still match.
        originals = {
            "generate-recomp-inputs.sh": "dd4b414cf4b2bbdc7103add460aa0f80bb2a471b452b58165ac2a1511d8d6948",
            "build-recomp-runtime.sh": "d8dac6f516f9030da8bcb98b7ebc9d96af6574f6c97fc2bffdf16638e256ced9",
            "verify-rt64-ios-static.sh": "70fd0f4b9bf570e15e2dfaa9a4d3b492d541f1ae26307773ca2fd1b82557bff8",
            "build-recomp-apple.sh": "03a1f90a595369362a7946da76bd794c75cf64cb35c6fc2528d2ee44cd597992",
        }
        for name, digest in originals.items():
            with self.subTest(name=name):
                data = (ROOT / "scripts" / name).read_bytes()
                default = "" if name == "build-recomp-apple.sh" else "8"
                block = VALIDATION.replace("DEFAULT", default).encode()
                self.assertEqual(data.count(block), 1)
                data = data.replace(block, b"")
                data = data.replace(b'--parallel "$build_jobs"', b'--parallel 8')
                data = data.replace(b' ${CMAKE_BUILD_PARALLEL_LEVEL:+-j "$build_jobs"}', b"")
                data = data.replace(b' ${build_jobs:+-jobs "$build_jobs"}', b"")
                self.assertEqual(hashlib.sha256(data).hexdigest(), digest)


if __name__ == "__main__":
    unittest.main()
