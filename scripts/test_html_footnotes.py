"""Compile probes for footnotes that must not split surrounding paragraphs."""
from html.parser import HTMLParser
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'Typst Lectures/meta/gabri_notes_html.typ'


class FootnotePage(HTMLParser):
    def __init__(self, html):
        super().__init__()
        self.paragraphs = []
        self.current_paragraph = None
        self.templates = []
        self.current_template = None
        self.references = []
        self.templates_in_paragraphs = 0
        self.feed(html)

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if tag == 'p':
            self.current_paragraph = []
        if tag == 'template':
            if self.current_paragraph is not None:
                self.templates_in_paragraphs += 1
            self.current_template = {'attrs': attrs, 'text': [], 'math': 0, 'citations': 0}
            self.templates.append(self.current_template)
        if attrs.get('role') == 'doc-noteref':
            self.references.append(attrs)
        if self.current_template is not None:
            if attrs.get('role') == 'math':
                self.current_template['math'] += 1
            if attrs.get('role') == 'doc-biblioref':
                self.current_template['citations'] += 1

    def handle_data(self, text):
        if self.current_paragraph is not None:
            self.current_paragraph.append(text)
        if self.current_template is not None:
            self.current_template['text'].append(text)

    def handle_endtag(self, tag):
        if tag == 'p':
            self.paragraphs.append(''.join(self.current_paragraph or []))
            self.current_paragraph = None
        if tag == 'template':
            self.current_template = None


@unittest.skipUnless(shutil.which('typst'), 'Typst CLI is required for HTML helper probes')
class HtmlFootnoteTests(unittest.TestCase):
    def compile(self, body):
        with tempfile.TemporaryDirectory(prefix='notes-footnote-test-') as folder:
            source = Path(folder) / 'probe.typ'
            output = source.with_suffix('.html')
            source.write_text(f'#import {json.dumps(str(HELPER))}: *\n' + body)
            result = subprocess.run(
                ['typst', 'compile', '--features', 'html', '--format', 'html',
                 '--root', ROOT.anchor, str(source), str(output)],
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('was ignored', result.stderr)
            self.assertNotIn('did not converge', result.stderr)
            return FootnotePage(output.read_text())

    def test_reference_stays_in_paragraph_and_note_keeps_math_and_citations(self):
        page = self.compile('''
#show: gabri_notes.with(lec_num: 99, title: [Footnote probe])
These strategies are called the #emph[reduced]#footnote[The note includes $x^2$ and #citep(label("Nash51:NonCooperative")).] #emph[normal-form plans] of the player.

Afterwards.
#lec_bibliography("refs.bib", title: none)
''')
        self.assertIn('These strategies are called the reduced1 normal-form plans of the player.',
                      page.paragraphs)
        self.assertEqual(page.templates_in_paragraphs, 0)
        self.assertEqual(len(page.templates), 1)
        note = page.templates[0]
        self.assertEqual(note['attrs']['id'], 'html-fn-1')
        self.assertEqual(note['math'], 1)
        self.assertGreaterEqual(note['citations'], 1)
        self.assertIn('The note includes', ''.join(note['text']))

    def test_lectures_collect_only_their_notes_and_keep_unique_ids(self):
        page = self.compile('''
#gabri_notes(lec_num: 2, title: [First])[
First #footnote[First note.] sentence.

Custom #footnote(numbering: n => [†])[Custom note.] label.
]
#gabri_notes(lec_num: 3, title: [Second])[
Second #footnote[Second note.] sentence.
]
''')
        self.assertEqual(len(page.templates), 3)
        self.assertEqual([note['attrs']['id'] for note in page.templates],
                         ['html-fn-1', 'html-fn-2', 'html-fn-3'])
        self.assertEqual([note['attrs']['data-note-label'] for note in page.templates],
                         ['1', '†', '1'])
        self.assertEqual([ref['href'] for ref in page.references],
                         ['#html-fn-1', '#html-fn-2', '#html-fn-3'])
        self.assertEqual([''.join(note['text']).strip() for note in page.templates],
                         ['First note.', 'Custom note.', 'Second note.'])

    def test_many_notes_converge_without_losing_later_bodies(self):
        page = self.compile('''
#show: gabri_notes.with(lec_num: 99, title: [Many footnotes])
#for n in range(12) [
Sentence #n#footnote[Footnote #n with $x^2$.] continues.

]
''')
        self.assertEqual(len(page.references), 12)
        self.assertEqual(len(page.templates), 12)
        self.assertEqual([note['attrs']['id'] for note in page.templates],
                         [f'html-fn-{n}' for n in range(1, 13)])
        self.assertTrue(all(note['math'] == 1 for note in page.templates))
        self.assertTrue(all('continues.' in paragraph for paragraph in page.paragraphs))


if __name__ == '__main__':
    unittest.main()
