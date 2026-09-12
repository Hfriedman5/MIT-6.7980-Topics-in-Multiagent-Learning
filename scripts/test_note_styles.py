"""Exercise paths and removed compiler modes at the style boundary."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

from check_site import Page

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('typst'), 'Typst CLI is required')
class NoteStyleTests(unittest.TestCase):
    def test_styles_reject_removed_compiler_inputs(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'probe.typ'
            for style in ('gabri_notes', 'gabri_notes_html'):
                source.write_text(
                    f'#import {json.dumps(str(ROOT / "content/meta" / (style + ".typ")))}: *\n')
                for option in ('web', 'html', 'combined'):
                    with self.subTest(style=style, option=option):
                        result = subprocess.run(
                            ['typst', 'compile', '--root', ROOT.anchor,
                             '--input', f'{option}=false', str(source),
                             str(source.with_suffix('.pdf'))],
                            capture_output=True, text=True)
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn('inputs are unsupported', result.stderr)


if __name__ == "__main__":
    unittest.main()
