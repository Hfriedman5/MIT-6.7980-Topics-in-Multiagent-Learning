#import "@preview/cetz:0.4.1"

#let sans(body) = { text(weight: "bold", font: "PT Sans")[#body] }

#let item(body, title: "") = {
  set par(hanging-indent: 1cm)
  set list(indent: 1cm)
  strong(title + ":")
  sym.space
  body
}

#let dt(s) = {
  (
    [#s]
      + if s.last() == "1" and (not s.ends-with(" 1") and not s.ends-with("11")) {
        [#super[st]]
      } else if s.last() == "2" and not s.ends-with("12") {
        [#super[nd]]
      } else if s.last() == "3" and not s.ends-with("13") {
        [#super[rd]]
      } else {
        [#super[th]]
      }
  )
}

#let mybox(body, bg: black, fg: white) = {
  box(baseline: 1mm, inset: 1mm, fill: bg, radius: 1mm)[#text(
    weight: "semibold",
    fill: fg,
    font: "PT Sans",
    size: 9pt,
  )[#upper[#body]]]
};
#let math = {} // mybox(bg: blue)[math]}
#let complexity = mybox(bg: green)[complexity]
#let exam = { mybox(bg: red)[EXAM] }
#let examOut = { mybox(bg: red)[EXAM OUT] }
#let examDue = { mybox(bg: red)[EXAM DUE] }
#let proj = mybox(bg: blue)[project]
#let projP = mybox(bg: purple)[project]
#let brk = { mybox(bg: luma(60%))[holiday] }
#let rev = { mybox(bg: luma(40%))[review] }
#let hwout(n) = { mybox(bg: orange)[HW#n out] }
#let hwdue(n) = {}//{mybox(bg:purple)[HW#n due]}
#let email(addr) = {
  let w = .3
  let h = .2
  box(
    cetz.canvas({
      import cetz.draw: *
      rect((0, 0), (w, h), stroke: .2mm)
      line((0, h), (w / 2, h / 2.5), (w, h), stroke: .2mm)
    }),
  )
  [~]
  raw(addr)
}

#let part(title, spacing: 3mm) = {
  table.cell(colspan: 2)[#v(spacing)#show: smallcaps;#title]
}
