"""Portable private generation for the pinned GoldenPad runtime; standard library only."""
import concurrent.futures
import hashlib
import io
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import struct
import subprocess
import sys
import tarfile
import tempfile
import uuid

ROOT = Path(__file__).resolve().parents[1]
RETAIL_SHA1 = "abe01e4aeb033b6c0836819f549c791b26cfde83"
CONVERTED_SHA256 = "7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959"
PATCH_SHA256 = "5a079d5b3750afcb027e46367e318b884eadabbd238a450a70f95e3976ded263"
HEADERS_PIN = "c4356466796c697dfd298010b9bed261f9ed8c6a"


def run(*args, cwd=ROOT, env=None):
    subprocess.run([str(arg) for arg in args], cwd=cwd, env=env, check=True)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def identity():
    paths = [ROOT / "sources.lock.json", ROOT / "CMakeLists.txt",
             ROOT / "cmake/game-module/CMakeLists.txt", ROOT / "cmake/host-tools/CMakeLists.txt",
             ROOT / "cmake/host-tools/windows-utf8.manifest",
             ROOT / "cmake/ModuleIdentity.cmake", ROOT / "scripts/module_build.py",
             ROOT / "scripts/module-identity.py", ROOT / "scripts/build-game-module.py",
             *list((ROOT / "patches").glob("*.patch")),
             *[p for p in (ROOT / "Support/RecompPrototype").rglob("*") if p.suffix in (".h", ".hpp", ".cpp", ".mm")]]
    digest = hashlib.sha256()
    for path in sorted(paths, key=lambda p: p.relative_to(ROOT).as_posix()):
        digest.update(path.relative_to(ROOT).as_posix().encode() + b"\0")
        digest.update(path.read_bytes().replace(b"\r\n", b"\n") + b"\0")
    return digest.hexdigest()


def check_source(path, pin):
    actual = subprocess.check_output(["git", "-C", str(path), "rev-parse", "HEAD"], text=True).strip()
    if actual != pin:
        raise ValueError(f"Preserving source at a different revision: {path}")
    dirty = subprocess.check_output(["git", "-C", str(path), "status", "--porcelain",
                                     "--untracked-files=no", "--ignore-submodules=all"], text=True)
    if dirty.strip():
        raise ValueError(f"Preserving modified source: {path}")


def prepare_source():
    pin = json.loads((ROOT / "sources.lock.json").read_text())["components"]["goldeneye"]
    source = ROOT / pin["path"]
    if not (source / ".git").exists():
        if source.exists() and any(source.iterdir()):
            raise ValueError(f"Preserving existing non-Git source directory: {source}")
        # A shared maintainer checkout may have a local submodule URL override.
        # Use the tracked URL for this command without rewriting shared Git config.
        run("git", "-c", "core.autocrlf=false", "-c", f"submodule.vendor/goldeneye.url={pin['url']}",
            "submodule", "update", "--init", "--", pin["path"])
    check_source(source, pin["commit"])
    headers = source / "lib/ge"
    if not (headers / ".git").exists():
        if headers.exists() and any(headers.iterdir()):
            raise ValueError(f"Preserving existing non-Git header directory: {headers}")
        run("git", "-c", "core.autocrlf=false", "submodule", "update", "--init", "--", "lib/ge", cwd=source)
    check_source(headers, HEADERS_PIN)
    return source


def generator_environment():
    env = dict(os.environ)
    if os.name != "nt" or shutil.which("cl", path=env.get("PATH")):
        return env
    installer = Path(env.get("ProgramFiles(x86)", r"C:\Program Files (x86)")) / "Microsoft Visual Studio/Installer/vswhere.exe"
    if not installer.is_file():
        raise ValueError("Install Visual Studio Build Tools with Desktop development with C++ and a Windows SDK, then try again.")
    arm_host = platform.machine().lower() in ("arm64", "aarch64")
    requirements = ["-requires", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64"]
    if arm_host:
        requirements = ["-requiresAny", *requirements, "Microsoft.VisualStudio.Component.VC.Tools.ARM64"]
    installation = subprocess.check_output([str(installer), "-latest", "-products", "*", *requirements,
                                            "-property", "installationPath"], text=True).strip()
    versions = sorted((Path(installation) / "VC/Tools/MSVC").glob("*"), reverse=True)
    arm = arm_host and any(
        (version / "bin/Hostarm64/arm64/cl.exe").is_file() for version in versions)
    arch = "arm64" if arm else "x64"
    if not any((version / f"bin/Host{arch}/{arch}/cl.exe").is_file() for version in versions):
        raise ValueError(f"Visual Studio is missing its {arch} C++ compiler; add Desktop development with C++ and a Windows SDK.")
    script = Path(installation) / "VC/Auxiliary/Build/vcvarsall.bat"
    command = subprocess.list2cmdline([env.get("COMSPEC", "cmd.exe")]) + f' /d /s /c ""{script}" {arch} >nul && set"'
    result = subprocess.run(command, capture_output=True, text=True, check=True, env=env)
    for line in result.stdout.splitlines():
        key, separator, value = line.partition("=")
        if separator and key:
            existing = next((name for name in env if name.casefold() == key.casefold()), key)
            env[existing] = value
    if not shutil.which("cl", path=env.get("Path", env.get("PATH"))):
        raise ValueError("Visual Studio could not prepare its C++ compiler. Check the Windows SDK components.")
    return env


def normalize_rom(data):
    if len(data) != 0xC00000:
        raise ValueError("Supply your supported 12 MiB US retail GoldenEye 007 ROM.")
    if data[:4] == b"\x37\x80\x40\x12":
        data = b"".join(data[i:i + 2][::-1] for i in range(0, len(data), 2))
    elif data[:4] == b"\x40\x12\x37\x80":
        data = b"".join(data[i:i + 4][::-1] for i in range(0, len(data), 4))
    if hashlib.sha1(data).hexdigest() != RETAIL_SHA1:
        raise ValueError("The ROM is not the supported US retail revision; your original file was not changed.")
    return data


def patch_tools(llvm, env):
    suffix = ".exe" if os.name == "nt" else ""
    compiler = Path(env.get("PADMINT_MIPS_CC", str(llvm / ("bin/clang" + suffix))))
    linker = llvm / ("bin/ld.lld" + suffix)
    for tool in (compiler, linker):
        if not tool.is_file():
            raise ValueError(f"PadMint's patch tool is missing: {tool}")
    return compiler, linker


def check_patch_tools(llvm, env):
    """Check real MIPS2/o32 code generation before fetching or translating inputs."""
    compiler, linker = patch_tools(llvm, env)
    targets = subprocess.check_output([str(compiler), "--print-targets"], text=True, env=env)
    if not re.search(r"^\s*mips\s+-", targets, re.M):
        raise ValueError("This LLVM compiler has no MIPS backend. GoldenPad needs PadMint's mips-clang tool "
                         "(PADMINT_MIPS_CC); its normal iOS compiler can remain unchanged.")
    with tempfile.TemporaryDirectory(prefix="GoldenPad MIPS probe ") as temporary:
        folder = Path(temporary)
        source, obj, linked = folder / "probe.c", folder / "probe.o", folder / "linked.o"
        source.write_text("int goldenpad_probe(int value) { return value * 3 + 7; }\n")
        run(compiler, "-target", "mips", "-mips2", "-mabi=32", "-mno-abicalls", "-G0",
            "-mno-odd-spreg", "-mno-check-zero-division", "-c", source, "-o", obj, env=env)
        run(linker, "-m", "elf32btsmip", "-r", obj, "-o", linked, env=env)
        header = linked.read_bytes()[:52]
        if (len(header) != 52 or header[:6] != b"\x7fELF\x01\x02" or header[18:20] != b"\0\x08"
                or int.from_bytes(header[36:40], "big") & 0xF000F000 != 0x10001000):
            raise ValueError("Patch tools did not produce the required big-endian MIPS2/o32 ELF")


def apply_gep1(source, patch):
    """Bounded COPY/DATA conversion, matching the existing on-device importer."""
    if len(patch) < 13 or len(patch) > 1024 * 1024 or patch[:4] != b"GEP1":
        raise ValueError("Invalid GEP1 conversion data")
    source_size, target_size = struct.unpack_from("<II", patch, 4)
    if source_size != len(source) or target_size > 32 * 1024 * 1024:
        raise ValueError("Invalid GEP1 conversion sizes")
    out = bytearray()
    cursor = 12
    while cursor < len(patch):
        operation = patch[cursor]
        cursor += 1
        if operation == 255:
            if cursor != len(patch) or len(out) != target_size:
                break
            return bytes(out)
        if operation == 0 and cursor + 8 <= len(patch):
            offset, count = struct.unpack_from("<II", patch, cursor)
            cursor += 8
            if offset + count > len(source):
                break
            fragment = source[offset:offset + count]
        elif operation == 1 and cursor + 4 <= len(patch):
            count, = struct.unpack_from("<I", patch, cursor)
            cursor += 4
            if cursor + count > len(patch):
                break
            fragment = patch[cursor:cursor + count]
            cursor += count
        else:
            break
        if len(out) + len(fragment) > target_size:
            break
        out.extend(fragment)
    raise ValueError("Invalid or incomplete GEP1 conversion data")


def export_files(source, destination, paths):
    archive = subprocess.check_output(["git", "-C", str(source), "archive", "HEAD", "--", *paths])
    with tarfile.open(fileobj=io.BytesIO(archive)) as bundle:
        for member in bundle:
            relative = Path(member.name)
            if relative.is_absolute() or ".." in relative.parts or not (member.isfile() or member.isdir()):
                raise ValueError(f"Unsupported source archive entry: {member.name}")
            path = destination / relative
            if member.isdir():
                path.mkdir(parents=True, exist_ok=True)
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                with bundle.extractfile(member) as stream:
                    path.write_bytes(stream.read())


def embed_bytes(data, name, folder):
    folder.mkdir(parents=True, exist_ok=True)
    # Signed bytes match the pinned file_to_c tool on every host.
    values = ",".join(str(byte if byte < 128 else byte - 256) for byte in data)
    (folder / (name + ".c")).write_text(f"extern const char {name}[{len(data)}];\nconst char {name}[{len(data)}] = {{{values}}};\n")
    (folder / (name + ".h")).write_text(f'#ifdef __cplusplus\nextern "C" {{\n#endif\nextern const char {name}[{len(data)}];\n#ifdef __cplusplus\n}}\n#endif\n')


def make_flags(makefile, name):
    text = makefile.read_text().replace("\\\n", " ")
    match = re.search(r"^" + re.escape(name) + r"\s*:=\s*(.*)$", text, re.M)
    if not match or "$" in match.group(1):
        raise ValueError(f"Pinned patch Makefile has an unsupported {name}; review its build rules")
    return shlex.split(match.group(1))


def output_hashes(folder):
    return {path.relative_to(folder).as_posix(): sha256(path)
            for path in sorted(folder.rglob("*")) if path.is_file() and path.name != "module-inputs.json"}


def check_generated(folder):
    record = json.loads((folder / "module-inputs.json").read_text())
    if record.get("contract") != identity() or record.get("outputs") != output_hashes(folder):
        raise ValueError("Generated module inputs are stale or changed; run build-game-module.py with your supported ROM again.")
    required = ("RecompiledFuncs/lookup.cpp", "RecompiledFuncs/recomp_overlays.inl", "rsp/aspMain.cpp",
                "RecompiledPatches/patches.c", "RecompiledPatches/patches_bin.c", "private/goldenpad_conversion_patch.c")
    if not all((folder / name).is_file() for name in required) or not list((folder / "RecompiledFuncs").glob("*.c")):
        raise ValueError("Generated module inputs are incomplete")
    return record


def generate(source, rom, work, llvm, jobs, env):
    suffix = ".exe" if os.name == "nt" else ""
    compiler, linker = patch_tools(llvm, env)
    host_build = work / ("host-" + platform.system().lower() + "-" + platform.machine().lower())
    run("cmake", "--fresh", "-S", ROOT / "cmake/host-tools", "-B", host_build, "-G", "Ninja", "-DCMAKE_BUILD_TYPE=Release", env=env)
    run("cmake", "--build", host_build, "--target", "N64RecompCLI", "RSPRecomp", "GoldenPadGeneratorTest", "--parallel", jobs, env=env)
    run(host_build / ("GoldenPadGeneratorTest" + suffix), env=env)
    n64, rsp = host_build / ("N64Recomp" + suffix), host_build / ("RSPRecomp" + suffix)
    contract = identity()
    inputs = {"contract": contract, "rom": hashlib.sha256(rom).hexdigest(),
              "tools": {str(tool): sha256(tool) for tool in (n64, rsp, compiler, linker)}}
    generated = work / "generated"
    if generated.is_dir():
        try:
            if check_generated(generated).get("inputs") == inputs:
                return generated
        except (OSError, ValueError):
            pass
    with tempfile.TemporaryDirectory(prefix="generation-", dir=work) as temporary:
        stage = Path(temporary) / "source"
        export_files(source, stage, ["us.toml", "dump.toml", "data_dump.toml", "aspMain.us.toml", "patches.toml",
                                    "tools_weaken_patched.py", "patches", "lib/rt64/include", "include", "src/main/register_patches.cpp"])
        export_files(source / "lib/ge", stage / "lib/ge", ["include"])
        patch = (source / "vanilla_to_tlbfree.gep1").read_bytes()
        if hashlib.sha256(patch).hexdigest() != PATCH_SHA256:
            raise ValueError("The pinned ROM conversion data changed")
        converted = apply_gep1(rom, patch)
        if hashlib.sha256(converted).hexdigest() != CONVERTED_SHA256:
            raise ValueError("ROM conversion did not produce the pinned TLB-free image")
        # Registration only needs overlays.hpp. game.hpp unnecessarily pulls
        # host thread/Mach APIs into the private module's cross-platform build.
        registration = stage / "src/main/register_patches.cpp"
        registration.write_text(registration.read_text().replace('#include "librecomp/game.hpp"\n', ''))
        (stage / "ge007.tlbfree.z64").write_bytes(converted)
        (stage / "rsp").mkdir(exist_ok=True)
        run(n64, "us.toml", cwd=stage)
        run(sys.executable, stage / "tools_weaken_patched.py", cwd=stage)
        run(rsp, "aspMain.us.toml", cwd=stage)
        patches = stage / "patches"
        cflags = make_flags(patches / "Makefile", "CFLAGS") + make_flags(patches / "Makefile", "CPPFLAGS")
        sources = sorted(patches.glob("*.c"), key=lambda p: p.name)
        def compile_patch(path):
            run(compiler, *cflags, path.name, "-c", "-o", path.with_suffix(".o").name, cwd=patches)
        with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
            list(pool.map(compile_patch, sources))
        run(linker, *[path.with_suffix(".o").name for path in sources], *make_flags(patches / "Makefile", "LDFLAGS"),
            "-o", "patches.elf", cwd=patches)
        run(n64, "patches.toml", cwd=stage)
        embed_bytes((patches / "patches.bin").read_bytes(), "mm_patches_bin", stage / "RecompiledPatches")
        # The registration source expects these historical filenames.
        for extension in ("c", "h"):
            (stage / f"RecompiledPatches/mm_patches_bin.{extension}").rename(stage / f"RecompiledPatches/patches_bin.{extension}")
        embed_bytes(patch, "goldenpad_conversion_patch", stage / "private")
        record = {"contract": contract, "inputs": inputs, "outputs": output_hashes(stage)}
        (stage / "module-inputs.json").write_text(json.dumps(record, indent=2) + "\n")
        check_generated(stage)
        if generated.exists():
            preserved = generated.with_name("generated.recovered-" + uuid.uuid4().hex[:12])
            generated.rename(preserved)
            print(f"Preserved previous generated folder: {preserved}", flush=True)
        stage.rename(generated)
    return generated
