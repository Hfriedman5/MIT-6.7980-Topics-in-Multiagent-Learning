#import "@preview/cetz:0.2.2"
#import "boxes.typ": *
// #import "@preview/ctheorems:1.1.0": *
#import "theorems.typ": *
#import "linalg.typ": *
#import "lovelace.typ": *

#let pseudocode-list = pseudocode-list.with(
  indentation: 1.10em,
  line-gap: 1.00em,
  hooks: .3mm,
  stroke: .2mm + gray,
  booktabs-stroke: .4mm + black,
)

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
  link("mailto:" + addr, raw(addr))
}
#let sf = text.with(font: "New Computer Modern Sans 08")

#let swallow = it => place(hide(it))

#let gabri_notes(body, lec_num: none, date: none, title: none, show_outline: false, extrathanks: none) = {
  set text(font: "New Computer Modern", size: 9.5pt)
  // set text(size: 9.5pt)
  set par(justify: true)
  show par: set block(above: 4mm)
  set list(indent: 4.05mm)
  set enum(indent: 4.05mm)
  let is_web = sys.inputs.at("web", default: "false") == "true"
  set page(
    margin: if is_web {
      1mm
    } else {
      (x: 1.2in, top: 1.1in, bottom: 1in)
    },
    numbering: if is_web {
      none
    } else {
      "1"
    },
    width: if is_web {
      5.8in
    } else {
      8.5in
    },
    height: if is_web {
      auto
    } else {
      11in
    },
  )
  // set page(margin: 1mm, numbering: none, width: 5.8in, height: auto)
  // set text(font: "PT Sans")
  set heading(numbering: "1.1  ")
  set cite(style: "alphanum.csl")
  set math.equation(supplement: none)
  show cite: set text(fill: blue.darken(40%))
  show strong: set text(font: "New Computer Modern Sans", weight: "bold")
  // show strong: set text(font: "Frutiger", weight: "bold")
  // show heading: set text(font: "New Computer Modern Sans", weight: "bold")
  show heading: it => {
    // if it.level == 1 {
    //   v(8mm)
    //   grid(
    //     columns: (30%, 70%),
    //     align: top,
    //     box(baseline: .6mm, line(length: 100%, stroke: black + 1.8mm)), line(length: 100%, stroke: black + .6mm),
    //   )
    // }
    v(1mm)
    // text(font: "New Computer Modern Sans", weight: "bold", it)
    strong(it)
    v(1mm)
  }
  show: thmrules
  show link: it => {
    if it.body.func() != raw and it.body.has("text") and (
      it.body.text.starts-with("http://") or it.body.text.starts-with("https://") or it.body.text.match(
        regex("^10.\d{4,9}/[-._;()/:a-zA-Z0-9]+$"),
      ) != none
    ) {
      link(it.dest, raw(it.body.text))
    } else {
      it
    }
  }
  show "i.e.": emph
  show "e.g.": emph

  swallow[#text[Lecture #lec_num: #title]<lecture>]
  box(
    stroke: .5pt,
    inset: 3mm,
    width: 100%,
    radius: 0mm,
  )[
    #show strong: set text(font: "New Computer Modern Sans", weight: "bold")
    #place(top + left)[MIT 6.S890 --- Topics in Multiagent Learning]
    #place(top + right)[#date]
    #v(12mm)
    #align(center)[#text(size: 16pt)[#strong[Lecture #lec_num#v(0mm)*#title*]]]
    #v(5mm)
    Instructor: Prof. Gabriele Farina (#email("gfarina@mit.edu"))#footnote(
      numbering: (_)=>sym.star.filled,
    )[These notes are class material that has not undergone formal peer review. The
      TA and I are grateful for any reports of typos. #extrathanks]
    #counter(footnote).update(0)
  ]

  if show_outline {
    outline(fill: repeat([~.~]))
    line(length: 100%)
    v(1cm)
  } else {
    v(8mm)
  }
  body
}

#let citet = cite.with(form: "prose")
#let citep = cite

#let lec_bibliography = bibliography
// #let lec_bibliography = (path, title:none) => {}

#let appendix = body => {
  counter(heading).update(0)
  set heading(numbering: "A.1")
  body
}
#let brown = rgb(149, 69, 53)
#let comment(body) = text(
  luma(50%),
  size: 10pt,
)[[#box(baseline: -.35mm, text(size: 8pt, $triangle.r$)) #body]]
#let todo(body) = highlight(fill: red.lighten(50%), body)
#let theorem = thmbox(
  "theorem",
  "Theorem",
  base: "heading",
  titlefmt: text.with(font: "New Computer Modern Sans", weight: "bold"),
  base_level: 1,
  fill: luma(94%),
  inset: 3mm,
  radius: 1.5mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let open-problem = thmbox(
  "open-problem",
  "Open Problem",
  base: "heading",
  titlefmt: text.with(font: "New Computer Modern Sans", weight: "bold"),
  base_level: 1,
  fill: luma(94%),
  inset: 3mm,
  radius: 1.5mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let corollary = thmbox(
  "corollary",
  "Corollary",
  base: "heading",
  titlefmt: text.with(font: "New Computer Modern Sans", weight: "bold"),
  base_level: 1,
  fill: luma(94%),
  inset: 3mm,
  radius: 1.5mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let definition = thmbox(
  "definition",
  "Definition",
  base: "heading",
  titlefmt: text.with(font: "New Computer Modern Sans", weight: "bold"),
  base_level: 1,
  fill: luma(94%),
  inset: 3mm,
  radius: 1.5mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let example = thmbox(
  "example",
  "Example",
  base: "heading",
  titlefmt: text.with(font: "New Computer Modern Sans", weight: "bold"),
  base_level: 1,
  fill: luma(94%),
  inset: 3mm,
  radius: 1.5mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let remark = thmbox(
  "remark",
  "Remark",
  base: "heading",
  titlefmt: text.with(font: "New Computer Modern Sans", weight: "bold"),
  base_level: 1,
  fill: luma(94%),
  inset: 3mm,
  radius: 1.5mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let proof = thmbox(
  "proof",
  [Proof],
  titlefmt: emph,
  separator: [#h(0.1em).#h(2mm)],
  base: "heading",
  stroke: (left: .3mm + luma(60%), right: none),
  radius: 0mm,
  inset: (left: 4mm, y: 1mm),
  padding: none,
  bodyfmt: body => [#body #h(1fr) $square$],
  breakable: true,
).with(numbering: none)
#let solution = thmbox(
  "solution",
  [Solution],
  titlefmt: emph,
  separator: [#h(0.1em).#h(2mm)],
  base: "heading",
  stroke: (left: .3mm + luma(60%), right: none),
  radius: 0mm,
  inset: (left: 4mm, y: 1mm),
  padding: none,
  bodyfmt: body => [#body #h(1fr) $square$],
  breakable: true,
).with(numbering: none)

#let argmin = math.op($arg#h(1mm)min$, limits: true)
#let argmax = math.op($arg#h(1mm)max$, limits: true)

#let dt(s) = {
  [#s] + if s.last() == "1" and (not s.ends-with(" 1") and not s.ends-with("11")) {
    [#super[st]]
  } else if s.last() == "2" and not s.ends-with("12") {
    [#super[nd]]
  } else if s.last() == "3" and not s.ends-with("13") {
    [#super[rd]]
  } else {
    [#super[th]]
  }
}

#let changelog(body) = [
  #v(1cm)
  #line(length: 100%, stroke: gray)
  #set text(luma(40%))
  *Changelog*
  #set text(8pt, font: "Menlo")
  #body
]

#let manualcite(..lbls) = {
  let rows = ()
  for lbl in lbls.pos() {
    rows.push(cite(lbl))
    rows.push(cite(lbl, form: "full"))
  }
  grid(columns: (1cm, auto), row-gutter: 3.8mm, column-gutter: 2.3mm, ..rows)
}

#let proofdir(marker, body) = list(indent: 0mm, marker: marker, block(width: 100%, breakable: true, body))

// Math notation
#let boxeq(inset: 2mm, bl: 2mm, body, punct: "") = (
  $
    #box(
  baseline: bl,
  stroke: .2mm,
  inset: ("y": inset, "x": 2mm),
  $display(#body)$,

)" "#punct
  $
)
#let qquad = $quad quad$
#let nor(pt, domain: $Omega$) = $cal(N)_(#h(-.2em)domain)(pt)$
#let span = $op("span")$
#let colspan = $op("colspan")$
#let ip(a, b) = $lr(angle.l #a, #b angle.r)$
#let infconv = math.op(
  box(
    baseline: .8mm,
    text(size: 7.5pt, stack(dir: ttb, $+$, v(-.4mm) + sym.or)),
  ),
)
#let opt(dir, var, obj, ..constraints) = {
  // assert(dir == math.min or dir == math.max)
  let data = (($limits(dir)_(var)$, $&obj$),)
  for (i, cntnt) in constraints.pos().enumerate(start: 0) {
    if i == 0 {
      data.push(("s.t.", $&$ + cntnt))
    } else {
      data.push(("", $&$ + cntnt))
    }
  }
  math.mat(delim: none, ..data)
}
#let P = text(font: "New Computer Modern Sans", "P")
#let PPAD = text(font: "New Computer Modern Sans", "PPAD")
#let NP = text(font: "New Computer Modern Sans", "NP")
#let coNP = text(font: "New Computer Modern Sans", "co-NP")
#let cone = math.op("cone")
#let cK = math.cal("K")
#let nablat = math.op($tilde(nabla)#h(-1mm)$)
#let div(a, b, dgf: $phi$) = $#text(font: "New Computer Modern", "D")_#dgf (#a mid(||) #b)$
#let divt(a, b) = $#text(font: "New Computer Modern", "D")_(phi_t) (#a mid(||) #b)$
#let circled(body) = box(
  baseline: .6mm,
  circle(
    radius: 1.6mm,
    stroke: .2mm,
    inset: .3mm,
    text(size: 7pt, font: "New Computer Modern Sans 08", body),
  ),
)
#let dom = math.op("dom")
#let diag = math.op("diag")
// [#math.cal("N")#h(-.8mm)#math.cal("P")]
// #let coNP = [co-#NP]
