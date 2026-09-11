"""Exercise attachment validation and the build/deployment file contract."""
from pathlib import Path
import tempfile
import unittest

from public_files import (COURSE_FIGURES, copy_public_files, note_outputs,
                          required_files, validate_inputs, validate_public_path)

ROOT = Path(__file__).resolve().parents[1]


class PublicFilesTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.config = {'notes': [{'source': 'notes/topic.typ'}],
                       'slides': {'overview': 'slides/intro.pdf'}}
        self.modules = [{'rows': [{'kind': 'lecture', 'id': 'overview'},
                                  {'kind': 'lecture', 'id': 'nash'},
                                  {'kind': 'no-class', 'id': None}]}]
        for source in [*COURSE_FIGURES.values(), 'notes/topic.typ']:
            path = self.root / source
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('fixture')
        path = self.root / 'slides/intro.pdf'
        path.parent.mkdir()
        path.write_bytes((ROOT / 'slides/L00_course_intro.pdf').read_bytes())

    def validate(self):
        validate_inputs(self.config, self.modules, self.root)

    def test_unknown_lecture_id_fails_before_copying(self):
        self.config['slides'] = {'typo': 'slides/intro.pdf'}
        with self.assertRaisesRegex(ValueError, 'Unknown slide lecture IDs: typo'):
            self.validate()

    def test_missing_and_corrupt_pdfs_fail(self):
        path = self.root / 'slides/intro.pdf'
        path.unlink()
        with self.assertRaisesRegex(ValueError, 'Missing course source'):
            self.validate()
        path.write_bytes(b'%PDF-1.7\nNot actually a PDF')
        with self.assertRaisesRegex(ValueError, 'Invalid slide PDF'):
            self.validate()

    def test_wrong_extension_and_wrong_shape_fail(self):
        for slides in [{'overview': 'slides/intro.pptx'}, ['slides/intro.pdf']]:
            with self.subTest(slides=slides), self.assertRaises(ValueError):
                required_files({**self.config, 'slides': slides})

    def test_distinct_files_cannot_overwrite_same_output(self):
        self.config['slides']['nash'] = 'other/INTRO.pdf'
        with self.assertRaisesRegex(ValueError, 'Colliding slide output'):
            self.validate()
        self.config['slides']['nash'] = 'slides/intro.pdf'
        self.validate()  # Reusing exactly the same deck is intentional and safe.

    def test_source_cannot_escape_course_directory(self):
        self.config['slides']['overview'] = '../intro.pdf'
        with self.assertRaisesRegex(ValueError, 'inside the course directory'):
            self.validate()

    def test_note_filename_collision_fails_before_compilation(self):
        self.config['notes'].append({'source': 'other/TOPIC.typ'})
        with self.assertRaisesRegex(ValueError, 'Colliding note output'):
            self.validate()

    def test_build_copy_and_deployment_use_the_same_output_names(self):
        self.validate()
        destination = self.root / 'output'
        copy_public_files(self.config, self.root, destination)
        required = required_files(self.config)
        self.assertEqual(note_outputs(self.config['notes'][0]), {
            'html': 'topic.html', 'pdf': 'pdf/topic.pdf', 'source': 'source/topic.typ'})
        for path in destination.rglob('*'):
            if path.is_file():
                name = path.relative_to(destination).as_posix()
                self.assertIn(name, required)
                validate_public_path(name, required)
        for name in ('slides/private.pdf', 'assets/.env', '../index.html', 'fow/private.py'):
            with self.subTest(name=name), self.assertRaises(ValueError):
                validate_public_path(name, required)


if __name__ == '__main__':
    unittest.main()
