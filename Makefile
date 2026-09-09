PYTHON ?= python3

.PHONY: all html bundle syllabus check serve

all: bundle

html:
	$(PYTHON) scripts/build_site.py

bundle:
	$(PYTHON) scripts/build_site.py --zip

syllabus:
	typst compile --root . --font-path html-exporter/assets/fonts 'Syllabus/6.7980 F26 Syllabus.typ' 'Syllabus/6.7980 Fall 2026 Syllabus.pdf'
	mkdir -p html
	cp 'Syllabus/6.7980 Fall 2026 Syllabus.pdf' html/syllabus.pdf

check:
	$(PYTHON) -m unittest discover -s scripts -p 'test_*.py'
	cargo test --locked --manifest-path html-exporter/Cargo.toml
	$(PYTHON) scripts/check_site.py html
	node scripts/check_katex.cjs html

serve:
	$(PYTHON) -m http.server 8798 --bind 127.0.0.1 --directory html
