# Building and editing the notes

Run commands from the repository root. The Makefile uses `python3` by default;
set `PYTHON=/path/to/python3` if needed. The converter's Cargo lockfile pins
Typst 0.15.1; use the matching Typst CLI for consistent output.

## Editing individual lectures

Open the repository folder in VS Code and install the recommended Tinymist
extension. Each lecture and supplementary reading is a standalone
`content/<topic>.typ` document that imports `meta/gabri_notes.typ`, the default
PDF style. Its styles, figures, and bibliography all live below `content/`,
inside Typst's default project root. No root override, input variables, target
flags, or generated source file is needed:

```sh
typst compile content/nfgs_nash.typ
```

The checked-in `.vscode/settings.json` selects the paged target and loads the
bundled Frutiger fonts via
[Tinymist's fontPaths setting](https://myriad-dreamin.github.io/tinymist/config/vscode.html#tinymistfontpaths).
For standalone CLI compilation on another machine, install those fonts for the
same typography; Typst can still compile using fallback fonts.

`make check-pdf` compiles every authored note without compiler flags or
`TYPST_*` environment overrides, writing PDFs and diagnostics under
`.build/standalone-pdfs/`. This check also runs as part of `make check`.
PDFs created alongside the lecture sources by the editor or CLI are ignored by
Git; the site build writes its published PDFs under `html/pdf/`.

The old nested source layout, numbered figure paths, and `gabri_notes_bk.typ`
and `gabri_notes_pdf.typ` imports are rejected by the build. The former `web`,
`html`, and `combined` compiler inputs are rejected by both styles. Combined
document cross-reference injection and the exporter's old source-rewriting
shims have been removed; each note is compiled independently.

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

All lecture and supplementary PDFs share `content/meta/gabri_notes.typ`.
The print style uses A4 pages, 1.3-inch side margins, 1.6-inch top/bottom margins,
10.2pt New Computer Modern body text, and Frutiger Bold headings. A ruled opening
panel carries the course, date, lecture title, and instructor. Each footer keeps
the full authored title beside the lecture identifier and a right-aligned
current/total page count. Long titles wrap without hyphenation; section markers
vary by heading level. Headings have more space above than below: 9/5mm for
sections, 7.5/4.5mm for subsections, and 6/4.5mm for deeper levels. Unnumbered
headings follow the same hierarchy. Block spacing collapses adjacent gaps,
and headings stay with the following text. Build with the
bundled font directory as shown in the build scripts. The HTML exporter selects
`gabri_notes_html.typ` and its CSS explicitly; the authored notes always use the
working PDF style.

## Source files

- Edit `content/*.typ` for explanations, equations, and proofs.
- Edit `html-export.json` for note documents, supplementary reading order, stable syllabus mappings, slides, and export settings.
- Edit `syllabus/6.7980 F26 Syllabus.typ` for course facts, formatted prose, and the ordered lecture/module outline.
- Edit `syllabus/fall-2026-calendar.typ` for verified class dates and fixed academic-calendar exceptions.
- Edit `scripts/course_index.py` for course-home markup, not a duplicate of syllabus content.
- Edit `html-exporter/src/course.css` for the homepage layout.
- Edit `html-exporter/src/gabri-notes.css` for the lecture layout.
- Edit `content/meta/gabri_notes_html.typ` for semantic HTML components.
- Edit `content/meta/gabri_notes.typ` for the native PDF layout.
- Edit `content/meta/lovelace_html.typ` for HTML pseudocode.

`how_to_cite.url_prefix` in `html-export.json` sets the published base URL for
lecture citation links, currently `https://www.mit.edu/~6.7980/`. Keep the trailing
slash. Navigation and asset links remain relative so local previews and the
downloadable bundle work without a web server at that address.

The syllabus calls `schedule(class-dates, outline)`. Its outline contains
`lecture("stable-id", [Title], description: [...], instructor: [...])`,
`module[Part title]`, and `no-class(title: [...], description: [...])` entries.
Lecture numbers and dates are generated from the linked syllabus rows. Authored note titles must match the corresponding syllabus title (or `short_title` for supplementary notes). Edit both the syllabus and the Typst header when renaming a lecture: the build rejects mismatches and never substitutes a different title into the note. Author `short_title` only for supplementary notes. Tests cover title agreement and rejection of divergence; the site checker also validates rendered HTML titles.

Lectures consume the next class date and receive a zero-based lecture number.
An undated `no-class` consumes a class date without advancing that number;
module headings consume neither. Use `standalone: true` on a lecture to start
a section without a part heading.

Set `hide-instructors: true` on `schedule(...)` to hide all lecturer names in
the PDF schedule while keeping their assignments in the source. This syllabus
enables the flag; its default is `false`. The website schedule also hides names.

MIT's fixed exceptions use `no-class(on: "YYYY-MM-DD", description: [...])` and
are inserted chronologically without consuming a class date. They are defined
beside the date list, then included in the outline via `..calendar-exceptions`.
Their placement in that outline has no effect on their dates. Typst rejects
duplicate or unordered dates, duplicate lecture IDs, conflicting exceptions,
and a mismatch between class dates and entries. Adding or deleting a lecture
therefore requires adjusting another slot, for example replacing a project break.

The Fall 2026 calendar was verified on September 9, 2026 against the
[MIT Registrar's calendar](https://registrar.mit.edu/calendar-pdf) and
[class-day totals](https://registrar.mit.edu/calendar/class-days).
Classes run September 9–December 10. The course has 12 Tuesday and 13 Thursday
slots, starting September 10. October 13 follows a Monday schedule and November
26 is Thanksgiving; November 11 is a Wednesday holiday.

The website reads `<course-schedule>` metadata evaluated by Typst, so it uses
the same assigned dates as the PDF and supports nested Typst text without a
second schedule parser. `html-export.json` maps notes to stable `syllabus_ids`.
The build derives their current titles, numbers, dates, and ordering, and writes a
resolved exporter configuration to `.build/html-export.json`. The authored
`notes` list contains no `number`, `syllabus_numbers`, or `date` fields; these
fields are generated and should not be edited in `.build/` either.
Generated HTML/PDF note sources receive the derived header metadata without
rewriting the authored lecture files. Supplementary readings receive S1, S2,
and so on in their listed order, with the term in place of a class date.

For example, a scheduled note and an independent slide attachment are configured as:

```json
{
  "notes": [
    {
      "source": "content/nfgs_nash.typ",
      "syllabus_ids": ["nash"]
    }
  ],
  "slides": {"overview": "slides/L00_course_intro.pdf"}
}
```

A note can reference several lecture IDs; its header uses the first scheduled
session and the index links it from every referenced session. Slides do not need
a corresponding note document. They follow the stable lecture ID when the
outline is reordered. Files are copied to `slides/<filename>.pdf`, so two
different source files cannot use the same output filename (including case-only
differences). Multiple lectures may intentionally share the same source PDF.
Unknown IDs, missing files, corrupt PDFs, and output collisions fail before the
build clears staging. Poppler's `pdfinfo` checks PDF validity.

Course facts live in the syllabus's `course` dictionary. Its `item(...)` and
`course-text("key")[...]` blocks expose formatted prose via Typst metadata.
`scripts/course_data.py` reads this alongside the schedule and preserves
paragraphs, emphasis, bold text, code, and links for the index. New unsupported
prose constructs fail explicitly instead of disappearing. The lecture-note
exporter remains responsible for mathematical content. PDF-only course figures
remain outside these shared prose blocks and stay hidden on the homepage.
Course title, authors, term, and citation metadata are also derived from the
syllabus. The JSON retains deployment URLs and exporter-specific settings.

`scripts/public_files.py` defines note output paths, copied course illustrations,
slide output paths, required files, and permitted public asset types. Index links,
the site build, and the local deployment tool use that same contract. Deployment
still checks staged bytes, rejects private paths and symlinks, and excludes stray
files from the payload. A configured slide PDF needs no additional deployment
allowlist entry.
The source repository explicitly includes the configured lecture 0 PDF in
`.gitignore`; editable slide decks remain excluded. When adding another public
slide PDF, also make sure its source is included in version control so clean
checkouts can build it.

Use `make syllabus` after outline changes to rebuild both syllabus PDF copies
and regenerate the current index. Use `make html` to also regenerate lecture
notes and their navigation with the new session numbers and dates.
For exporter development, `python3 scripts/course_index.py --resolve-only`
refreshes the generated configuration without rewriting the website or PDFs.

## Figures

All active figure dependencies live in `content/figures/<topic>/`, normally
matching the lecture's Typst filename. Shared figures retain their owning topic:
for example, `kernelized.typ` reuses `figures/efg_intro/nf_strategies.svg`.
Folder names never depend on lecture numbers. There is one rendered asset per
figure, next to its editable source when available; no separate assets copy is
needed.

```sh
python3 scripts/build_dynamics.py       # OGD/MWU and optimism figures
python3 scripts/build_diagrams.py       # self-play, bandits, and PPAD diagrams
```

These commands run during the full site build. Editable dynamics and diagram
sources live under `content/figures/`; the dynamics helpers are in
`content/meta/dyns.typ`. Generated SVGs are used by both rendering paths.

The optional `prepare_kuhn_figure.py` and `prepare_kuhn_alternatives.py` scripts
require Pillow. They preserve white node interiors and verify that compositing
the transparent figures over white reproduces the original pixels exactly.
`course_collage.py` rebuilds the homepage illustration collage from the screenshots
under `syllabus/assets/`.

Use `wrapped-figure` for prose alongside a compact diagram:

```typst
#wrapped-figure(side: right, text-width: 55%)[
  Explain the learning process here.
][
  #image("figures/learning_intro/self_play.svg", width: 300pt)
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
and image occurrences, validates each “How to cite” URL against the generated
lecture page, and checks every KaTeX expression. Absolute URLs under
`how_to_cite.url_prefix` are checked against the build as well as relative links,
including CSS assets and HTML/SVG anchors. For a live check of external links,
run `python3 scripts/check_links.py html --online`; blocked or unreachable
destinations are reported as unverified, separately from HTTP 404/410 failures.
Add `--doi-warnings` to report failed checks of `doi.org` and `dx.doi.org`
links as non-blocking warnings. Those URLs are still checked, including their
redirects; other external failures and all local/citation errors remain blocking.
`site.separate_paths` lists directories deployed independently of the course
bundle (currently `fow/`); links into those directories are checked online unless
explicitly excluded with `--skip-separate-site fow/`.
Review rendered PDFs
and representative desktop/mobile pages after visual changes: automated checks
do not establish that every equation fits or every figure label is readable.
