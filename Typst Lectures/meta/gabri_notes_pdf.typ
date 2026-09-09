// Native paged compatibility renderer for active chapters.
// Visual style follows their canonical gabri_notes_bk.typ import.
#import "linalg.typ": *
#import "lovelace.typ": *
#import "notation.typ": *
#import "markers.typ": paragraph-marker

#let lecnum = state("lecnum", none)
#let lecture-number-label(value) = if str(value).starts-with("S") { str(value) } else { "L" + str(value) }
#let lecture-label(value) = if str(value).starts-with("S") { "Supplementary reading " + str(value) } else { "Lecture " + str(value) }
#let sf = text.with(font: "Frutiger")
#let eps = math.epsilon.alt
#let BB = $𝔹$
#let CC = $ℂ$
#let NN = $ℕ$
#let QQ = $ℚ$
#let RR = $ℝ$
#let EE = math.op($𝔼$, limits: true)
#let cK = $cal(K)$
#let cS = $cal(S)$
#let PPAD = text(font: "Frutiger", "PPAD")
#let NP = text(font: "Frutiger", "NP")
#let coNP = text(font: "Frutiger", "co-NP")
#let P = text(font: "Frutiger", "P")
#let argmin = math.op("arg min", limits: true)
#let argmax = math.op("arg max", limits: true)
#let html-math-color(fill, body) = text(fill: fill, body)
#let ip(a, b) = $lr(chevron.l #a, #b chevron.r)$
#let div(a, b, dgf: $phi$) = $op("D") _#dgf (#a mid(||) #b)$
#let divt(a, b) = $op("D") _(phi_t) (#a mid(||) #b)$
#let dom = math.op("dom")
#let diag = math.op("diag")
#let cone = math.op("cone")
#let span = math.op("span")
#let colspan = math.op("colspan")
#let qquad = $quad quad$
#let proofdir(marker, body) = [#marker~~#body]
#let bpar(body) = [#strong(body) #h(0.5em)]
#let changelog(body) = block(above: 1.2em, stroke: (top: 0.15mm + luma(80%)), inset: (top: 8pt))[
  #text(font: "Frutiger", size: 9pt, fill: luma(40%))[Changelog]
  #v(0.4em)
  #text(size: 9pt, body)
]
#let citep(..keys) = {
  let keys = keys.pos()
  if keys.len() == 2 and type(keys.last()) == content {
    cite(keys.first(), supplement: keys.last())
  } else {
    for key in keys { cite(key) }
  }
}
#let citet = cite.with(form: "prose")
#let lec_bibliography(path, title: auto) = bibliography(path, title: title)

#let plain-text(value) = if type(value) == str {
  value
} else if value.func() in (linebreak, parbreak, [ ].func()) {
  " "
} else if value.has("text") {
  value.text
} else if value.has("children") {
  value.children.map(plain-text).join("")
} else if value.has("body") {
  plain-text(value.body)
} else {
  ""
}

#let gabri_notes(
  body, lec_num: none, date: none, title: none,
  instructor: [Prof. Gabriele Farina], show_outline: false, extrathanks: none,
) = {
  set document(title: lecture-label(lec_num) + ": " + plain-text(title), author: plain-text(instructor))
  set page(width: 8.27in, height: 11.69in,
    margin: (x: 1.3in, top: 1.6in, bottom: 1.6in),
    numbering: "1", number-align: center)
  set text(font: "New Computer Modern", size: 10.2pt)
  set par(justify: true)
  show par: set block(above: 4mm)
  set list(indent: 4.05mm)
  set enum(indent: 4.05mm)
  set heading(numbering: (..nums) => lecture-number-label(lec_num) + "." + nums.pos().map(str).join("."))
  set math.equation(supplement: none)
  set cite(style: "alphanum.csl")
  show cite: set text(fill: blue.darken(40%))
  show strong: set text(font: "Frutiger", weight: "bold")
  show heading: it => {
    if it.numbering != none {
      v(5mm)
      [#h(-.4in)#box(width: .3in, fill: gray, height: 2mm)#h(.1in)#box(width: .6in)[#strong(counter(heading).display())]#strong(it.body)]
    } else {
      [#h(-.4in)#box(width: .3in, fill: gray, height: 2mm)#h(.1in)#strong(it.body)]
    }
    v(0mm)
  }
  show figure.caption: caption => context pad(left: 2em, right: 1em,
    align(left)[#h(-1em)*#caption.supplement #numbering(caption.numbering, ..caption.counter.get())*#caption.separator#caption.body])
  show figure.where(kind: "lecture-environment"): it => it.body
  lecnum.update(str(lec_num))
  box(stroke: .5pt, inset: 3mm, width: 100%, radius: 0mm)[
    #place(top + left)[MIT 6.7980 --- Topics in Multiagent Learning]
    #place(top + right)[#date]
    #v(12mm)
    #align(center)[#text(size: 16pt)[#strong[#lecture-label(lec_num)#v(0mm)*#title*]]]
    #v(5mm)
    Instructor: #instructor
    #if extrathanks != none { footnote(extrathanks) }
  ]
  v(1cm)
  if show_outline { outline() }
  body
}

#let appendix(body) = context {
  counter(heading).update(0)
  let number = lecture-number-label(lecnum.get())
  set heading(numbering: (..nums) => number + "." + numbering("A.1", ..nums))
  body
}

#let environment(name) = (..args, body) => figure(
  kind: "lecture-environment", supplement: name, outlined: false, caption: none,
  numbering: n => context [#lecture-number-label(lecnum.get()).#n],
  block(width: 100%, fill: luma(95%), stroke: .15mm + luma(80%),
    inset: 3mm, radius: .65mm, breakable: true, align(left)[
    #context {
      strong([#name #lecture-number-label(lecnum.get()).#counter(figure.where(kind: "lecture-environment")).get().first()])
      if args.pos().len() > 0 { [ (#args.pos().first())] }
      strong[.]
    }
    #h(0.2em)#body
  ]))
#let theorem = environment("Theorem")
#let corollary = environment("Corollary")
#let definition = environment("Definition")
#let example = environment("Example")
#let remark = environment("Remark")
#let claim = environment("Claim")
#let subclaim = environment("Subclaim")
#let lemma = environment("Lemma")
#let exercise = environment("Exercise")
#let open-problem = environment("Open Problem")
#let proof-environment(name) = (..args, body) => block(
  width: 100%, stroke: (left: .3mm + luma(60%), right: none),
  inset: (left: 4mm, y: 1mm), breakable: true)[
  #emph[#name#if args.pos().len() > 0 { [ #args.pos().first()] }.]
  #h(0.2em)#body #h(1fr) $square$
]
#let proof = proof-environment("Proof")
#let proofsketch = proof-environment("Proof Sketch")
#let solution = proof-environment("Solution")

#let wrapped-figure(text-body, figure-body, side: right, text-width: 65%) = {
  let figure-width = (1 - text-width / 100%) * 1fr
  let text-width = text-width / 100% * 1fr
  let figure-body = {
    show image: it => if it.width == 100% { it } else {
      let options = it.fields()
      let source = options.remove("source")
      options.insert("width", 100%)
      image(source, ..options)
    }
    align(center, figure-body)
  }
  if side == left {
    grid(columns: (figure-width, text-width), column-gutter: 12pt, figure-body, text-body)
  } else {
    grid(columns: (text-width, figure-width), column-gutter: 12pt, text-body, figure-body)
  }
}
#let wrapped-figure-with-caption(text-body, figure-body, caption, side: right, text-width: 65%) = {
  wrapped-figure(text-body, figure(figure-body, caption: caption), side: side, text-width: text-width)
}
