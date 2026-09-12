# Notes HTML Exporter

This Rust binary exports the notes by compiling Typst with its experimental HTML backend and then applying a light postprocessing pass for the public lecture layout.

The Typst side lives primarily in `meta/gabri_notes_html.typ`, which emits HTML-friendly classes and attributes for the exporter. The Rust side calls Typst as a library, reads the resulting HTML, and handles the page shell, lecture rail, citation and footnote sidenotes, equation sizing hooks, bibliography cleanup, and KaTeX conversion.

## Usage

The canonical entry point is the course Makefile:

```sh
make bundle
```

That generates `html/` with a shared stylesheet using the native Typst bundle
target and packages `dist/6.7980-notes.zip`. It validates local links and math.
See the [course README](../README.md) and [build guide](../docs/building.md).

For a single lecture:

```sh
python3 scripts/course_index.py --resolve-only
cargo run --manifest-path html-exporter/Cargo.toml -- \
  --root . \
  --config .build/html-export.json --math katex \
  'content/nfgs_nash.typ' \
  .build/nfgs_nash.html
```

The Rust exporter reads the resolved `notes` configuration in `.build/`, whose
numbers, dates, course facts, and citation metadata come from the syllabus.
Use `make html` for publishing: it also updates the Typst note headers, compiles
PDFs, copies slide attachments, and synchronizes the index and syllabus PDF.

Useful options:

- `--root <dir>`: set the Typst project root.
- `--math <svg|katex>`: choose the math backend. The course build uses `katex`, with SVG fallback for unsupported expressions. Unsupported KaTeX conversions retain Typst's SVG.
- `--site-title <title>`: change the header title.
- `--authors <text>`: change the author line.
- `--index <href>` and `--pdf <href>`: add header links.

## Checks

```sh
make check
```

This runs the Python/Rust regression tests and validates the already-generated site.
The converter embeds Typst 0.15.1 and supports its current font, file, package,
and diagnostic APIs. `SOURCE_DATE_EPOCH` can fix the compiler's clock for
reproducible builds.

## Bundled browser assets

`assets/katex/` contains the pinned KaTeX 0.16.22 browser runtime, styles, fonts,
and MIT license. The course builder rewrites the standalone converter's CDN
links to these local assets. See the [KaTeX browser documentation](https://katex.org/docs/browser).

`assets/fonts/` contains genuine Frutiger Regular (400) and Bold (700) faces
from the existing notes. Environment names and numbers, including generated
algorithm counters, proof labels, and figure/table caption labels, request 600
through `--environment-label-weight`. Browsers currently match this to the
available Bold face; add a genuine Semibold face with a 600 `@font-face` rule
to obtain that distinct weight. Synthetic weight remains disabled.
