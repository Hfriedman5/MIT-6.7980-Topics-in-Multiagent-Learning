"""Lay out the original lecture screenshots as an SVG collage.

The screenshots remain unmodified; SVG viewports frame selected excerpts.
Run this script after changing the screenshots or their arrangement.
"""
from base64 import b64encode
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'syllabus/assets'


def panel(name, original_size, crop, position, size, angle):
    x, y = position
    width, height = size
    original_width, original_height = original_size
    crop_box = ' '.join(map(str, crop))
    image = b64encode((ASSETS / name).read_bytes()).decode('ascii')
    return f'''<g transform="translate({x} {y}) rotate({angle} {width / 2} {height / 2})">
  <rect x="5" y="8" width="{width}" height="{height}" rx="8" fill="#292722" opacity=".10"/>
  <rect width="{width}" height="{height}" rx="8" fill="#ffffff" stroke="#d5d2cc" stroke-width="1.6"/>
  <svg x="10" y="10" width="{width - 20}" height="{height - 20}" viewBox="{crop_box}" preserveAspectRatio="xMidYMid slice" overflow="hidden">
    <image width="{original_width}" height="{original_height}" href="data:image/png;base64,{image}"/>
  </svg>
</g>'''


def main():
    panels = [
        panel('course-home-screenshot.png', (2590, 2066),
              (250, 12, 1570, 800), (25, 38), (755, 395), -1.2),
        panel('notes-nash-screenshot.png', (2338, 2080),
              (25, 45, 2220, 1990), (50, 460), (685, 618), -1.6),
        panel('notes-game-tree-screenshot.png', (2312, 2066),
              (181, 500, 1560, 1024), (801, 34), (750, 500), 1.5),
        panel('notes-topology-screenshot.png', (3010, 2076),
              (32, 42, 2920, 2010), (815, 551), (742, 524), -.9),
    ]
    svg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1100" viewBox="0 0 1600 1100">
<title>The course website and HTML lecture notes</title>
<desc>A collage of four original screenshots showing the course homepage, colorful equilibrium dynamics, a Kuhn poker game tree, and the topology of Nash equilibria. The lecture screenshots include the website navigation sidebar.</desc>
<rect x="1" y="1" width="1598" height="1098" rx="18" fill="#f6f5f1" stroke="#d5d2cc" stroke-width="2"/>
''' + '\n'.join(panels) + '\n</svg>\n'
    (ASSETS / 'html-notes-collage.svg').write_text(svg)


if __name__ == '__main__':
    main()
