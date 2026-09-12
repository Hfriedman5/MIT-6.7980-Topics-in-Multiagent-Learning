// Bundle references use Typst's live labels, counters, and link destinations.
// A single-file preview cannot introspect another document; it uses that
// note's exported header for a lecture-level web link instead.
#let lecture-title(number, title) = {
  let kind = if str(number).starts-with("S") { "Supplementary Reading" } else { "Lecture" }
  [#kind~#number, “#title”]
}

#let lecture-link(note, destination, body) = context {
  assert(note.match(regex("^[a-z][a-z0-9_]*$")) != none,
    message: "Expected a lecture source basename (without .typ).")
  assert(destination == none or type(destination) == label,
    message: "Expected a stable destination label, or none for the whole lecture.")
  let anchor = if destination == none { none } else { str(destination) }
  assert(anchor == none or anchor.match(regex("^[a-zA-Z][a-zA-Z0-9_-]*$")) != none,
    message: "Cross-lecture labels must use letters, digits, hyphens or underscores.")
  if "course-bundle" in sys.inputs {
    let (dest, reference) = if destination == none {
      let path = if target() == "html" { "/" + note + ".html" } else { "/pdf/" + note + ".pdf" }
      let doc = query(document.where(path: path)).first()
      (doc.location(), doc.title)
    } else {
      let reference = {
        // The outer link covers the phrase and its reference together.
        show link: it => it.body
        ref(destination)
      }
      (destination, reference)
    }
    let body = if body == [] { reference } else { [#body (#reference)] }
    link(dest, if target() == "html" { body } else { text(fill: blue.darken(40%), body) })
  } else {
    import ("../" + note + ".typ") as chapter
    let other = chapter.lecture
    let reference = lecture-title(other.lec_num, other.title)
    let body = if body == [] { reference } else { [#body (#reference)] }
    let relative = note + ".html" + if anchor == none { "" } else { "#" + anchor }
    if target() == "html" {
      link(relative, body)
    } else {
      let base = sys.inputs.at("course-url", default: "https://www.mit.edu/~6.7980/")
      link(base + relative, text(fill: blue.darken(40%), body))
    }
  }
}
