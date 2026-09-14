# Editable figure sources

Every SVG in this directory has an editable Typst source. Usually it has the
same basename beside the SVG. The six `ppad_completeness/gate_*.svg` files share
`ppad_completeness/gate.typ` and select their gate with a compiler input.

`make`, `make html`, and `make bundle` regenerate all figure SVGs before
compiling the notes. Run `make figures` to rebuild just the figures. The builder
also writes HTML variants under `.build/html-figures/`, using Georgia for body
labels and Frutiger for bold labels, matching the HTML pages. Georgia must be
installed or available through `TYPST_FONT_PATHS`. Mathematical notation keeps
its math font. HTML variants also contain a selectable text layer taken directly
from Typst's layout; the visible glyph outlines retain the exact typography.
The SVGs beside the sources retain the PDF typography.

From the repository root, regenerate an individual figure with Typst 0.15.1:

```sh
typst compile --root . --font-path html-exporter/assets/fonts \
  content/figures/nfgs_nash/nash_plots.typ \
  content/figures/nfgs_nash/nash_plots.svg
```

For a gate, add `--input gate=assignment` (or `constant`, `addition`,
`subtraction`, `multiplication`, `comparison`) and compile `gate.typ` to the
corresponding `gate_<name>.svg`.

For a selectable HTML variant, use the exporter after `make figures` builds it:

```sh
html-exporter/target/release/notes-html-exporter --figure-svg --root . \
  content/figures/nfgs_nash/nash_plots.typ \
  .build/html-figures/nfgs_nash/nash_plots.svg
```

For gate variants, add `--figure-input gate=assignment` (or another gate name).
Shared typography is defined in
`libs/typography.typ`; new figures should import `figure-font` and `figure-style`,
use `#set text(font: figure-font, ...)`, and apply `#show: figure-style`.

The root flag lets figures import shared libraries and component plots.
`learning2/plots.typ` includes the four `ftr_*.typ` / `omd_euc.typ` files beside
it; these are large, generated Matplotlib drawing sources. Compile the combined
`plots.typ` to reproduce the existing four-panel SVG. The shared libraries in
`libs/` reuse `content/meta/linalg.typ`, and the extensive-form strategy figures
reuse `kernelized/vertices.typ`.

`scripts/build_figures.py` discovers standalone `.typ` sources recursively,
including those whose SVG has not been generated yet. It excludes `libs/`
directories and the include-only files listed in `SUPPORT_SOURCES`. New shared
libraries should go in `libs/`; add other include-only files to that exclusion
list. Every build recompiles the figures so changes to shared libraries and
component plots are reflected in the output. Historical font metrics and
lecture-level scaling can differ slightly under the current compiler.

## Recovered sources

Recovered from the **Costis Gabri monograph** directory, using both its
`typst_content` lectures and the standalone exports in `texcontent/figures`.
The following paths are relative to that original directory. Inline drawings
were extracted into standalone files with their required imports and page setup.
Existing SVGs were retained during recovery.

Compatibility edits replace the old point-list `path` API with `curve` commands,
replace obsolete MiTeX labels and angle symbols with native Typst math, and
convert sampled gradient colors to RGB so that SVG embedding in PDFs retains
the colors. Unavailable New Computer Modern Sans labels use the bundled
Frutiger font. Figure pages have transparent backgrounds. Some inline figures
also need explicit widths or removal of lecture-level scale wrappers.

| Local source | Original source |
| --- | --- |
| `brouwer/example_games.typ` | `texcontent/figures/L17/example_games.typ` |
| `brouwer/sperner_example.typ` | `texcontent/figures/L17/sperner_example.typ` |
| `brouwer/sperner_padded.typ` | `texcontent/figures/L17/sperner_padded.typ` |
| `brouwer/sperner_paths.typ` | `texcontent/figures/L17/sperner_paths.typ` |
| `brouwer/sperner_triangulation.typ` | `texcontent/figures/L17/sperner_triangulation.typ` |
| `correlated/km_game.typ` | `texcontent/figures/L03/km_game.typ` |
| `correlated/kohlberg_mertens.typ` | `texcontent/figures/L03/kohlberg_mertens.typ` |
| `correlated/nash_irrational.typ` | `texcontent/figures/L03/nash_irrational.typ` |
| `learning1/entropy.typ` | `texcontent/figures/L05/entropy.typ` |
| `learning2/plots.typ` | `texcontent/figures/L06/plots.typ` |
| `learning2/table.typ` | `texcontent/figures/L06/table.typ` |
| `nfgs_nash/color_wheel.typ` | `texcontent/figures/L01/color_wheel.typ` |
| `nfgs_nash/nash_plots.typ` | `texcontent/figures/L01/nash_plots.typ` |
| `nfgs_nash/prisoner_dilemma.typ` | `texcontent/figures/L01/prisoner_dilemma.typ` |
| `nfgs_nash/theater_football.typ` | `texcontent/figures/L01/theater_football.typ` |
| `brouwer/color_wheel.typ` | `texcontent/figures/L03/color_wheel.typ` |
| `correlated/game_table.typ` | `texcontent/figures/L04/game_table.typ` |
| `libs/nash.typ` | `texcontent/figures/libs/nash.typ` |
| `libs/sperner.typ` | `typst_meta/sperner.typ` |
| `libs/efgs.typ` | `typst_meta/efgs.typ` |
| `learning2/ftr_ent.typ` | `texcontent/figures/L06/ftr_ent.typ` |
| `learning2/ftr_euc.typ` | `texcontent/figures/L06/ftr_euc.typ` |
| `learning2/ftr_log.typ` | `texcontent/figures/L06/ftr_log.typ` |
| `learning2/omd_euc.typ` | `texcontent/figures/L06/omd_euc.typ` |
| `efg_intro/kuhn.typ` | `typst_content/L09.typ (inline figure)` |
| `efg_intro/variations.typ` | `typst_content/L09.typ (inline figure)` |
| `efg_intro/small_efg.typ` | `typst_content/L09.typ (inline figure)` |
| `efg_intro/nf_strategies.typ` | `typst_content/L09.typ (inline figure)` |
| `perfection/guess-the-ace.typ` | `typst_content/L11.typ (inline figure)` |
| `perfection/guess-the-ace-x.typ` | `typst_content/L11.typ (inline figure)` |
| `perfection/venn.typ` | `typst_content/L11.typ (inline figure)` |
| `perfection/uniform.typ` | `typst_content/L11.typ (inline figure)` |
| `phi_regret/equation.typ` | `typst_content/L08.typ (inline figure)` |
| `phi_regret/blum_mansour.typ` | `typst_content/L08.typ (inline figure)` |
| `phi_regret/gordon.typ` | `typst_content/L08.typ (inline figure)` |
