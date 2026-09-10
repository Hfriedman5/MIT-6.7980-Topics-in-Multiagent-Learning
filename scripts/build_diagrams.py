#!/usr/bin/env python3
"""Rebuild transparent diagram assets from their editable Typst sources."""
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def build_diagrams(root: Path = ROOT) -> None:
    for lecture, name in (('L04', 'self_play'), ('L07', 'bandit')):
        source = root / 'content/figures' / lecture / (name + '.typ')
        svg = root / 'content/assets' / f'{lecture}-{name}.svg'
        for output in (svg, source.with_suffix('.pdf')):
            subprocess.run([
                'typst', 'compile', '--root', str(root), str(source), str(output),
            ], cwd=root, check=True)
        shutil.copy2(svg, root / 'content/figures' / lecture / (name + '.svg'))
        print(f'Diagram: {lecture}/{name}', flush=True)

    directory = root / 'content/figures/ppad'
    for gate in ('assignment', 'constant', 'addition', 'subtraction',
                 'multiplication', 'comparison'):
        subprocess.run([
            'typst', 'compile', '--root', str(root), '--input', f'gate={gate}',
            str(directory / 'gate.typ'), str(directory / f'gate_{gate}.svg'),
        ], cwd=root, check=True)
    for name in ('circuit', 'addition_gadget'):
        subprocess.run([
            'typst', 'compile', '--root', str(root),
            str(directory / (name + '.typ')), str(directory / (name + '.svg')),
        ], cwd=root, check=True)
    print('Diagrams: PPAD gates, circuit, and addition gadget', flush=True)


if __name__ == '__main__':
    build_diagrams()
