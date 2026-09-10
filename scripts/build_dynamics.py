#!/usr/bin/env python3
"""Regenerate the SVG and PDF figures that use the shared dynamics package."""
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
FIGURES = (('L05', 'ogd_mwu'), ('L06', 'optimistic'))


def build_dynamics(root: Path = ROOT) -> None:
    """Keep the website assets and standalone figures in sync with dyns.typ."""
    for lecture, name in FIGURES:
        source = root / 'content' / 'figures' / lecture / (name + '.typ')
        svg = root / 'content' / 'assets' / f'{lecture}-{name}.svg'
        duplicate = root / 'content' / 'figures' / lecture / (name + '.svg')
        svg.parent.mkdir(parents=True, exist_ok=True)
        duplicate.parent.mkdir(parents=True, exist_ok=True)
        for output in (svg, source.with_suffix('.pdf')):
            subprocess.run([
                'typst', 'compile', '--root', str(root), str(source), str(output),
            ], cwd=root, check=True)
        shutil.copy2(svg, duplicate)
        print(f'Dynamics figure: {lecture}/{name}', flush=True)


if __name__ == '__main__':
    build_dynamics()
