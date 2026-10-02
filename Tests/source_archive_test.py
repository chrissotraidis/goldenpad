"""ROM-free source-export and manifest checks, including Apple's Python 3.9."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SourceArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="goldenpad-source-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / "fixture"
        (self.root / "scripts").mkdir(parents=True)
        for name in ("check-sources.py", "package-public-sources.py"):
            shutil.copy2(ROOT / "scripts" / name, self.root / "scripts" / name)
        self.files = {}
        for name, data in (("empty.txt", b""), ("small.txt", b"source fixture\n"),
                           ("large.txt", b"x" * (1024 * 1024 + 17))):
            (self.root / name).write_bytes(data)
            self.files[name] = {"sha256": hashlib.sha256(data).hexdigest()}
        (self.root / "alias.txt").symlink_to("small.txt")
        self.files["alias.txt"] = {"link": "small.txt"}

    def manifest(self):
        (self.root / "source-manifest.json").write_text(json.dumps({
            "app_commit": "synthetic-test-revision", "files": self.files,
        }))

    def check(self):
        return subprocess.run([sys.executable, "-B", str(self.root / "scripts/check-sources.py")],
                              text=True, capture_output=True, cwd=self.root)

    def test_archive_checks_empty_small_multichunk_and_symlink(self):
        self.manifest()
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("PASS: source archive manifest synthetic-test-revision", result.stdout)

    def test_changed_content_is_rejected(self):
        self.manifest()
        (self.root / "small.txt").write_bytes(b"changed source fixture\n")
        result = self.check()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Source content mismatch: small.txt", result.stderr)

    def test_missing_content_is_rejected(self):
        self.files["absent.txt"] = {"sha256": hashlib.sha256(b"").hexdigest()}
        self.manifest()
        result = self.check()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Source content mismatch: absent.txt", result.stderr)

    def test_wrong_symlink_is_rejected(self):
        self.files["alias.txt"] = {"link": "empty.txt"}
        self.manifest()
        result = self.check()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Source link mismatch: alias.txt", result.stderr)

    def test_export_hashes_and_verifies_tracked_fixture_only(self):
        # Empty pins are confined to this synthetic fixture, never the real lock.
        (self.root / "sources.lock.json").write_text('{"components": {}}\n')
        (self.root / ".gitignore").write_text("dist/\nignored.txt\n")
        (self.root / "ignored.txt").write_text("ignored source fixture\n")
        (self.root / "untracked.txt").write_text("untracked source fixture\n")
        def git(*args):
            return subprocess.check_output(["git", "-C", str(self.root), *args],
                                           text=True, stderr=subprocess.PIPE).strip()
        git("init", "--quiet")
        git("add", "scripts", "sources.lock.json", ".gitignore", *self.files)
        git("-c", "user.name=Source Fixture", "-c", "user.email=fixture@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "Synthetic source fixture")
        # The exporter's python3 child must use the same interpreter under test.
        shim = Path(self.temporary.name) / "bin"
        shim.mkdir()
        (shim / "python3").symlink_to(sys.executable)
        env = dict(os.environ, PATH=str(shim) + os.pathsep + os.environ.get("PATH", ""),
                   PYTHONDONTWRITEBYTECODE="1")
        command = [sys.executable, "-B", str(self.root / "scripts/package-public-sources.py")]
        result = subprocess.run(command, cwd=self.root, env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        archives = list((self.root / "dist").glob("*.tar.gz"))
        self.assertEqual(len(archives), 1)
        archive = archives[0]
        first_bytes = archive.read_bytes()
        expected = hashlib.sha256(first_bytes).hexdigest() + "  " + archive.name + "\n"
        self.assertEqual(archive.with_suffix(archive.suffix + ".sha256").read_text(), expected)
        with tarfile.open(archive) as tar:
            names = set(tar.getnames())
            manifest = json.load(tar.extractfile("GoldenPad-source/source-manifest.json"))
            self.assertNotIn("GoldenPad-source/ignored.txt", names)
            self.assertNotIn("GoldenPad-source/untracked.txt", names)
            self.assertEqual(manifest["app_commit"], git("rev-parse", "HEAD"))
            for name, entry in self.files.items():
                self.assertEqual(manifest["files"][name], entry)
            exported_check = Path(self.temporary.name) / "exported"
            exported_check.mkdir()
            # Fixture-only archive generated above; no downloaded or private input.
            tar.extractall(exported_check)
        check = subprocess.run([sys.executable, "-B", str(exported_check / "GoldenPad-source/scripts/check-sources.py")],
                               text=True, capture_output=True)
        self.assertEqual(check.returncode, 0, check.stderr)
        repeat = subprocess.run(command, cwd=self.root, env=env, text=True, capture_output=True)
        self.assertEqual(repeat.returncode, 0, repeat.stderr)
        self.assertEqual(archive.read_bytes(), first_bytes)


if __name__ == "__main__":
    unittest.main()
