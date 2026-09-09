// Decorative paragraph markers use explicit geometry in both output formats,
// so font fallback and math rendering cannot enlarge them relative to prose.
#let paragraph-marker(shape: "square") = context {
  assert(shape in ("square", "triangle-right", "triangle-up"))
  if target() == "html" {
    html.elem("span", attrs: (
      class: "paragraph-marker paragraph-marker-" + shape,
      "aria-hidden": "true",
    ))[]
  } else {
    box(baseline: 0.04em, {
      if shape == "square" {
        square(size: 0.5em, fill: text.fill, stroke: none)
      } else if shape == "triangle-right" {
        polygon(fill: text.fill, stroke: none,
          (0em, 0em), (0.5em, 0.275em), (0em, 0.55em))
      } else {
        polygon(fill: text.fill, stroke: none,
          (0em, 0.5em), (0.275em, 0em), (0.55em, 0.5em))
      }
    })
  }
}
