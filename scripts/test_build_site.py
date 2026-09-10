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
        self.source = self.root / 'content/content/lecture.typ'
        self.source.parent.mkdir(parents=True)
        self.source.write_text('''#import "../meta/gabri_notes_bk.typ": *
#image("../figures/game.png")
Lecture prose.
''')
        self.chapter = {'source': 'content/content/lecture.typ', 'number': 3}
        self.original = self.source.read_text()
        for name, value in (('ROOT', self.root), ('STAGE', self.stage)):
            replacement = patch.object(build_site, name, value)
            replacement.start()
            self.addCleanup(replacement.stop)

    def test_pdf_source_preserves_prose_and_resolves_asset_paths(self):
        generated = build_site.prepare_pdf_source(self.source).read_text()
        self.assertIn('#import "/content/meta/gabri_notes_pdf.typ": *', generated)
        self.assertIn('#image("/content/figures/game.png")', generated)
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

    def test_schedule_controls_generated_note_headers_without_editing_source(self):
        self.source.write_text('#import "../meta/gabri_notes_bk.typ": *\n'
                               '#show: gabri_notes.with(lec_num: 3, date: [Tue, Sep 16, 2025])')
        original = self.source.read_text()
        self.chapter.update(number=8, date='Thu, Oct 8, 2026')
        for generated in (build_site.prepare_pdf_source(self.source, self.chapter),
                          build_site.prepare_html_source(self.source, self.chapter)):
            self.assertIn('lec_num: 8, date: [Thu, Oct 8, 2026]', generated.read_text())
        self.assertEqual(self.source.read_text(), original)
        self.assertIn('#import "/content/meta/gabri_notes_html.typ": *',
                      build_site.prepare_html_source(self.source, self.chapter).read_text())

    def test_supplementary_header_uses_term_instead_of_a_class_date(self):
        self.chapter.update(number='S1', supplementary=True, date='Fall 2026')
        self.source.write_text('#show: gabri_notes.with(lec_num: 5, date: [old term])')
        content = build_site.chapter_source_text(self.source, self.chapter)
        self.assertIn('lec_num: "S1", date: [Fall 2026]', content)

    def test_missing_note_header_fails_instead_of_silently_using_old_metadata(self):
        self.chapter['date'] = 'Thu, Oct 8, 2026'
        with self.assertRaisesRegex(ValueError, 'expected one lecture number and date'):
            build_site.prepare_pdf_source(self.source, self.chapter)


if __name__ == '__main__':
    unittest.main()
