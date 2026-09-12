"""Native cross-note references, isolated previews, and lecture-scoped citations."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

from lecture_links import validate_lecture_links
from test_html_references import ReferencePage

ROOT = Path(__file__).resolve().parents[1]


class LectureLinkValidationTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.root = Path(folder.name)
        self.source = self.root / 'one.typ'
        self.target = self.root / 'two.typ'
        self.source.write_text('#lecture-link("two", <stable-result>)[The result]')
        self.target.write_text('= The result <stable-result>\n')
        self.config = {'notes': [{'source': 'one.typ'}, {'source': 'two.typ'}]}

    def test_renaming_heading_text_preserves_links(self):
        self.target.write_text('= Renamed result <stable-result>\n')
        self.assertEqual(validate_lecture_links(self.root, self.config), 1)

    def test_missing_or_ambiguous_heading_is_rejected(self):
        for text in ('= Result <renamed-label>',
                     '= Result <stable-result>\n== Another <stable-result>',
                     'Unattached label <stable-result>'):
            with self.subTest(text=text):
                self.target.write_text(text)
                with self.assertRaisesRegex(ValueError, 'expected one labeled section or environment'):
                    validate_lecture_links(self.root, self.config)

    def test_whole_lecture_needs_no_heading(self):
        self.source.write_text('#lecture-link("two", none)[]')
        self.target.write_text('No numbered headings.')
        self.assertEqual(validate_lecture_links(self.root, self.config), 1)

    def test_unpublished_note_is_rejected(self):
        self.config['notes'].pop()
        with self.assertRaisesRegex(ValueError, 'unknown linked lecture'):
            validate_lecture_links(self.root, self.config)

    def test_dynamic_or_local_destinations_are_rejected(self):
        for call in ('#lecture-link(name, <stable-result>)[Result]',
                     '#lecture-link("../two", <stable-result>)[Result]',
                     '#lecture-link("one", <stable-result>)[Result]'):
            with self.subTest(call=call):
                self.source.write_text(call)
                with self.assertRaises(ValueError):
                    validate_lecture_links(self.root, self.config)


@unittest.skipUnless(shutil.which('typst'), 'Typst CLI is required')
class LectureLinkRenderingTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory(prefix='lecture-link-test-')
        self.addCleanup(folder.cleanup)
        self.folder = Path(folder.name)

    def compile(self, body, *, html=True, bundle=False, inputs=(), expect_error=None):
        helper = ROOT / 'content/meta' / ('gabri_notes_html.typ' if html else 'gabri_notes.typ')
        source = self.folder / 'probe.typ'
        source.write_text(f'#import {json.dumps(str(helper))}: *\n' + body)
        output = self.folder / 'bundle' if bundle else source.with_suffix('.html' if html else '.pdf')
        args = ['typst', 'compile', '--root', ROOT.anchor,
                '--font-path', str(ROOT / 'html-exporter/assets/fonts')]
        if bundle:
            args += ['--features', 'html,bundle', '--format', 'bundle', '--input', 'course-bundle=true']
        elif html:
            args += ['--features', 'html', '--format', 'html']
        for value in inputs:
            args += ['--input', value]
        result = subprocess.run([*args, str(source), str(output)], capture_output=True, text=True)
        if expect_error:
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(expect_error, result.stderr)
        else:
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('did not converge', result.stderr)
        return output

    def fixture(self, number, *, html=True, inserted=False):
        source = 'source.html' if html else 'pdf/source.pdf'
        destination = 'destination.html' if html else 'pdf/destination.pdf'
        insertion = '= Earlier section\n#example[Earlier example.]' if inserted else ''
        return f'''
#document("{source}", title: lecture-title(5, [Source]))[
  #show: gabri_notes.with(lec_num: 5, title: [Source])
  #example[An unrelated example.]
  #theorem[An earlier result.] <source-result>
  #lecture-link("destination", <target-theorem>)[the _result_]
  #lecture-link("destination", <target-section>)[]
  #lecture-link("destination", <target-appendix>)[]
  #lecture-link("destination", none)[]
]
#document("{destination}", title: lecture-title({json.dumps(number)}, [Destination]))[
  #show: gabri_notes.with(lec_num: {json.dumps(number)}, title: [Destination])
  {insertion}
  = Destination <target-section>
  #theorem[The target result.] <target-theorem>
  #lecture-link("source", <source-result>)[the earlier result]
  #appendix[
    = Details <target-appendix>
    Details of the proof.
  ]
]
'''

    def test_native_bundle_references_follow_actual_counters_in_both_directions(self):
        for number, prefix in ((19, 'L19'), ('S8', 'S8')):
            for inserted in (False, True):
                with self.subTest(number=number, inserted=inserted):
                    output = self.compile(self.fixture(number, inserted=inserted), bundle=True)
                    page = ReferencePage((output / 'source.html').read_text())
                    target = ReferencePage((output / 'destination.html').read_text())
                    n = 2 if inserted else 1
                    kind = 'Supplementary Reading' if prefix.startswith('S') else 'Lecture'
                    self.assertEqual([''.join(ref['text']) for ref in page.references], [
                        f'the result (Theorem\u00a0{prefix}.{n})',
                        f'Section\u00a0{prefix}.{n}', f'Section\u00a0{prefix}.A',
                        f'{kind}\u00a0{number}, “Destination”',
                    ])
                    self.assertIn('em', page.references[0]['tags'])
                    self.assertEqual([ref['href'] for ref in page.references], [
                        'destination.html#target-theorem', 'destination.html#target-section',
                        'destination.html#target-appendix', 'destination.html',
                    ])
                    for ref in page.references[:3]:
                        self.assertIn(ref['href'].split('#')[1], target.ids)
                    self.assertEqual(''.join(target.references[0]['text']),
                                     'the earlier result (Theorem\u00a0L5.2)')
                    self.assertIn(target.references[0]['href'].split('#')[1], page.ids)

    def test_native_typst_rejects_an_invalid_reference_target(self):
        body = self.fixture(19).replace('#theorem[The target result.]', '#text[Unnumbered text.]')
        self.compile(body, bundle=True, expect_error='cannot reference text')

    def test_standalone_preview_uses_the_destination_notes_own_header(self):
        output = self.compile('''
#show: gabri_notes.with(lec_num: 5, title: [Source])
See #lecture-link("learning_intro", <sec-learning-zero-sum>)[the _self-play_ proof].
''')
        page = ReferencePage(output.read_text())
        self.assertEqual(page.references[0]['href'], 'learning_intro.html#sec-learning-zero-sum')
        self.assertEqual(''.join(page.references[0]['text']),
                         'the self-play proof (Lecture\u00a04, “Learning in games: Foundations”)')
        self.assertIn('em', page.references[0]['tags'])

    @unittest.skipUnless(shutil.which('pdfinfo'), 'Poppler is required for PDF links')
    def test_native_pdf_links_have_relative_urls_and_matching_named_destinations(self):
        output = self.compile(self.fixture('S8', html=False, inserted=True), html=False, bundle=True)
        source = output / 'pdf/source.pdf'
        target = output / 'pdf/destination.pdf'
        urls = subprocess.check_output(['pdfinfo', '-url', str(source)], text=True)
        for anchor in ('target-theorem', 'target-section', 'target-appendix'):
            self.assertIn('destination.pdf#' + anchor, urls)
        dests = subprocess.check_output(['pdfinfo', '-dests', str(target)], text=True)
        for anchor in ('target-theorem', 'target-section', 'target-appendix'):
            self.assertIn('"' + anchor + '"', dests)
        text = subprocess.check_output(['pdftotext', str(source), '-'], text=True)
        self.assertIn('Theorem S8.2', text)
        self.assertIn('Section S8.A', text)

    @unittest.skipUnless(shutil.which('pdfinfo'), 'Poppler is required for PDF links')
    def test_standalone_pdf_uses_canonical_web_links_and_honors_override(self):
        configured = json.loads((ROOT / 'html-export.json').read_text())['how_to_cite']['url_prefix']
        for base, inputs in ((configured, ()),
                             ('https://example.org/course/', ('course-url=https://example.org/course/',))):
            with self.subTest(base=base):
                output = self.compile('''
#show: gabri_notes.with(lec_num: 5, title: [PDF source])
See #lecture-link("learning_intro", <sec-learning-zero-sum>)[the self-play proof].
''', html=False, inputs=inputs)
                urls = subprocess.check_output(['pdfinfo', '-url', str(output)], text=True)
                self.assertIn(base + 'learning_intro.html#sec-learning-zero-sum', urls)

    def test_native_html_bibliographies_and_first_citation_notes_stay_with_their_lecture(self):
        output = self.compile('''
#document("one.html")[
  #show: gabri_notes.with(lec_num: 1, title: [One])
  #citep(<Nash51:NonCooperative>)
  #lec_bibliography("refs.bib")
]
#document("two.html")[
  #show: gabri_notes.with(lec_num: 2, title: [Two])
  #citep(<Nash51:NonCooperative>) and #citep(<auer2002nonstochastic>)
  #lec_bibliography("refs.bib")
]
''', bundle=True)
        first = (output / 'one.html').read_text()
        second = (output / 'two.html').read_text()
        self.assertIn('id="bib-Nash51-NonCooperative"', first)
        self.assertNotIn('id="bib-auer2002nonstochastic"', first)
        self.assertIn('id="bib-Nash51-NonCooperative"', second)
        self.assertIn('id="bib-auer2002nonstochastic"', second)
        self.assertEqual(first.count('class="citation-note"'), 1)
        self.assertEqual(second.count('class="citation-note"'), 2)
        entry = re.search(r'class="bib-entry">(.*?)</td>', first, re.S)[1]
        self.assertNotIn('[Nas51]', entry)
        self.assertIn('Non-Cooperative Games', entry)
        self.assertIn('href="http://www.jstor.org/stable/1969529"', entry)

    @unittest.skipUnless(shutil.which('pdftotext'), 'Poppler is required for PDF bibliographies')
    def test_native_pdf_bibliographies_include_only_their_own_citations(self):
        shutil.copy2(ROOT / 'content/meta/refs.bib', self.folder / 'refs.bib')
        output = self.compile('''
#document("one.pdf")[
  #show: gabri_notes.with(lec_num: 1, title: [One])
  #citep(<Nash51:NonCooperative>)
  #lec_bibliography("refs.bib")
]
#document("two.pdf")[
  #show: gabri_notes.with(lec_num: 2, title: [Two])
  #citep(<auer2002nonstochastic>)
  #lec_bibliography("refs.bib")
]
''', html=False, bundle=True)
        first, second = [' '.join(subprocess.check_output(
            ['pdftotext', str(output / name), '-'], text=True).split())
            for name in ('one.pdf', 'two.pdf')]
        self.assertIn('Non-Cooperative Games', first)
        self.assertNotIn('nonstochastic', first.lower())
        self.assertIn('nonstochastic', second.lower())
        self.assertNotIn('Non-Cooperative Games', second)


if __name__ == '__main__':
    unittest.main()
