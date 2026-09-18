# Course materials

Reflect every user-requested course change in both the current index page and the syllabus PDF in the same update.

- The editable syllabus and schedule are in `syllabus/6.7980 F26 Syllabus.typ`.
- Generate the current `html/index.html` with `scripts/course_index.py` and `html-export.json`.
- Rebuild `syllabus/6.7980 Fall 2026 Syllabus.pdf` and synchronize the copy at `html/syllabus.pdf`, which is linked from the index page.
- Edit shared facts in the syllabus's `course` dictionary and prose in its `item(...)` / `course-text(...)` blocks. The index reads these via `scripts/course_data.py`; do not duplicate course text in Python.
- `html-export.json` uses `notes` with stable `syllabus_ids` and a separate `slides` map keyed by lecture ID. Numbers, dates, course facts, and citation metadata are generated in `.build/html-export.json`; do not author redundant numbers or dates. Use `scripts/public_files.py` for export paths and validation shared with deployment.
- Verify schedule consistency and visually check the rebuilt PDF after changes.
- Reorder the syllabus's date-free `lecture(...)`, `no-class(...)`, and `module[...]` outline. `schedule(class-dates, outline)` assigns dates and lecture numbers; verified class dates and fixed academic-calendar exceptions are in `syllabus/fall-2026-calendar.typ`. Keep stable lecture IDs with their topics and map notes through `syllabus_ids` in `html-export.json`.
- Use Frutiger only for bold text and headings in the syllabus PDF. Use New Computer Modern for regular and italic body text. Do not use PT Sans, and check the embedded fonts when changing typography.
- Load the bundled regular and bold Frutiger faces with `--font-path html-exporter/assets/fonts` when compiling the syllabus. `make syllabus` rebuilds and synchronizes both PDF copies with this setting; the full site build uses it too.

# FoW backend address privacy

- Never hardcode the backend URL or its real hostname in the FoW frontend, public documentation, example links, or downloadable assets. Do not disclose the student-code execution host through the public course site.
- Supply the backend address at runtime through an instructor-provided arena link or explicit connection settings. Keep real deployment addresses in private deployment configuration, outside public source and assets.
- Build-time environment variables that embed an address in the published JavaScript do not satisfy this rule. Check the final static deployment payload for backend hostnames before publishing.
