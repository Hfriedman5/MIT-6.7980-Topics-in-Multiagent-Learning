"""The public file contract shared by rendering, building, and deployment."""
from pathlib import Path, PurePosixPath
import shutil
import subprocess

COURSE_FIGURES = {
    'traffic-cone.svg': 'website/traffic-cone.svg',
    'course-image-transparent.svg': 'website/thumbnail-transparent.svg',
    'html-notes-collage.svg': 'syllabus/assets/html-notes-collage.svg',
    'fog-of-war-challenge.png': 'syllabus/assets/fog-of-war-challenge.png',
}
ASSET_SUFFIXES = {'.css', '.js', '.svg', '.png', '.jpg', '.jpeg', '.gif', '.webp',
                  '.ttf', '.otf', '.woff', '.woff2'}


def note_outputs(note: dict) -> dict[str, str]:
    source = Path(note['source'])
    return {'html': source.stem + '.html', 'pdf': f'pdf/{source.stem}.pdf'}


def slide_output(source: str) -> str:
    if not isinstance(source, str) or Path(source).suffix.lower() != '.pdf':
        raise ValueError(f'Configured slides must be PDFs: {source!r}')
    return 'slides/' + Path(source).name


def copied_files(config: dict) -> dict[str, str]:
    files = {'assets/course/' + name: source for name, source in COURSE_FIGURES.items()}
    owners = {}
    slides = config.get('slides', {})
    if not isinstance(slides, dict):
        raise ValueError('slides must map stable lecture IDs to PDF source paths.')
    for source in slides.values():
        output = slide_output(source)
        key = output.casefold()
        if key in owners and owners[key] != source:
            raise ValueError(f'Colliding slide output: {output} ({owners[key]}, {source})')
        owners[key] = source
        files[output] = source
    return files


def required_files(config: dict) -> set[str]:
    required = {'index.html', 'syllabus.pdf'}
    claimed = {name.casefold() for name in required}
    for note in config['notes']:
        for output in note_outputs(note).values():
            if output.casefold() in claimed:
                raise ValueError(f'Colliding note output: {output}')
            claimed.add(output.casefold())
            required.add(output)
    required.update(copied_files(config))
    return required


def validate_public_path(name: str, required: set[str]) -> None:
    path = PurePosixPath(name)
    if (not name or path.is_absolute() or name != path.as_posix()
            or any(part.startswith('.') or part.lower().startswith('fow')
                   or part.lower() == 'challenge' for part in path.parts)
            or '\\' in name or any(ord(c) < 32 for c in name)):
        raise ValueError(f'Unsafe or private manifest path: {name!r}')
    is_asset = (path.parts[0] == 'assets' and
                (path.suffix in ASSET_SUFFIXES or name in
                 {'assets/katex/LICENSE', 'assets/katex/VERSION'}))
    if name not in required and not is_asset:
        raise ValueError(f'Unexpected public build artifact: {name}')


def validate_inputs(config: dict, modules: list[dict], root: Path) -> None:
    """Fail before writing outputs, including for unlinked or corrupt slides."""
    required = required_files(config)
    for name in required:
        validate_public_path(name, required)
    ids = {r['id'] for m in modules for r in m['rows'] if r['kind'] == 'lecture'}
    if unknown := config.get('slides', {}).keys() - ids:
        raise ValueError('Unknown slide lecture IDs: ' + ', '.join(sorted(unknown)))
    sources = [n['source'] for n in config['notes']] + list(copied_files(config).values())
    for source in set(sources):
        path = root / source
        if Path(source).is_absolute() or not path.resolve().is_relative_to(root.resolve()):
            raise ValueError(f'Source must stay inside the course directory: {source}')
        if not path.is_file():
            raise ValueError(f'Missing course source: {source}')
    for source in set(config.get('slides', {}).values()):
        result = subprocess.run(['pdfinfo', str(root / source)], capture_output=True, text=True)
        if result.returncode:
            raise ValueError(f'Invalid slide PDF: {source}\n{result.stderr.strip()}')


def copy_public_files(config: dict, root: Path, destination: Path) -> None:
    for output, source in copied_files(config).items():
        target = destination / output
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(root / source, target)
