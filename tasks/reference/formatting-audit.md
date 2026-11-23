# Formatting audit: what the sources look like today, and one style to enforce

**Reference doc**, 2026-11-23 (audit, stage 1 of `tasks/cmake-crossplatform-build.md`). Measured with clang-format
23.1.5 in the audit's container (`tasks/adhoc/cmake-crossplatform-build/formatting_audit.sh`, data in
`data/formatting.tsv`; style comparison run separately over the 122 demo `.c`/`.cpp` files).

## State

- **No `.clang-format` is committed** (none anywhere in the repository), yet the history has four whole-tree formatting
  passes (`73f58ea`, `02e83be` in 2021 and 2022; `6f8a3ed`, `0b6affa` in 2024; `eb7a0b3` prepared the first). The style
  was therefore chosen on the command line or by a file outside the repository; **the result is Google style** (2-space
  indent, 80 columns, attached braces, `void ChangeSize(int w, int h) {` on one line).
- **Line endings:** LF everywhere in first-party code (`638345d` ran dos2unix). 0 of 352 files measured have carriage
  returns.
- **Closest built-in style, by changed lines over the 122 demo files** (`clang-format --style=X | diff`): **Google 1,268
  lines** (15 files already identical), Chromium 2,492 (16), LLVM 8,843 (18), Mozilla 158,524, WebKit 196,750,
  Microsoft 126,409, GNU 186,470; Google or LLVM with a 4-space indent is about 47,000. The 1,268 lines are the drift of
  newer clang-format versions and of hand edits since the last pass (the ImGui additions among them).
- **By group** (files, files with tabs, files identical to `--style=Google`):

| group | files | with tabs | Google-clean |
|---|--:|--:|--:|
| demos, chapters 1 to 18 and 21 | 96 | 6 (`bounce`, `glrect`, `spot`, `nurbs`, `nurbt`, `select`) | 7 |
| platform chapters 19, 20, 22 | 37 | 3 | 16 |
| `shared/` first-party (`gltools`, `math3d`, `VBOMesh`, `TriangleMesh`, `glframe`, `stopwatch`, ...) | 12 | 2 | 3 |
| `shared/GLee.c`, `GLee.h` | 2 | 0 | 0 (reformatted to 2-space by the 2021 passes) |
| `shared/openexr-*` (vendored OpenEXR 1.4 headers, two copies) | 189 | 177 | 4 |
| `contrib/imgui` (vendored Dear ImGui 1.76) | 16 | 1 | 0 |

## Recommendation (formatting may change; consistency is the goal)

1. Commit a `.clang-format` with `BasedOnStyle: Google` at the repository root (the style the code already has; no other
   style is within an order of magnitude of the current files).
2. **Exclude vendored code** from the formatter: `shared/GLee.*`, `shared/openexr-*`, `contrib/`. The entrypoint
   script `entrypoint/format.sh` (added with the container) already skips GLee and OpenEXR and only walks `examples/src`.
3. Run `make format` once, as its own commit (about 1,300 changed lines in the demos plus `shared/` and the tab-indented
   files), so later diffs are only content. The behavior-neutral claim is checkable: formatting changes no token, so
   a build before and after must give identical object code (compare `gcc -S` output per file, as
   `semantic_delta.sh` does for the history).
4. Add a check target (`make check-format`: format, then `git diff --exit-code`) the same way the maintainer's other
   projects do, once the CMake build exists. Not done in the audit: the audit changes no source.
5. Pin the clang-format version in the container image (Fedora 45 ships 23.1.5); a newer clang-format will re-flow a few
   lines and the pin keeps the check stable.

The 2021 to 2024 passes also reflowed comments (`ReflowComments`), so the book's long line comments were re-wrapped; a
comment-faithful alternative is `ReflowComments: false` in the same file, at the cost of lines over 80 columns. That is a
style choice for the maintainer; the audit does not make it.
