"""Protect the syllabus-to-reading mapping and fail closed on lost sessions."""
import copy
import json
import re
from pathlib import Path
import unittest

from check_site import Page
from course_index import read_schedule, render_index, validate_readings

ROOT = Path(__file__).resolve().parents[1]


class CourseIndexTests(unittest.TestCase):
    def setUp(self):
        self.config = json.loads((ROOT / 'html-export.json').read_text())
        self.syllabus = (ROOT / self.config['site']['syllabus_source']).read_text()
        self.modules = read_schedule(self.syllabus, self.config['site']['year'])

    def test_full_semester_preserves_both_calendar_exceptions(self):
        rows = [row for module in self.modules for row in module['rows']]
        self.assertEqual([r['number'] for r in rows if r['number'] is not None], list(range(25)))
        self.assertEqual(rows[0]['title'], 'Course Overview')
        self.assertEqual(rows[1]['title'], 'Setting and equilibria: the Nash equilibrium')
        self.assertEqual([r['iso_date'] for r in rows if r['number'] is None],
                         ['2026-10-13', '2026-11-26'])
        self.assertEqual(rows[-1]['iso_date'], '2026-12-10')

    def test_missing_or_unreadable_class_fails_instead_of_disappearing(self):
        for source in (self.syllabus.replace('    7,', '    8,'),
                       self.syllabus.replace('"Oct 1",', '[Oct 1],')):
            with self.subTest(source=source[-50:]), self.assertRaises(ValueError):
                read_schedule(source, 2026)

    def test_standalone_sessions_do_not_extend_foundations(self):
        standalone = [m for m in self.modules if not m['title']]
        self.assertEqual([[r['number'] for r in m['rows']] for m in standalone], [[0], [9]])
        foundations = next(m for m in self.modules if 'Foundations' in m['title'])
        self.assertEqual([r['number'] for r in foundations['rows'] if r['number'] is not None],
                         list(range(1, 9)))

    def test_every_note_and_pdf_remains_reachable_with_no_placeholder_links(self):
        html = render_index(self.config, self.modules)
        page = Page(html)
        for chapter in self.config['lectures']:
            stem = Path(chapter['source']).stem
            self.assertIn(stem + '.html', page.links)
            self.assertIn('pdf/' + stem + '.pdf', page.links)
        self.assertIn('syllabus.pdf', page.links)
        self.assertNotIn('#', page.links)
        self.assertNotIn('Readings are drawn from the Fall 2025 notes', html)

    def test_note_numbers_match_the_current_syllabus(self):
        validate_readings(self.config, self.modules)
        chapters = {Path(c['source']).stem: c for c in self.config['lectures']}
        self.assertEqual(chapters['nfgs_nash']['syllabus_numbers'], [1])
        self.assertEqual(chapters['nfgs_nash']['number'], 1)
        self.assertEqual(chapters['bandit']['syllabus_numbers'], [6])
        self.assertEqual(chapters['bandit']['number'], 6)
        self.assertEqual(chapters['learning2']['syllabus_numbers'], [])
        self.assertTrue(chapters['learning2']['supplementary'])
        self.assertEqual(chapters['learning2']['number'], 'S3')
        config = copy.deepcopy(self.config)
        config['lectures'][0], config['lectures'][1] = config['lectures'][1], config['lectures'][0]
        with self.assertRaisesRegex(ValueError, 'out of syllabus order'):
            validate_readings(config, self.modules)

    def test_course_overview_has_no_notes_or_pending_label(self):
        html = render_index(self.config, self.modules)
        overview = re.search(r'<tr class="schedule-row">\s*<th[^>]*>00</th>.*?</tr>', html, re.S).group()
        self.assertNotIn('<a ', overview)
        self.assertNotIn('Not yet posted', overview)


if __name__ == '__main__':
    unittest.main()
