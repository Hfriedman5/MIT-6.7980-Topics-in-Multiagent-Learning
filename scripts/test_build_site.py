"""Guard the per-lecture PDF build and its advertised download link."""
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import build_site


class LecturePdfBuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.stage = self.root / '.build/site'
        for path in ('source', 'pdf'):
            (self.stage / path).mkdir(parents=True, exist_ok=True)
        (self.root / '.build/logs').mkdir()
        self.source = self.root / 'Typst Lectures/content/lecture.typ'
        self.source.parent.mkdir(parents=True)
        self.source.write_text('''#import "../meta/gabri_notes_bk.typ": *
#image("../figures/game.png")
Lecture prose.
''')
        self.chapter = {'source': 'Typst Lectures/content/lecture.typ', 'number': 3}
        self.original = self.source.read_text()
        for name, value in (('ROOT', self.root), ('STAGE', self.stage)):
            replacement = patch.object(build_site, name, value)
            replacement.start()
            self.addCleanup(replacement.stop)

    def test_pdf_source_preserves_prose_and_resolves_asset_paths(self):
        generated = build_site.prepare_pdf_source(self.source).read_text()
        self.assertIn('#import "/Typst Lectures/meta/gabri_notes_pdf.typ": *', generated)
        self.assertIn('#image("/Typst Lectures/figures/game.png")', generated)
        self.assertIn('Lecture prose.', generated)
        self.assertEqual(self.source.read_text(), self.original)

    def test_pdf_is_compiled_before_its_link_is_exported(self):
        calls = []

        def compile(args, **kwargs):
            calls.append(args)
            output = Path(args[-1])
            if args[0] == 'typst':
                output.write_bytes(b'%PDF-1.7\n')
            else:
                self.assertTrue((self.stage / 'pdf/lecture.pdf').is_file())
                self.assertEqual(args[args.index('--pdf') + 1], 'pdf/lecture.pdf')
                output.write_text('<style>body {}</style><p>Lecture prose.</p>')
            return subprocess.CompletedProcess(args, 0)

        with patch.object(build_site.subprocess, 'run', side_effect=compile):
            build_site.build_chapter(self.chapter)
        self.assertEqual(calls[0][:2], ['typst', 'compile'])
        self.assertEqual(Path(calls[0][-1]), self.stage / 'pdf/lecture.pdf')
        self.assertEqual(len(calls), 2)
        self.assertEqual((self.stage / 'source/lecture.typ').read_text(), self.original)

    def test_pdf_failure_stops_before_exporting_a_dead_link(self):
        with patch.object(build_site.subprocess, 'run',
                          return_value=subprocess.CompletedProcess([], 1)) as run:
            with self.assertRaisesRegex(RuntimeError, 'Lecture 3 PDF failed'):
                build_site.build_chapter(self.chapter)
        self.assertEqual(run.call_count, 1)

    def test_header_validation_rejects_dates_from_another_edition(self):
        config = {'site': {'term': 'Fall 2026'}, 'lectures': [self.chapter]}
        schedule = [{'rows': [{'number': 3, 'iso_date': '2026-09-22'}]}]
        self.source.write_text('#show: gabri_notes.with(lec_num: 3, date: [Tue, Sep 22, 2026])')
        build_site.validate_source_headers(config, schedule)
        self.source.write_text('#show: gabri_notes.with(lec_num: 3, date: [Tue, Sep 16, 2025])')
        with self.assertRaisesRegex(ValueError, 'expected lecture 3, date Tue, Sep 22, 2026'):
            build_site.validate_source_headers(config, schedule)

    def test_supplementary_header_uses_term_instead_of_a_class_date(self):
        self.chapter.update(number='S1', supplementary=True)
        self.source.write_text('#show: gabri_notes.with(lec_num: "S1", date: [Fall 2026])')
        build_site.validate_source_headers({'site': {'term': 'Fall 2026'}, 'lectures': [self.chapter]}, [])


if __name__ == '__main__':
    unittest.main()
