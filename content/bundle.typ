// Assemble the HTML postprocessor's output with Typst 0.15's native bundle
// assets. Keeping chapter compilation separate preserves chapter-local labels,
// counters and bibliography state. `make bundle` also creates a ZIP archive.
#for file in json("../.build/bundle-files.json") {
  asset(file.output, read("../" + file.source, encoding: none))
}
