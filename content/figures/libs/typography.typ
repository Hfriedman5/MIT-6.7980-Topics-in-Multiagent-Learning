// SVG text is outlined at compilation, so HTML figures need the page's fonts.
#let figure-html = sys.inputs.at("figure-format", default: "pdf") == "html"
#let figure-font = if figure-html { "Georgia" } else { "New Computer Modern" }

#let figure-style(body) = {
  if figure-html {
    show strong: set text(font: "Frutiger", weight: "bold")
    body
  } else {
    body
  }
}
