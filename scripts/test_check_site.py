"""Regression checks for content silently discarded by Typst HTML export."""
from pathlib import Path
import unittest

from check_site import (
    Page, dropped_content_warnings, image_inventory_issues, source_image_paths,
)


class ImageInventoryTests(unittest.TestCase):
    source = Path('/course/content/lecture.typ')

    def issues(self, source_text, html):
        return image_inventory_issues(self.source, source_text, Page(html), 'lecture.html')

    def test_missing_image_without_any_broken_img_tag(self):
        # This is how the original failure looked: the image vanished completely.
        issues = self.issues('#align(center, image("../figures/game.svg"))',
                             '<div class="align"></div>')
        self.assertEqual(len(issues), 1)
        self.assertIn('expected 1 rendered occurrence(s), found 0', issues[0])

    def test_captioned_svg_image_marker_is_counted(self):
        self.assertEqual(self.issues(
            '#figure(caption: [A game.])[#image("../figures/game.svg")]',
            '<figure><div class="figure-body"><span '
            'data-image-source="&quot;../figures/game.svg&quot;">'
            '<svg></svg></span></div><figcaption>A game.</figcaption></figure>'), [])

    def test_present_image_with_zero_svg_frame_is_rejected(self):
        issues = self.issues(
            '#image("game.svg", width: 100%)',
            '<span data-image-source="&quot;game.svg&quot;"><svg '
            'style="overflow:visible; width: 0em; height: 0em" '
            'viewBox="0 0 1 1" width="1pt" height="1pt"></svg></span>')
        self.assertEqual(len(issues), 2)
        self.assertTrue(all('zero-size rendered image' in issue for issue in issues))
        self.assertTrue(any("width='0em'" in issue for issue in issues))
        self.assertTrue(any("height='0em'" in issue for issue in issues))

    def test_zero_nested_image_is_rejected_even_with_nonzero_frame(self):
        issues = self.issues(
            '#image("game.svg")',
            '<span data-image-source="&quot;game.svg&quot;"><svg '
            'style="width: 20em; height: 10em"><g>'
            '<image width="0" height="100"/></g></svg></span>')
        self.assertEqual(len(issues), 1)
        self.assertIn("<image> width='0'", issues[0])

    def test_empty_math_frame_outside_image_is_permitted(self):
        self.assertEqual(self.issues(
            '#image("game.svg")',
            '<span data-image-source="&quot;game.svg&quot;"><svg '
            'style="width: 20em; height: 10em"><image width="200" '
            'height="100"/></svg></span><br>'
            '<span role="math"><svg style="width:0em;height:0em">'
            '<image width="0" height="0"/></svg></span>'), [])

    def test_duplicate_source_calls_require_duplicate_rendered_markers(self):
        issues = self.issues('#image("same.svg") #image("same.svg")',
                             '<span data-image-source="&quot;same.svg&quot;"></span>')
        self.assertEqual(len(issues), 1)
        self.assertIn('expected 2 rendered occurrence(s), found 1', issues[0])

    def test_equal_totals_with_wrong_path_still_fail(self):
        issues = self.issues('#image("expected.svg")',
                             '<span data-image-source="&quot;different.svg&quot;"></span>')
        self.assertEqual(len(issues), 2)
        self.assertTrue(any('expected.svg' in issue for issue in issues))
        self.assertTrue(any('different.svg' in issue for issue in issues))

    def test_paths_are_normalized(self):
        self.assertEqual(self.issues(
            '#image("../figures/game.svg")',
            '<span data-image-source="&quot;/course/figures/game.svg&quot;"></span>'), [])

    def test_invalid_marker_does_not_crash_validation(self):
        issues = self.issues('', '<span data-image-source="not a string"></span>')
        self.assertEqual(len(issues), 1)
        self.assertIn('invalid data-image-source', issues[0])

    def test_source_comments_strings_and_raw_examples_are_excluded(self):
        source = '''
// #image("comment.svg")
/* nested /* #image("inner.svg") */ image("outer.svg") */
#let example = "image(\\"string.svg\\")"
`#image("inline-example.svg")`
```typst
#image("block-example.svg")
```
#align(center, image("../figures/real.svg", width: 50%))
#figure[#image("../figures/real.svg")]
'''
        self.assertEqual(source_image_paths(source),
                         ['../figures/real.svg', '../figures/real.svg'])


class DroppedContentWarningTests(unittest.TestCase):
    def test_spacing_and_experimental_export_warnings_are_permitted(self):
        self.assertEqual(dropped_content_warnings(
            'typst warning: html export is under active development and incomplete\n'
            'typst warning: h was ignored during HTML export\n'
            'typst warning: v was ignored during HTML export\n'), [])

    def test_ignored_alignment_and_html_element_fail(self):
        warnings = dropped_content_warnings(
            'typst warning: align was ignored during HTML export\n'
            'warning: elem may not occur inside of a paragraph and was ignored\n'
            '    source context\n')
        self.assertEqual(warnings, [
            'align was ignored during HTML export',
            'elem may not occur inside of a paragraph and was ignored',
        ])


if __name__ == '__main__':
    unittest.main()
