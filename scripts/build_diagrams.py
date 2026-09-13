#!/usr/bin/env python3
"""Rebuild transparent diagram assets from their editable Typst sources."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def build_diagrams(root: Path = ROOT) -> None:
    for topic, name in (('learning_intro', 'self_play'), ('bandit', 'bandit')):
        source = root / 'content/figures' / topic / (name + '.typ')
        subprocess.run([
            'typst', 'compile', '--root', str(root), str(source),
            str(source.with_suffix('.svg')),
        ], cwd=root, check=True)
        print(f'Diagram: {topic}/{name}', flush=True)

    source = root / 'content/figures/perfection/uniform_game.typ'
    subprocess.run([
        'typst', 'compile', '--root', str(root), str(source),
        str(source.with_suffix('.svg')),
    ], cwd=root, check=True)
    print('Diagram: perfection/uniform_game', flush=True)

    for name in ('kernelized/tree', 'tfnp/complexity_classes'):
        source = root / 'content/figures' / (name + '.typ')
        subprocess.run([
            'typst', 'compile', '--root', str(root), str(source),
            str(source.with_suffix('.svg')),
        ], cwd=root, check=True)
        print(f'Diagram: {name}', flush=True)

    directory = root / 'content/figures/ppad_completeness'
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
