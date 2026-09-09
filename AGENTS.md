# Course materials

Reflect every user-requested course change in both the current index page and the syllabus PDF in the same update.

- The editable syllabus and schedule are in `Syllabus/6.7980 F26 Syllabus.typ`.
- Generate the current `html/index.html` with `scripts/course_index.py` and `html-export.json`.
- Rebuild `Syllabus/6.7980 Fall 2026 Syllabus.pdf` and synchronize the copy at `html/syllabus.pdf`, which is linked from the index page.
- Keep course descriptions, logistics, and instructor information aligned between the index generator and the syllabus when changing those details.
- Verify schedule consistency and visually check the rebuilt PDF after changes.
- Use Frutiger only for bold text and headings in the syllabus PDF. Use New Computer Modern for regular and italic body text. Do not use PT Sans, and check the embedded fonts when changing typography.
- Load the bundled regular and bold Frutiger faces with `--font-path html-exporter/assets/fonts` when compiling the syllabus. `make syllabus` rebuilds and synchronizes both PDF copies with this setting; the full site build uses it too.
