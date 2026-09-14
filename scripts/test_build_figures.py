"""Figure discovery, shared dependencies, and parameterized SVG generation."""
from contextlib import redirect_stdout
import io
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

from build_figures import HTML_FIGURES, build_figures, section_reference_inputs


@unittest.skipUnless(shutil.which('typst'), 'Typst CLI is required')
class FigureBuildTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.root = Path(folder.name)
        self.figures = self.root / 'content/figures'
        (self.root / 'html-exporter/assets/fonts').mkdir(parents=True)

    def write(self, name, source):
        path = self.figures / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source)
        return path

    def build(self):
        with redirect_stdout(io.StringIO()):
            build_figures(self.root)

    def svg_width(self, name):
        return float(ET.parse(self.figures / name).getroot().attrib['viewBox'].split()[2])

    def test_creates_missing_svg_and_rebuilds_after_shared_dependency_changes(self):
        self.write('libs/size.typ', '#let size = 12pt')
        self.write('example/plot.typ', '''
#import "../libs/size.typ": size
#set page(width: auto, height: auto, margin: 0pt)
#rect(width: size, height: 10pt, stroke: none)
''')
        # These sources must only be compiled through their including figures.
        self.write('learning2/ftr_ent.typ', '#panic("component-only source")')
        self.write('kernelized/vertices.typ', '#panic("shared drawing helper")')
        self.build()
        self.assertEqual(self.svg_width('example/plot.svg'), 12)
        self.assertEqual(list(self.figures.rglob('*.svg')), [self.figures / 'example/plot.svg'])

        self.write('libs/size.typ', '#let size = 27pt')
        self.build()
        self.assertEqual(self.svg_width('example/plot.svg'), 27)

    def test_one_gate_source_generates_all_six_outputs_with_distinct_inputs(self):
        widths = {'assignment': 11, 'constant': 12, 'addition': 13,
                  'subtraction': 14, 'multiplication': 15, 'comparison': 16}
        entries = ', '.join(f'{gate}: {width}pt' for gate, width in widths.items())
        self.write('ppad_completeness/gate.typ', f'''
#set page(width: auto, height: auto, margin: 0pt)
#let widths = ({entries})
#rect(width: widths.at(sys.inputs.at("gate")), height: 10pt, stroke: none)
''')
        self.build()
        self.assertEqual(len(list(self.figures.rglob('*.svg'))), 6)
        for gate, width in widths.items():
            with self.subTest(gate=gate):
                self.assertEqual(self.svg_width(f'ppad_completeness/gate_{gate}.svg'), width)
                html = self.root / HTML_FIGURES / f'ppad_completeness/gate_{gate}.svg'
                self.assertEqual(float(ET.parse(html).getroot().attrib['viewBox'].split()[2]), width)

    def test_html_and_pdf_figures_have_independent_typography(self):
        self.write('example/plot.typ', '''
#set page(width: auto, height: auto, margin: 0pt)
#let html = sys.inputs.at("figure-format", default: "pdf") == "html"
#set text(font: if html { "Georgia" } else { "New Computer Modern" })
Figure labels
''')
        self.build()
        pdf = self.figures / 'example/plot.svg'
        html = self.root / HTML_FIGURES / 'example/plot.svg'
        self.assertNotEqual(pdf.read_bytes(), html.read_bytes())
        self.assertNotEqual(ET.parse(pdf).getroot().attrib['viewBox'],
                            ET.parse(html).getroot().attrib['viewBox'])
        svg = ET.parse(html).getroot()
        self.assertEqual(svg.attrib.get('data-selectable-text'), 'true')
        text = ''.join(node.text or '' for node in svg.iter('{http://www.w3.org/2000/svg}text'))
        self.assertEqual(text, 'Figure labels')
        self.assertFalse(list(ET.parse(pdf).getroot().iter('{http://www.w3.org/2000/svg}text')))

    def test_section_links_follow_lecture_schedule_and_heading_edits(self):
        self.write('calibration/route.typ', '''
#set page(width: auto, height: auto, margin: 0pt)
#for key in ("sec-calibration-from-regret", "sec-calibration-to-phi") {
  link("#" + key)[Section #sys.inputs.at(key, default: "bootstrap")]
  linebreak()
}
''')
        lecture = self.root / 'content/calibration.typ'
        authored = '''
#let gabri_notes(body, lec_num: none, date: none, title: none) = {
  set heading(numbering: (..nums) => "L" + str(lec_num) + "." + nums.pos().map(str).join("."))
  body
}
#show: gabri_notes.with(lec_num: 99, date: [Old date], title: "Forecasting")
#image("figures/calibration/route.svg")
= Introduction
= Producing forecasts <sec-calibration-from-regret>
= From forecasts to regret <sec-calibration-to-phi>
'''
        lecture.write_text(authored)
        chapter = {'source': 'content/calibration.typ', 'number': 4,
                   'date': 'Thu, Oct 8, 2026', 'title': 'Forecasting'}
        with patch('course_index.load_course', return_value=({'notes': [chapter]}, [])) as load:
            self.assertFalse((self.figures / 'calibration/route.svg').exists())
            self.build()
            self.assert_section_links(('L4.2', 'L4.3'))
            self.assertEqual(lecture.read_text(), authored)

            chapter['number'] = 7
            updated = authored.replace('= Producing forecasts', '= New prerequisite\n= Producing forecasts')
            lecture.write_text(updated)
            self.build()
            self.assert_section_links(('L7.3', 'L7.4'))
            self.assertEqual(lecture.read_text(), updated)
            self.assertEqual(load.call_count, 2)
            load.assert_called_with(self.root / 'html-export.json')

            lecture.write_text(updated.replace('<sec-calibration-to-phi>', '<renamed>'))
            with self.assertRaisesRegex(ValueError, 'Cannot resolve section references'):
                section_reference_inputs(self.root, Path('calibration/route.typ'))

    def assert_section_links(self, numbers):
        svg = ET.parse(self.root / HTML_FIGURES / 'calibration/route.svg').getroot()
        self.assertEqual(svg.attrib.get('data-selectable-text'), 'true')
        namespace = '{http://www.w3.org/2000/svg}'
        links = {}
        for anchor in svg.iter(namespace + 'a'):
            text = ''.join(node.text or '' for node in anchor.iter(namespace + 'text'))
            if text:
                links.setdefault(anchor.attrib['href'], '')
                links[anchor.attrib['href']] += text
        self.assertEqual(links, {
            '#sec-calibration-from-regret': 'Section ' + numbers[0],
            '#sec-calibration-to-phi': 'Section ' + numbers[1],
        })


if __name__ == '__main__':
    unittest.main()
