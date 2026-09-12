#!/usr/bin/env python3
"""Regenerate the SVG and PDF figures that use the shared dynamics package."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
FIGURES = (('learning1', 'ogd_mwu'), ('learning2', 'optimistic'))


def build_dynamics(root: Path = ROOT) -> None:
    """Regenerate the shared figure files beside their editable sources."""
    for topic, name in FIGURES:
        source = root / 'content' / 'figures' / topic / (name + '.typ')
        for output in (source.with_suffix('.svg'), source.with_suffix('.pdf')):
            subprocess.run([
                'typst', 'compile', '--root', str(root), str(source), str(output),
            ], cwd=root, check=True)
        print(f'Dynamics figure: {topic}/{name}', flush=True)


if __name__ == '__main__':
    build_dynamics()
