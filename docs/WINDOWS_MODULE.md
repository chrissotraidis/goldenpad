# Experimental Windows module build

This is next-release source work. No matching shell release has been published,
and the repository's release pause still applies. The current public release
does not provide this route. Local validation supplies a privately built,
matching empty shell with PadMint's `--app` option.

The next-release recipe builds a personal iPhone/iPad app on an Apple Silicon
Mac and experimentally on Windows ARM64 and x64. Windows requires Visual Studio
2022 Build Tools with Desktop development with C++ and a Windows SDK. Windows
x64 needs the x64/x86 C++ component; Windows ARM64 can use its native ARM64
component or x64 tools. PadMint supplies Python, Git,
CMake, Ninja, LLVM and the open-source iOS headers, plus a separate MIPS-capable
Clang for Windows. Older PadMint versions without `mips-clang` need updating.
The recipe uses `{python}` so it also works with PadMint's bundled Python.
Linux is not advertised as supported by this recipe.

The original static Mac build remains available:

```sh
scripts/build-personal-ipa.sh --rom YOUR_ROM --output PERSONAL.ipa
```

## Boundary and input checks

`scripts/build-module-shell.py` builds the opt-in empty shell on a Mac with
Xcode and Metal tools. The shell owns the runtime, renderer, platform services
and thread-local storage. It contains no generated game functions or GEP1
conversion resource. It keeps ROM import disabled when its module is missing
or incompatible, including import through an external file URL.

`scripts/build-game-module.py` accepts only the supported 12 MiB US retail ROM,
normalizes byte order in memory and checks its hash. Its original file is not
modified. The pinned GEP1 conversion is bounded and its output is checked
against the known TLB-free digest before generation. The private module owns
the generated game functions, audio RSP, overlay tables, translated patches,
patch bytes and conversion data. None of these private outputs may be published.

One exported getter returns a versioned table of pointers and scalar sizes.
The loader validates the table, required callbacks and a source identity before
using it. The identity covers the source pins, module and host build settings,
generation scripts, bridge sources and tracked patches. Both the shell and the
module must come from the same identity. Runtime callbacks are imported from
the shell; generated module symbols are hidden. Strong translated patches
replace the weak base functions regardless of object link order.

Generation checks the exact source revisions and rejects modified tracked
vendor sources. It records the input/tool digests and every generated file's
digest. A changed or incomplete set is rebuilt in a temporary folder. Existing
outputs are preserved under a unique recovery name before a complete replacement
is promoted; failure does not remove the previous output or its unique files.

Both static and module generation use the same maintained host-tool wrapper.
It sorts the pinned RSP generator's unordered emission loops and fixes its
reference-call naming to match the base generator's canonical names. This fixes
the observed `sprintf(rdram, ctx)` collision with the host C library: the game
callback is `sprintf_recomp`. A test invokes the actual emitter and verifies raw,
already-suffixed and unrelated callback names. The immutable vendor checkout is
unchanged. The module omits an unused `game.hpp` include from its staged patch
registration source so host Mach/thread headers are not required there.

## Validation and remaining gates

Completed locally on Apple Silicon with Apple Python 3.9:

- Sixteen portable synthetic input/freshness/recovery and compiler tests,
  including entry points under isolated Python.
- Seventeen cases using the actual native loader, including rejected identities,
  missing callbacks, retry after rejection, hidden symbols and both patch link
  orders.
- Real private-ROM conversion and generation with the pinned native generators.
- Empty iOS shell build; both PadMint's shell audit and the private release gate
  pass. No GEP1 resource or generated game function definitions are present.
  The runtime contains a small number of address-shaped symbol-name strings;
  those are not generated function definitions.
- Real iOS module built with PadMint's LLVM 22.1.8 and open-source headers. Its
  sole exported symbol is the module getter. Strict import checking resolves
  94 names from the shell and seven known runtime names.
- Matching embedded identities and personal IPA insertion pass. The static
  iOS build also passes using the same maintained generator. Its patch-code
  delta is exactly two corrected `sprintf_recomp` calls; private patch payload
  bytes are unchanged (the Python and native byte-array formatting differs).

The initial Windows packaged-player test exposed a missing MIPS backend in
PadMint's Windows LLVM 21.1.8 compiler. Its native ARM linker does handle MIPS2/o32 ELF.
The backend now checks the compiler's targets and actually compiles/links a
synthetic MIPS2/o32 probe before fetching dependencies. A separate managed
`PADMINT_MIPS_CC` can supply the patch compiler without changing the native iOS
compiler or linker. A private diagnostic using verified official Windows x64
Clang 18.1.8 and native ARM LLVM 21.1.8 passes the real module build, matching
identity, strict imports, sole-export check and IPA insertion under PadMint's
bundled x64 Python on Windows ARM64. All twelve portable tests pass there too.
The complete packaged PadMint player command also passes with a clean local
Windows source checkout, bundled Python and normal tool selection: no compiler
environment override. It uses the verified managed `mips-clang` installation
and existing LLVM/header caches, then checks imports and creates the personal
IPA. The installer itself passed a separate fresh, selective extraction from a
verified cached official archive. These are cached-tool build tests, not a
claim that an empty Windows machine or an iPhone was tested. Final IPA CRC,
matching embedded identities and absence of a raw GEP1 resource were rechecked.

A complete private backend build from `deb91ee` also passes with x64 MSVC
generators, the managed x64 MIPS compiler and x64 LLVM 21.1.8 under Windows ARM64
emulation. It completed in 145 seconds with one build job, existing tools/source
and native ARM helper tools. Compiler caches and PE headers verify the actual
x64 tools; all 69 generated sources match the native ARM Windows result after
newline normalization. Independent IPA readback confirms an arm64 iOS module,
matching identities and unchanged shell files, with only the module added.
Strict imports again resolve 94 app names and seven runtime names. This supports
the draft experimental x64 host flag; a fresh full private player build on native
x64 hardware remains untested.

After CRLF/LF normalization, 66 of 69 generated source files match the Mac build.
The three differences are translated patch code, its byte array and overlay
metadata, produced with Clang 18 on Windows versus Clang 22 on Mac. All nine
handwritten patch inputs, 31 translated function names/order and 153 callback
names agree. Overlay metadata has the same structure apart from numeric layout
and size constants, and both private patch blobs are 14,884 bytes. Instruction
selection and relocations differ. These checks found no missing patch, renamed
callback or table-layout discrepancy; they do not establish semantic or gameplay
equivalence between compiler versions.

[Hosted CI](https://github.com/chrissotraidis/goldenpad/actions/runs/40215751104)
passes native Windows x64/ARM64 and Mac generator builds, portable tests and
Mac loader checks without a ROM; that is not a game build or a device test.
Cross-host source comparisons normalize CRLF/LF; they do not claim identical
native binaries across different LLVM versions.

The Windows path checks also cover Japanese characters in work and temporary
folders. The host generators carry a process-local UTF-8 manifest, Visual Studio
setup preserves Unicode environment values, and the module CLI and its Python
helper handle redirected output without relying on environment encoding flags.
Public fixtures exercise real generator CLI arguments, TOML input/output paths,
and the existing callback-name tests; these fixtures check generation rather
than game execution. The full existing Mac entry-point suite also passed.

A complete private Windows ARM backend build from `12fdeb5` passes in fresh
Japanese work/TEMP folders using bundled x64 Python with UTF-8 mode explicitly
disabled. It took 164 seconds with one job and reused verified public source/tool
caches. Its newly built matching empty shell passes both content audits; strict
imports, sole module export, iOS compatibility and all eight original IPA entries
pass, with only the private module added. The original ROM is unchanged, and all 69 generated files are byte-identical
to the earlier Windows result. The same 66 of 69 generated files match the Mac reference, with the three previously
explained patch-compiler differences. The Mac private pair was refreshed and
checked before the final CLI-only change; the final matching empty shell and
private module were then checked together in this Windows run. These are backend
and packaging proofs; the earlier normal packaged-player command remains tied
to its recorded revision.

Physical iPhone/iPad launch, ROM import, audio, rendering, controls, save behavior
and gameplay still require validation. No device or gameplay acceptance is
claimed. Before any future release, the repository release pause, artifact
audits and the required current-main PadMint player checks must all be satisfied.
