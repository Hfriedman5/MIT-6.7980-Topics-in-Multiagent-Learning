#!/usr/bin/env python3
"""Build current Typst chapters, then assemble a native Typst asset bundle."""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import zipfile

from build_dynamics import build_dynamics
from build_diagrams import build_diagrams
from course_index import load_course, render_index
from public_files import copy_public_files, note_outputs, required_files, validate_public_path

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / '.build' / 'site'
CONFIG = ROOT / 'html-export.json'
RESOLVED_CONFIG = ROOT / '.build' / 'html-export.json'


def run(*args: str) -> None:
    subprocess.run(args, cwd=ROOT, check=True)


def chapter_source_text(source: Path, chapter: dict | None = None) -> str:
    """Derive note headers from the schedule without editing authored sources."""
    content = source.read_text()
    if chapter is not None and 'date' in chapter:
        content, numbers = re.subn(r'lec_num:\s*(?:"[^"]+"|\d+)',
            lambda _: 'lec_num: ' + json.dumps(chapter['number']), content, count=1)
        content, dates = re.subn(r'date:\s*\[[^\]]*\]',
            lambda _: 'date: [' + chapter['date'] + ']', content, count=1)
        if numbers != 1 or dates != 1:
            raise ValueError(f'{source.name}: expected one lecture number and date in the note header.')
    return content


def prepare_pdf_source(source: Path, chapter: dict | None = None) -> Path:
    """Keep PDF-only template selection and relocated paths out of chapter prose."""
    def absolute_path(match: re.Match) -> str:
        target = (source.parent / match[1]).resolve().relative_to(ROOT)
        return '"/' + target.as_posix() + '"'

    content = re.sub(r'"((?:\.\./)+[^"]+)"', absolute_path, chapter_source_text(source, chapter))
    content = content.replace('/content/meta/gabri_notes_bk.typ',
                              '/content/meta/gabri_notes_pdf.typ')
    target = ROOT / '.build' / 'pdf-source' / source.name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content)
    return target


def prepare_html_source(source: Path, chapter: dict) -> Path:
    content = chapter_source_text(source, chapter)
    if content == source.read_text():
        return source
    def absolute_path(match: re.Match) -> str:
        target = (source.parent / match[1]).resolve().relative_to(ROOT)
        return '"/' + target.as_posix() + '"'
    content = re.sub(r'"((?:\.\./)+[^"]+)"', absolute_path, content)
    content = content.replace('/content/meta/gabri_notes_bk.typ',
                              '/content/meta/gabri_notes_html.typ')
    target = ROOT / '.build' / 'html-source' / source.name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content)
    return target


def build_chapter(chapter: dict) -> str:
    source = ROOT / chapter['source']
    outputs = note_outputs(chapter)
    output = STAGE / outputs['html']
    pdf = STAGE / outputs['pdf']
    pdf_log = ROOT / '.build' / 'logs' / (source.stem + '.pdf.log')
    with pdf_log.open('w') as stream:
        result = subprocess.run([
            'typst', 'compile', '--root', str(ROOT),
            '--font-path', str(ROOT / 'html-exporter/assets/fonts'),
            str(prepare_pdf_source(source, chapter)), str(pdf),
        ], cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError(f"Lecture {chapter['number']} PDF failed:\n{pdf_log.read_text()}")
    log = ROOT / '.build' / 'logs' / (source.stem + '.log')
    with log.open('w') as stream:
        result = subprocess.run([
            str(ROOT / 'html-exporter/target/release/notes-html-exporter'),
            '--root', str(ROOT), '--config', str(RESOLVED_CONFIG), '--math', 'katex',
            '--pdf', outputs['pdf'],
            str(prepare_html_source(source, chapter)), str(output),
        ], cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError(f"Lecture {chapter['number']} failed:\n{log.read_text()}")
    html = output.read_text()
    # Keep one shared stylesheet; KaTeX sources stay in the lecture HTML.
    html, count = re.subn(r'<style>\s*.*?</style>',
                         '<link rel="stylesheet" href="assets/notes.css">',
                         html, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f'Expected the converter stylesheet in {output}')
    html = html.replace('../' + chapter['source'], outputs['source'])
    html = html.replace('https://cdn.jsdelivr.net/npm/katex@0.16.22/dist/', 'assets/katex/')
    output.write_text(html)
    (STAGE / outputs['source']).write_text(chapter_source_text(source, chapter))
    return f"Lecture {chapter['number']}: {source.stem}.html"


def make_index(config: dict, schedule: list[dict]) -> None:
    syllabus = ROOT / config['site']['syllabus_source']
    stylesheet_version = sha256((STAGE / 'assets/course.css').read_bytes()).hexdigest()[:12]
    (STAGE / 'index.html').write_text(render_index(
        config, schedule, stylesheet_version=stylesheet_version))
    copy_public_files(config, ROOT, STAGE)
    # Recompile the linked syllabus, so the PDF and schedule share one source.
    run('typst', 'compile', '--root', str(ROOT),
        '--font-path', str(ROOT / 'html-exporter/assets/fonts'),
        str(syllabus), str(STAGE / 'syllabus.pdf'))
    shutil.copy2(STAGE / 'syllabus.pdf', ROOT / 'syllabus/6.7980 Fall 2026 Syllabus.pdf')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--zip', action='store_true', help='also create dist/6.7980-notes.zip')
    parser.add_argument('--skip-build', action='store_true', help='reuse the existing Rust binary')
    args = parser.parse_args()
    config, schedule = load_course(CONFIG)
    RESOLVED_CONFIG.parent.mkdir(exist_ok=True)
    RESOLVED_CONFIG.write_text(json.dumps(config, indent=2) + "\n")
    version = subprocess.check_output(['typst', '--version'], text=True)
    match = re.search(r'typst (\d+)\.(\d+)\.(\d+)', version)
    if not match or tuple(map(int, match.groups())) < (0, 15, 1):
        raise RuntimeError('Typst 0.15.1 or later is required for the native bundle target.')
    if not args.skip_build:
        run('cargo', 'build', '--release', '--locked', '--manifest-path', 'html-exporter/Cargo.toml')
    if STAGE.exists():
        shutil.rmtree(STAGE)
    (STAGE / 'assets').mkdir(parents=True)
    shutil.copytree(ROOT / 'html-exporter/assets', STAGE / 'assets', dirs_exist_ok=True)
    (STAGE / 'source').mkdir()
    (STAGE / 'pdf').mkdir()
    (ROOT / '.build' / 'logs').mkdir(exist_ok=True)
    shutil.copy2(ROOT / 'html-exporter/src/gabri-notes.css', STAGE / 'assets/notes.css')
    shutil.copy2(ROOT / 'html-exporter/src/course.css', STAGE / 'assets/course.css')
    build_dynamics(ROOT)
    build_diagrams(ROOT)
    with ThreadPoolExecutor(max_workers=3) as pool:
        for message in pool.map(build_chapter, config['notes']):
            print(message, flush=True)
    make_index(config, schedule)
    entries = [{'output': str(p.relative_to(STAGE)), 'source': str(p.relative_to(ROOT))}
               for p in sorted(STAGE.rglob('*')) if p.is_file()]
    required = required_files(config)
    for entry in entries:
        validate_public_path(entry['output'], required)
    if missing := required - {entry['output'] for entry in entries}:
        raise ValueError('Incomplete site: ' + ', '.join(sorted(missing)))
    (ROOT / '.build/bundle-files.json').write_text(json.dumps(entries, indent=2) + '\n')
    run('typst', 'compile', '--root', '.', '--features', 'bundle', '--format', 'bundle',
        'content/bundle.typ', 'html')
    run(sys.executable, 'scripts/check_site.py', 'html')
    run('node', 'scripts/check_katex.cjs', 'html')
    if args.zip:
        target = ROOT / 'dist/6.7980-notes.zip'
        target.parent.mkdir(exist_ok=True)
        with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
            for entry in entries:
                archive.write(ROOT / 'html' / entry['output'], entry['output'])
        print(f'ZIP: {target.relative_to(ROOT)}')
    print('Site: html/index.html')


if __name__ == '__main__':
    main()
