"""Figure discovery, shared dependencies, and parameterized SVG generation."""
from contextlib import redirect_stdout
import io
from pathlib import Path
import shutil
import tempfile
import unittest
import xml.etree.ElementTree as ET

from build_figures import build_figures


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


if __name__ == '__main__':
    unittest.main()
