"""Check Typst's compiled math tree for subscript/function grouping errors."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
INDEXED_FUNCTIONS = {'K', 'λ', 'φ', 'ϕ', 'F'}


def nodes(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from nodes(child)
    elif isinstance(value, list):
        for child in value:
            yield from nodes(child)


def misplaced_arguments(bodies):
    return [node for node in nodes(bodies)
            if node.get('func') == 'attach'
            and node.get('base', {}).get('text') in INDEXED_FUNCTIONS
            and any(child.get('text') == '(' for child in nodes(node.get('b')))]


@unittest.skipUnless(shutil.which('typst'), 'Typst is needed to inspect compiled math')
class KernelizedMathRenderingTests(unittest.TestCase):
    def compile_math(self, formulas):
        # Compile the authored equations with the PDF's actual notation helpers.
        # The temporary document avoids touching the site's prepared sources.
        with tempfile.TemporaryDirectory(prefix='.kernelized-math-', dir=ROOT) as tmp:
            source = Path(tmp) / 'math.typ'
            source.write_text('#import "/content/meta/gabri_notes.typ": *\n'
                              + '\n\n'.join(formulas))
            result = subprocess.run([
                'typst', 'eval', '--root', str(ROOT), '--in', str(source),
                'query(math.equation).map(it => it.body)',
            ], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            return json.loads(result.stdout)

    def test_all_lecture_formulas_keep_arguments_outside_function_subscripts(self):
        source = (ROOT / 'content/kernelized.typ').read_text()
        formulas = re.findall(r'(?<!\\)\$.*?(?<!\\)\$', source, flags=re.S)
        bodies = self.compile_math(formulas)
        self.assertEqual(len(bodies), len(formulas))
        self.assertFalse(misplaced_arguments(bodies))
        symbols = {node.get('base', {}).get('text') for node in nodes(bodies)
                   if node.get('func') == 'attach'}
        self.assertTrue({'K', 'λ', 'F'} <= symbols)
        self.assertTrue({'φ', 'ϕ'} & symbols)

    def test_check_detects_the_actual_typst_parenthesis_trap(self):
        bad = self.compile_math([
            '$K_V(z,w)$', '$lambda_t(v)$', '$phi_V(z)_v$', '$F_j(r)$'])
        symbols = {node['base']['text'] for node in misplaced_arguments(bad)}
        self.assertTrue({'K', 'λ', 'F'} <= symbols)
        self.assertTrue({'φ', 'ϕ'} & symbols)
        good = self.compile_math([
            '$K_(V)(z,w)$', '$lambda_(t)(v)$', '$phi_(V)(z)_v$', '$F_(j)(r)$'])
        self.assertFalse(misplaced_arguments(good))


if __name__ == '__main__':
    unittest.main()
