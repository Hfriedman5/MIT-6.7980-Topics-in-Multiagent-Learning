#!/usr/bin/env python3
"""Regenerate standalone figures with PDF and HTML typography."""
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
HTML_FIGURES = Path('.build/html-figures')
EXPORTER = ROOT / 'html-exporter/target/release/notes-html-exporter'

# These are included by other figures rather than rendered on their own.
SUPPORT_SOURCES = {
    'kernelized/vertices.typ',
    'learning2/ftr_ent.typ',
    'learning2/ftr_euc.typ',
    'learning2/ftr_log.typ',
    'learning2/omd_euc.typ',
}
GATES = ('assignment', 'constant', 'addition', 'subtraction',
         'multiplication', 'comparison')

# Stable section labels identify the lecture references used by a drawing.
# Their displayed numbers are evaluated in the scheduled lecture, never authored.
SECTION_REFERENCES = {
    'calibration/route.typ': ('content/calibration.typ', (
        'sec-calibration-from-regret', 'sec-calibration-to-phi',
    )),
}


def section_reference_inputs(root: Path, figure: Path) -> list[str]:
    """Resolve linked figure labels through the same schedule as the notes."""
    reference = SECTION_REFERENCES.get(figure.as_posix())
    if reference is None:
        return []
    # Import here because build_site also imports the figure builder. This path
    # serves both the full site build and standalone `make figures`.
    from build_site import prepare_pdf_source
    from course_index import load_course

    source, labels = reference
    config, _ = load_course(root / 'html-export.json')
    chapter = next((note for note in config['notes'] if note['source'] == source), None)
    if chapter is None:
        raise ValueError(f'{figure}: referenced lecture {source} is not in the schedule.')
    prepared = prepare_pdf_source(root / source, chapter, root=root)
    expression = (
        '(' + ', '.join(json.dumps(label) for label in labels) + ',).map(key => { '
        'let elem = query(label(key)).first(); '
        '(label: key, number: numbering(elem.numbering, '
        '..counter(heading).at(elem.location()))) })'
    )
    result = subprocess.run([
        'typst', 'eval', '--in', str(prepared), '--root', str(root),
        '--font-path', str(root / 'html-exporter/assets/fonts'), expression,
    ], cwd=root, text=True, capture_output=True)
    if result.returncode:
        raise ValueError(f'Cannot resolve section references for {figure}:\n{result.stderr}')
    values = json.loads(result.stdout)
    return [arg for entry in values
            for arg in ('--input', f"{entry['label']}={entry['number']}")]


def build_figures(root: Path = ROOT, *, exporter: Path = EXPORTER) -> None:
    """Always rebuild figures, including when only an imported helper changed."""
    directory = root / 'content/figures'
    fonts = subprocess.check_output([
        'typst', 'fonts', '--font-path', str(root / 'html-exporter/assets/fonts'),
    ], cwd=root, text=True).splitlines()
    if 'Georgia' not in fonts:
        raise RuntimeError('Georgia is required to match the HTML figure text to the pages. '
                           'Install Georgia or provide it through TYPST_FONT_PATHS.')
    for source in sorted(directory.rglob('*.typ')):
        relative = source.relative_to(directory)
        if 'libs' in relative.parts or relative.as_posix() in SUPPORT_SOURCES:
            continue
        if relative.as_posix() == 'ppad_completeness/gate.typ':
            outputs = [(source.with_name(f'gate_{gate}.svg'),
                        ['--input', f'gate={gate}']) for gate in GATES]
        else:
            output = source.with_suffix('.svg')
            if relative.as_posix() in SECTION_REFERENCES and not output.is_file():
                # The lecture can eagerly load image(...) even when its PDF
                # uses the native drawing. Bootstrap that dependency before
                # evaluating references, then replace it with resolved labels.
                subprocess.run([
                    'typst', 'compile', '--root', str(root),
                    '--font-path', str(root / 'html-exporter/assets/fonts'),
                    '--input', 'figure-format=pdf', str(source), str(output),
                ], cwd=root, check=True)
            outputs = [(output, section_reference_inputs(root, relative))]
        for output, inputs in outputs:
            html_output = root / HTML_FIGURES / output.relative_to(directory)
            html_output.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run([
                'typst', 'compile', '--root', str(root),
                '--font-path', str(root / 'html-exporter/assets/fonts'),
                '--input', 'figure-format=pdf',
                *inputs, str(source), str(output),
            ], cwd=root, check=True)
            figure_inputs = ['--figure-input' if value == '--input' else value
                             for value in inputs]
            subprocess.run([
                str(exporter), '--figure-svg', '--root', str(root),
                *figure_inputs, str(source), str(html_output),
            ], cwd=root, check=True)
            print(f'Figure: {output.relative_to(directory)}', flush=True)


if __name__ == '__main__':
    subprocess.run(['cargo', 'build', '--release', '--locked',
                    '--manifest-path', 'html-exporter/Cargo.toml'], cwd=ROOT, check=True)
    build_figures()
