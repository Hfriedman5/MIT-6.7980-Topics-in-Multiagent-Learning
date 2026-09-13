#!/usr/bin/env python3
"""Regenerate every standalone Typst figure beside its source."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]

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


def build_figures(root: Path = ROOT) -> None:
    """Always rebuild figures, including when only an imported helper changed."""
    directory = root / 'content/figures'
    for source in sorted(directory.rglob('*.typ')):
        relative = source.relative_to(directory)
        if 'libs' in relative.parts or relative.as_posix() in SUPPORT_SOURCES:
            continue
        if relative.as_posix() == 'ppad_completeness/gate.typ':
            outputs = [(source.with_name(f'gate_{gate}.svg'),
                        ['--input', f'gate={gate}']) for gate in GATES]
        else:
            outputs = [(source.with_suffix('.svg'), [])]
        for output, inputs in outputs:
            subprocess.run([
                'typst', 'compile', '--root', str(root),
                '--font-path', str(root / 'html-exporter/assets/fonts'),
                *inputs, str(source), str(output),
            ], cwd=root, check=True)
            print(f'Figure: {output.relative_to(directory)}', flush=True)


if __name__ == '__main__':
    build_figures()
