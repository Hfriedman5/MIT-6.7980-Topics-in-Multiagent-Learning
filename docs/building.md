# Building and editing the notes

Run commands from the repository root. The Makefile uses `python3` by default;
set `PYTHON=/path/to/python3` if needed. The converter's Cargo lockfile pins
Typst 0.15.1; use the matching Typst CLI for consistent output.

## Build pipeline

`make html` builds the Rust converter, regenerates the editable dynamics and
diagram figures, compiles each lecture to HTML and PDF, generates the course
index from the syllabus, and assembles `html/` using Typst's experimental bundle
target. `make bundle` also produces `dist/6.7980-notes.zip`.

The generated website has a schedule, 15 lecture and supplementary pages,
PDF downloads, downloadable chapter sources, a syllabus, and local browser
assets. KaTeX 0.16.22 renders supported expressions; unsupported expressions
retain their Typst SVG rendering. No npm installation is needed for the course
build: the browser runtime and its license are under `html-exporter/assets/katex/`.

After the Rust converter has been built, a quicker rebuild is:

```sh
python3 scripts/build_site.py --skip-build --zip
```

Compiler diagnostics are saved under `.build/logs/`. Build products in `.build/`,
`html/`, `dist/`, and `html-exporter/target/` are not versioned.

## Source files

- Edit `Typst Lectures/content/*.typ` for explanations, equations, and proofs.
- Edit `html-export.json` for reading order, syllabus mappings, and site metadata.
- Edit `Syllabus/6.7980 F26 Syllabus.typ` for schedule topics, dates, and instructors.
- Edit `scripts/course_index.py` for course-home content and markup.
- Edit `html-exporter/src/course.css` for the homepage layout.
- Edit `html-exporter/src/gabri-notes.css` for the lecture layout.
- Edit `Typst Lectures/meta/gabri_notes_html.typ` for semantic HTML components.
- Edit `Typst Lectures/meta/gabri_notes_pdf.typ` for the native PDF layout.
- Edit `Typst Lectures/meta/lovelace_html.typ` for HTML pseudocode.

The schedule reader recognizes `module[...]` and `row(...)` in the syllabus.
It fails if a row cannot be parsed or lecture numbers are not consecutive.
Use `standalone: true` on a row to start a section without a part heading.
`html-export.json` maps chapters to sessions using `syllabus_numbers`;
supplementary readings use S1, S2, and so on.

## Figures

All active figure dependencies live inside `Typst Lectures/`.

```sh
python3 scripts/build_dynamics.py       # OGD/MWU and optimism figures
python3 scripts/build_diagrams.py       # self-play, bandits, and PPAD diagrams
```

These commands run during the full site build. Editable dynamics and diagram
sources live under `Typst Lectures/figures/`; the dynamics helpers are in
`Typst Lectures/meta/dyns.typ`. Generated SVGs are used by both rendering paths.

The optional `prepare_kuhn_figure.py` and `prepare_kuhn_alternatives.py` scripts
require Pillow. They preserve white node interiors and verify that compositing
the transparent figures over white reproduces the original pixels exactly.
`course_collage.py` rebuilds the homepage illustration collage from the screenshots
under `Syllabus/assets/`.

Use `wrapped-figure` for prose alongside a compact diagram:

```typst
#wrapped-figure(side: right, text-width: 55%)[
  Explain the learning process here.
][
  #image("../figures/L04/self_play.svg", width: 300pt)
]
```

The two columns stack on narrow screens. `wrapped-figure-with-caption` accepts
a third content argument for a caption.

## Typography and verification

The build loads the bundled regular and bold Frutiger faces from
`html-exporter/assets/fonts`. The syllabus uses Frutiger for bold text and
headings, with New Computer Modern for regular and italic body text.
The font files and other third-party assets retain their respective terms.

`make check` runs the Python and Rust regression suites, verifies local links
and image occurrences, and checks every KaTeX expression. Review rendered PDFs
and representative desktop/mobile pages after visual changes: automated checks
do not establish that every equation fits or every figure label is readable.
