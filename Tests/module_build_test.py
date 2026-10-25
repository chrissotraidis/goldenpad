"""Portable conversion and complete-output freshness; no real game inputs."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import module_build as build


class IsolatedPythonTests(unittest.TestCase):
    def test_entry_points_can_import_helpers_under_isolated_python(self):
        for script in ("build-game-module.py", "build-module-shell.py", "check-host-generators.py"):
            with self.subTest(script=script):
                result = subprocess.run([sys.executable, "-I", str(build.ROOT / "scripts" / script), "--help"],
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
        result = subprocess.run([sys.executable, "-I", str(build.ROOT / "scripts/module-identity.py")],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), build.identity())


class ConversionTests(unittest.TestCase):
    def setUp(self):
        self.source = b"0123456789"
        self.patch = b"GEP1" + struct.pack("<II", 10, 6) + b"\0" + struct.pack("<II", 2, 4) + b"\1" + struct.pack("<I", 2) + b"ab\xff"

    def test_copy_and_literal_operations(self):
        self.assertEqual(build.apply_gep1(self.source, self.patch), b"2345ab")

    def test_truncated_or_extra_bytes_fail(self):
        for patch in [self.patch[:end] for end in range(len(self.patch))] + [self.patch + b"extra"]:
            with self.subTest(size=len(patch)):
                with self.assertRaises(ValueError):
                    build.apply_gep1(self.source, patch)

    def test_copy_outside_input_and_target_overflow_fail(self):
        for offset, length, size in ((9, 4, 4), (2, 4, 3)):
            patch = b"GEP1" + struct.pack("<II", 10, size) + b"\0" + struct.pack("<II", offset, length) + b"\xff"
            with self.assertRaises(ValueError):
                build.apply_gep1(self.source, patch)

    def test_byte_swapped_rom_normalization_preserves_input(self):
        original = bytes.fromhex("80371240") + bytes(0xC00000 - 4)
        swapped = b"".join(original[i:i + 2][::-1] for i in range(0, len(original), 2))
        with mock.patch.object(build, "RETAIL_SHA1", hashlib.sha1(original).hexdigest()):
            self.assertEqual(build.normalize_rom(swapped), original)
        self.assertEqual(swapped[:4], bytes.fromhex("37804012"))
        with self.assertRaises(ValueError):
            build.normalize_rom(b"wrong")


class GenerationChecks(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="GoldenPad module spaces ")
        self.addCleanup(temporary.cleanup)
        self.folder = Path(temporary.name)
        names = ("RecompiledFuncs/lookup.cpp", "RecompiledFuncs/recomp_overlays.inl", "RecompiledFuncs/funcs_0.c",
                 "rsp/aspMain.cpp", "RecompiledPatches/patches.c", "RecompiledPatches/patches_bin.c",
                 "private/goldenpad_conversion_patch.c")
        for name in names:
            path = self.folder / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("synthetic\n")
        self.record = {"contract": "test-contract", "inputs": {}, "outputs": build.output_hashes(self.folder)}
        (self.folder / "module-inputs.json").write_text(json.dumps(self.record))
        patcher = mock.patch.object(build, "identity", return_value="test-contract")
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_exact_complete_generation_is_accepted(self):
        self.assertEqual(build.check_generated(self.folder), self.record)

    def test_changed_nonempty_output_is_rejected(self):
        (self.folder / "RecompiledPatches/patches.c").write_text("different nonempty output")
        with self.assertRaisesRegex(ValueError, "stale"):
            build.check_generated(self.folder)

    def test_missing_rsp_and_changed_contract_are_rejected(self):
        (self.folder / "rsp/aspMain.cpp").unlink()
        with self.assertRaises(ValueError):
            build.check_generated(self.folder)
        with mock.patch.object(build, "identity", return_value="updated-contract"):
            with self.assertRaises(ValueError):
                build.check_generated(self.folder)

    def test_future_makefile_expansion_requires_review(self):
        path = self.folder / "Makefile"
        path.write_text("CFLAGS := -target mips \\\n -O2\nLDFLAGS := $(OTHER_FLAGS)\n")
        self.assertEqual(build.make_flags(path, "CFLAGS"), ["-target", "mips", "-O2"])
        with self.assertRaises(ValueError):
            build.make_flags(path, "LDFLAGS")

    def test_failed_regeneration_preserves_previous_output_and_unique_files(self):
        work = self.folder / "work"
        original = work / "generated"
        original.mkdir(parents=True)
        (original / "personal-notes").write_text("keep this private file")
        source = self.folder / "source"
        source.mkdir()
        (source / "vanilla_to_tlbfree.gep1").write_bytes(b"invalid pinned data")
        llvm = self.folder / "llvm"
        suffix = ".exe" if build.os.name == "nt" else ""
        host = work / ("host-" + build.platform.system().lower() + "-" + build.platform.machine().lower())
        for path in (llvm / ("bin/clang" + suffix), llvm / ("bin/ld.lld" + suffix),
                     host / ("N64Recomp" + suffix), host / ("RSPRecomp" + suffix)):
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"synthetic tool")
        with mock.patch.object(build, "run"), mock.patch.object(build, "export_files"):
            with self.assertRaisesRegex(ValueError, "conversion data changed"):
                build.generate(source, b"synthetic ROM", work, llvm, 1, {})
        self.assertEqual((original / "personal-notes").read_text(), "keep this private file")
        self.assertFalse(list(work.glob("generation-*")))


if __name__ == "__main__":
    unittest.main()
