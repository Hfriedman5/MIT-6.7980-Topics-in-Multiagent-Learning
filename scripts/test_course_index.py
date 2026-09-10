"""Protect the syllabus-to-reading mapping and fail closed on lost sessions."""
import copy
import json
import re
import tempfile
from datetime import date, timedelta
from pathlib import Path
import unittest

from check_site import Page
from course_index import read_schedule, render_index, resolve_readings, validate_readings

ROOT = Path(__file__).resolve().parents[1]


class CourseIndexTests(unittest.TestCase):
    def setUp(self):
        self.config = json.loads((ROOT / 'html-export.json').read_text())
        self.path = ROOT / self.config['site']['syllabus_source']
        self.syllabus = self.path.read_text()
        self.modules = read_schedule(self.path, self.config['site']['year'])

    def evaluate(self, source):
        with tempfile.NamedTemporaryFile(mode='w', suffix='.typ', dir=self.path.parent) as file:
            file.write(source)
            file.flush()
            return read_schedule(Path(file.name), 2026)

    def lecture_block(self, id):
        start = self.syllabus.index(f'  lecture(\n    "{id}",')
        end = self.syllabus.index('\n  ),', start) + len('\n  ),')
        return self.syllabus[start:end]

    def test_full_semester_preserves_both_calendar_exceptions(self):
        rows = [row for module in self.modules for row in module['rows']]
        lectures = [r for r in rows if r['kind'] == 'lecture']
        self.assertEqual([r['number'] for r in lectures], list(range(len(lectures))))
        self.assertEqual(rows[0]['title'], 'Course Overview')
        self.assertEqual(rows[1]['title'], 'Setting and equilibria: the Nash equilibrium')
        self.assertEqual([r['iso_date'] for r in rows if r['title'] == 'No class'],
                         ['2026-10-13', '2026-11-24', '2026-11-26'])
        self.assertTrue(all(r['number'] is None for r in rows if r['kind'] == 'no-class'))
        self.assertEqual(rows[-1]['iso_date'], '2026-12-10')

    def test_calendar_has_every_official_tuesday_thursday_slot(self):
        expected = []
        day = date(2026, 9, 9)
        while day <= date(2026, 12, 10):
            if day.weekday() in (1, 3):
                expected.append(day.isoformat())
            day += timedelta(days=1)
        rows = [r for m in self.modules for r in m['rows']]
        self.assertEqual([r['iso_date'] for r in rows], expected)
        eligible = [r for r in rows if r['iso_date'] not in ('2026-10-13', '2026-11-26')]
        self.assertEqual(sum(date.fromisoformat(r['iso_date']).weekday() == 1 for r in eligible), 12)
        self.assertEqual(sum(date.fromisoformat(r['iso_date']).weekday() == 3 for r in eligible), 13)

    def test_missing_entries_bad_dates_and_duplicate_ids_fail(self):
        variants = [
            self.syllabus.replace(self.lecture_block('brouwer'), ''),
            self.syllabus.replace('schedule(class-dates,',
                'schedule(class-dates + (class-dates.last(),),'),
            self.syllabus.replace('schedule(class-dates,',
                'schedule(class-dates.rev(),'),
            self.syllabus.replace('schedule(class-dates,',
                'schedule(("bad date",) + class-dates.slice(1),'),
            self.syllabus.replace('"brouwer",', '"nash",'),
            self.syllabus.replace('..calendar-exceptions,',
                '..calendar-exceptions, no-class(on: "2026-09-10"),'),
        ]
        for i, source in enumerate(variants):
            with self.subTest(variant=i), self.assertRaises(ValueError):
                self.evaluate(source)

    def test_reordering_reassigns_dates_numbers_and_note_links(self):
        first, second = self.lecture_block('nash'), self.lecture_block('efg-learning')
        source = self.syllabus.replace(first, 'REORDER_MARKER').replace(second, first).replace('REORDER_MARKER', second)
        modules = self.evaluate(source)
        rows = {r['id']: r for m in modules for r in m['rows'] if r['id']}
        self.assertEqual((rows['nash']['number'], rows['nash']['iso_date']), (8, '2026-10-08'))
        self.assertEqual((rows['efg-learning']['number'], rows['efg-learning']['iso_date']), (1, '2026-09-15'))
        self.assertEqual([r['iso_date'] for m in modules for r in m['rows'] if r['title'] == 'No class'],
                         ['2026-10-13', '2026-11-24', '2026-11-26'])
        resolved = resolve_readings(self.config, modules)
        nash = next(c for c in resolved['lectures'] if c['syllabus_ids'] == ['nash'])
        self.assertEqual((nash['number'], nash['date']), (8, 'Thu, Oct 8, 2026'))
        page = render_index(self.config, modules)
        row = re.search(r'<tr class="schedule-row">\s*<th[^>]*>08</th>.*?</tr>', page, re.S).group()
        self.assertIn('nfgs_nash.html', row)
        self.assertNotIn('learning_efg.html', row)

    def test_nested_typst_content_preserves_text_and_punctuation(self):
        source = self.syllabus.replace('[Course Overview]',
            '[Course *Overview*: #link("https://example.com/path")[Nash\'s games] (intro)]')
        self.assertEqual(self.evaluate(source)[0]['rows'][0]['title'], "Course Overview: Nash's games (intro)")

    def test_standalone_sessions_do_not_extend_foundations(self):
        standalone = [m for m in self.modules if not m['title']]
        self.assertEqual([[r['id'] for r in m['rows']] for m in standalone], [['overview'], ['taking-stock']])
        foundations = next(m for m in self.modules if 'Foundations' in m['title'])
        self.assertNotIn('taking-stock', [r['id'] for r in foundations['rows']])

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
        resolved = resolve_readings(self.config, self.modules)
        chapters = {Path(c['source']).stem: c for c in resolved['lectures']}
        self.assertEqual(chapters['nfgs_nash']['syllabus_numbers'], [1])
        self.assertEqual(chapters['nfgs_nash']['number'], 1)
        self.assertEqual(chapters['bandit']['syllabus_numbers'], [6])
        self.assertEqual(chapters['bandit']['number'], 6)
        self.assertEqual(chapters['learning2']['syllabus_numbers'], [])
        self.assertTrue(chapters['learning2']['supplementary'])
        self.assertEqual(chapters['learning2']['number'], 'S3')
        config = copy.deepcopy(resolved)
        config['lectures'][0], config['lectures'][1] = config['lectures'][1], config['lectures'][0]
        with self.assertRaisesRegex(ValueError, 'out of syllabus order'):
            validate_readings(config, self.modules)

    def test_note_mapping_rejects_missing_lecture_ids(self):
        config = copy.deepcopy(self.config)
        config['lectures'][0]['syllabus_ids'] = ['missing-topic']
        with self.assertRaisesRegex(ValueError, 'Invalid syllabus_ids'):
            resolve_readings(config, self.modules)

    def test_course_overview_has_no_notes_or_pending_label(self):
        html = render_index(self.config, self.modules)
        overview = re.search(r'<tr class="schedule-row">\s*<th[^>]*>00</th>.*?</tr>', html, re.S).group()
        self.assertNotIn('<a ', overview)
        self.assertNotIn('Not yet posted', overview)


if __name__ == '__main__':
    unittest.main()
