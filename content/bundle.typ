// Compile all notes together so native refs can see their live destinations.
// Separate HTML and PDF bundles avoid duplicating each label across formats.
#let format = sys.inputs.at("notes-format", default: "pdf")
#assert(format in ("html", "pdf"), message: "Expected notes-format=html or pdf.")
#import "meta/lecture-links.typ": lecture-title
#for note in json("../.build/html-export.json").notes {
  let name = note.source.split("/").last().trim(".typ", at: end)
  let output = if format == "html" { name + ".html" } else { "pdf/" + name + ".pdf" }
  let source = "../.build/" + format + "-source/" + name + ".typ"
  import source as chapter
  let header = chapter.lecture
  document(output, title: lecture-title(header.lec_num, header.title), include source)
}
