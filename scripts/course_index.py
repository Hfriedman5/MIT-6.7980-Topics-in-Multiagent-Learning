"""Course landing page, with the schedule read from the current Typst syllabus."""
from datetime import date
import copy
import json
import subprocess
from html import escape
from pathlib import Path
import re


# Course illustrations copied into the portable site.
COURSE_FIGURES = {
    'course-image-transparent.svg': 'website/thumbnail-transparent.svg',
    'html-notes-collage.svg': 'syllabus/assets/html-notes-collage.svg',
    'fog-of-war-challenge.png': 'syllabus/assets/fog-of-war-challenge.png',
}


ROOT = Path(__file__).resolve().parents[1]


def read_schedule(syllabus: Path, year: int) -> list[dict]:
    """Read the exact schedule evaluated by Typst, including assigned dates."""
    result = subprocess.run([
        'typst', 'eval', '--in', str(syllabus.resolve()), '--root', str(ROOT),
        '--font-path', str(ROOT / 'html-exporter/assets/fonts'),
        'query(<course-schedule>).map(e => e.value)',
    ], cwd=ROOT, text=True, capture_output=True)
    if result.returncode:
        raise ValueError('Cannot evaluate syllabus schedule:\n' + result.stderr)
    schedules = json.loads(result.stdout)
    if len(schedules) != 1:
        raise ValueError('Expected exactly one course-schedule metadata element.')
    modules = []
    for entry in schedules[0]:
        if entry['kind'] == 'module':
            modules.append({'title': entry['title'], 'rows': []})
            continue
        if date.fromisoformat(entry['iso_date']).year != year:
            raise ValueError('Schedule date is outside the configured academic year.')
        if not modules or entry['standalone']:
            modules.append({'title': '', 'rows': []})
        modules[-1]['rows'].append(entry)
    return modules


def resolve_readings(config: dict, modules: list[dict]) -> dict:
    """Resolve stable lecture IDs to current session numbers and note dates."""
    resolved = copy.deepcopy(config)
    rows = {r['id']: r for m in modules for r in m['rows'] if r['kind'] == 'lecture'}
    for chapter in resolved['lectures']:
        ids = chapter.get('syllabus_ids', [])
        if chapter.get('supplementary'):
            if ids:
                raise ValueError('Supplementary notes cannot claim syllabus lectures.')
            chapter['syllabus_numbers'] = []
            chapter['date'] = config['site']['term']
            continue
        if not ids or len(ids) != len(set(ids)) or not set(ids) <= rows.keys():
            raise ValueError(f"Invalid syllabus_ids for {chapter['source']}: {ids}")
        sessions = sorted((rows[id] for id in ids), key=lambda r: r['number'])
        chapter['syllabus_numbers'] = [r['number'] for r in sessions]
        chapter['number'] = sessions[0]['number']
        day = date.fromisoformat(sessions[0]['iso_date'])
        chapter['date'] = f'{day:%a, %b} {day.day}, {day.year}'
    resolved['lectures'].sort(key=lambda c: (bool(c.get('supplementary')),
        int(str(c['number'])[1:]) if c.get('supplementary') else c['number']))
    validate_readings(resolved, modules)
    return resolved


def validate_readings(config: dict, modules: list[dict]) -> None:
    scheduled = {r['number'] for m in modules for r in m['rows'] if r['number'] is not None}
    primary = []
    seen_supplement = False
    supplement_number = 0
    for chapter in config['lectures']:
        numbers = chapter.get('syllabus_numbers', [])
        if chapter.get('supplementary'):
            seen_supplement = True
            supplement_number += 1
            if chapter['number'] != f'S{supplement_number}':
                raise ValueError('Supplementary readings must be numbered S1, S2, and so on.')
            if numbers:
                raise ValueError('Supplementary notes cannot claim a syllabus session.')
        else:
            if seen_supplement or not numbers or not set(numbers) <= scheduled:
                raise ValueError('Readings must follow the syllabus before supplementary notes.')
            primary.append(min(numbers))
            if chapter['number'] not in numbers:
                raise ValueError('Lecture note numbers must match a linked syllabus session.')
    if primary != sorted(primary):
        raise ValueError('Readings are out of syllabus order.')


def render_index(config: dict, modules: list[dict], *, stylesheet_version: str = '') -> str:
    config = resolve_readings(config, modules)
    site = config['site']
    sections = []
    for index, module in enumerate(modules):
        rows = []
        for row in module['rows']:
            number = row['number']
            badge = row.get('badge', '')
            badge_html = (f'<span class="schedule-badge" data-badge="{escape(badge.lower(), quote=True)}">'
                          f'{escape(badge)}</span>') if badge else ''
            if number is None:
                rows.append(f'<tr class="schedule-break"><td class="session-number"></td>'
                            f'<td class="session-date"><time datetime="{row["iso_date"]}">{escape(row["date"])}</time>{badge_html}</td>'
                            f'<td class="break-topic" colspan="2"><strong>{escape(row["title"])}</strong>'
                            f'<span>{escape(row["description"])}</span></td></tr>')
                continue
            notes = [c for c in config['lectures'] if number in c.get('syllabus_numbers', [])]
            links = ''.join(
                (f'<span class="reading-kind">{escape(c["reading_label"])}</span>' if c.get('reading_label') else '') +
                f'<a class="reading-link" href="{Path(c["source"]).stem}.html" '
                f'aria-label="Read notes: {escape(c["short_title"], quote=True)}">HTML</a>'
                f'<a class="pdf-link" href="pdf/{Path(c["source"]).stem}.pdf" '
                f'aria-label="PDF: {escape(c["short_title"], quote=True)}">PDF</a>' for c in notes)
            if not links:
                links = ('<span class="notes-pending">Not yet posted</span>'
                         if number != 0 and module['title'] != 'Project work and presentations' else '')
            rows.append(f'''<tr class="schedule-row">
  <th scope="row" class="session-number">{number:02}</th>
  <td class="session-date"><time datetime="{row['iso_date']}">{escape(row['date'])}</time>{badge_html}</td>
  <td class="session-topic"><h4>{escape(row['title'])}</h4><p>{escape(row['description'])}</p></td>
  <td class="materials-cell"><div class="session-links">{links}</div></td>
</tr>''')
        title = re.sub(r' \(\d+ lectures\)$', '', module['title'])
        if title:
            opening = (f'<section class="schedule-module" aria-labelledby="module-{index}">'
                       f'<h3 id="module-{index}">{escape(title)}</h3>')
            table_label = f'aria-labelledby="module-{index}"'
        else:
            label = escape(module['rows'][0]['title'], quote=True)
            opening = f'<section class="schedule-standalone" aria-label="{label}">'
            table_label = f'aria-label="{label}"'
        sections.append(opening + f'<table class="schedule-table" {table_label}>'
                        '<colgroup><col class="number-column"><col class="date-column">'
                        '<col><col class="materials-column"></colgroup>'
                        '<thead><tr><th scope="col">#</th><th scope="col">Date</th>'
                        '<th scope="col">Topic</th><th scope="col">Notes</th></tr></thead>'
                        f'<tbody>{"".join(rows)}</tbody></table></section>')
    supplementary = ''.join(
        f'<li><a href="{Path(c["source"]).stem}.html">{escape(str(c["number"]))} · {escape(c["short_title"])} <span aria-hidden="true">↗</span></a>'
        f'<a class="pdf-link" href="pdf/{Path(c["source"]).stem}.pdf" '
        f'aria-label="PDF: {escape(c["short_title"], quote=True)}">PDF</a></li>'
        for c in config['lectures'] if c.get('supplementary'))
    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="MIT 6.7980, Fall 2026. Game theory, optimization, and learning in multiagent systems. Course schedule, lecture notes, and syllabus.">
<title>{escape(site['event'])} · {escape(site['title'])} · {escape(site['term'])}</title>
<link rel="stylesheet" href="assets/notes.css">
<link rel="stylesheet" href="assets/course.css{('?v=' + escape(stylesheet_version, quote=True)) if stylesheet_version else ''}">
</head>
<body class="course-home">
<a class="skip-link" href="#main">Skip to content</a>
<header class="course-header home-width">
  <p class="course-term">{escape(site['event'])} · {escape(site['term'])}</p>
  <h1>Topics in Multiagent Learning</h1>
</header>
<main id="main" class="course-layout home-width">
<div class="course-content">
<section id="overview" class="course-overview" aria-label="Course overview">
  <div class="overview-copy">
  <p>This course studies multiagent systems through game theory, optimization, and learning theory. We cover foundational topics such as Nash equilibria, regret minimization, learning dynamics, and extensive-form games.</p>
  <p>We also explore modern topics: multiagent deep reinforcement learning; information and mechanism design; team games and hidden-role games; alignment; high-dimensional and kernelized learning; nonconvex games; calibration; and the complexity of finding equilibria. Applications and open research questions connect the theory to multiagent AI.</p>
  <nav class="course-links" aria-label="Course navigation"><a href="#schedule">Schedule &amp; notes</a><a href="syllabus.pdf">Syllabus (PDF)</a><a href="https://www.mit.edu/~6.7980/fow">Fog of War Challenge <span aria-hidden="true">↗</span></a></nav>
  </div>
  <figure class="course-image">
    <img src="assets/course/course-image-transparent.svg" width="200" height="409" alt="Two phase portraits of learning dynamics in two-player games, showing strategy updates and marked equilibria.">
  </figure>
</section>
<section id="schedule" class="course-schedule" aria-labelledby="schedule-title">
  <h2 id="schedule-title">Schedule &amp; lecture notes</h2>
  {''.join(sections)}
  <section class="supplementary-section" aria-labelledby="supplementary-title"><h3 id="supplementary-title">Supplementary reading</h3><ul class="supplementary-list">{supplementary}</ul></section>
  <section id="improving-material" class="improving-material" aria-labelledby="improving-material-title">
    <h2 id="improving-material-title">Improving Material</h2>
    <p>We would like to make the lecture notes available to as many people as possible. You can now read them in a browser, follow links between sections and references, and move between the notes and their source. We would like everyone's help to make this a useful resource for learners around the world.</p>
    <p>We will divide the class into groups, each focusing on a different part of the material. Using the <a href="https://github.com/gabrfarina/MIT-6.7980-Topics-in-Multiagent-Learning">class GitHub repository</a>, each group can open issues to identify improvements and submit pull requests to implement them. We will improve the material together, reviewing and building on one another's contributions.</p>
    <p>Contributions can include clarifying explanations and proofs, fixing errors, adding examples and homework-style exercises for future readers, and polishing figures, organization, and presentation. If anyone is brave enough, we would also love interactive components that let readers experiment with the ideas.</p>
    <p><em>On the bright side, there is no homework! :-)</em> Improving the shared material accounts for 30% of the course grade.</p>
  </section>
  <section id="project" class="course-project" aria-labelledby="project-title">
    <h2 id="project-title">Project</h2>
    <p>Projects may be completed individually or in groups of 2-5 students and will include a presentation. We will offer three project directions:</p>
    <p id="fog-of-war-challenge"><strong>Fog of War Challenge.</strong> Build and evaluate an agent that plays with partial information. Explore how it uses observations, reasons about uncertainty, and chooses strategic actions. Each bot sandbox is allocated two CPU cores and 4 GiB of memory. A dedicated document will describe the challenge, including the rules, starter code, and how to access the arena.</p>
    <p><strong>Modeling questions.</strong> Formulate a multiagent problem by specifying the players, objectives, information, and available actions. Study how modeling choices affect the resulting strategic behavior. We will provide a separate document with possible modeling questions and leads to explore.</p>
    <p><strong>Theory questions.</strong> Investigate a mathematical question about equilibria, learning dynamics, or computational complexity. Develop rigorous proofs, bounds, or counterexamples that clarify the behavior of multiagent systems. We will provide a separate document with possible theory questions and leads to explore.</p>
    <p>The project is the central component of the course and accounts for 50% of the final grade. We will therefore be &ldquo;robust&rdquo; in our grading: we will look carefully at the depth of your understanding, the quality and substance of your work, and how clearly you explain your results.</p>
  </section>
</section>
</div>
<aside class="course-sidebar" aria-label="Course details and teaching team">
<section class="course-details" aria-labelledby="details-title">
  <h2 id="details-title">Course information</h2>
  <dl><div><dt>Lectures</dt><dd>Tue &amp; Thu<br><span class="lecture-time">11:00 am–12:30 pm</span></dd></div><div><dt>Room</dt><dd>E25-111</dd></div></dl>
</section>
<section id="people" class="course-people" aria-label="Teaching team">
  <h2>Instructors</h2>
  <ul class="instructor-list">
    <li><a class="person-name" href="https://people.csail.mit.edu/costis">Constantinos Daskalakis</a><a href="mailto:costis@csail.mit.edu">costis@csail.mit.edu</a><span>Office 32-G694</span></li>
    <li><a class="person-name" href="https://www.mit.edu/~gfarina">Gabriele Farina</a><a href="mailto:gfarina@mit.edu">gfarina@mit.edu</a><span>Office 45-501F</span></li>
  </ul>
  <p class="office-hours">Meetings by appointment.</p>
  <h2 id="ta-title">Teaching assistants</h2>
  <ul class="ta-list" aria-labelledby="ta-title">
    <li><span class="person-name">Kat Federova</span><a href="mailto:fedorova@mit.edu">fedorova@mit.edu</a></li>
    <li><span class="person-name">Mingyang Liu</span><a href="mailto:liumy19@mit.edu">liumy19@mit.edu</a></li>
    <li><span class="person-name">Daniel Xia</span><a href="mailto:dxia03@mit.edu">dxia03@mit.edu</a></li>
    <li><span class="person-name">Rui Yao</span><a href="mailto:rayyao@mit.edu">rayyao@mit.edu</a></li>
  </ul>
  <p class="office-hours">TA office hours to be announced.</p>
</section>
<section class="course-prerequisites" aria-labelledby="prerequisites-title"><h2 id="prerequisites-title">Prerequisites</h2><p>Advanced undergraduate discrete mathematics and algorithms, and mathematical maturity.</p></section>
<section class="course-work" aria-labelledby="work-title"><h2 id="work-title">Coursework</h2><ul class="grade-components"><li><strong>Attendance and participation 20%</strong></li><li><strong>Improving material 30%</strong></li><li><strong>Project 50%</strong></li></ul><p>There are no assigned homework sets. Students will <a href="#improving-material">improve the shared course materials</a> and complete a theoretical or experimental <a href="#project">project</a> with a presentation. Projects may be individual or in groups of two to five students.</p><p>Attendance at at least 50% of lectures earns the attendance and participation component, assessed on a binary basis using random in-class quizzes.</p><p>Lecture notes are available as HTML and PDF. Announcements and administrative materials are posted on Canvas.</p><p>See the <a href="syllabus.pdf">syllabus</a> for collaboration and AI use policies.</p></section>
</aside>
</main>
<footer class="course-footer home-width"><p>MIT 6.7980 · {escape(site['term'])}</p><a href="#main">Back to top ↑</a></footer>
</body></html>'''


if __name__ == '__main__':
    from hashlib import sha256
    config = json.loads((ROOT / 'html-export.json').read_text())
    modules = read_schedule(ROOT / config['site']['syllabus_source'], config['site']['year'])
    stylesheet = ROOT / 'html/assets/course.css'
    stylesheet.write_bytes((ROOT / 'html-exporter/src/course.css').read_bytes())
    figure_directory = ROOT / 'html/assets/course'
    figure_directory.mkdir(parents=True, exist_ok=True)
    for name, source in COURSE_FIGURES.items():
        (figure_directory / name).write_bytes((ROOT / source).read_bytes())
    version = sha256(stylesheet.read_bytes()).hexdigest()[:12]
    (ROOT / 'html/index.html').write_text(render_index(config, modules, stylesheet_version=version))
    print('Updated html/index.html from the evaluated syllabus schedule.')
