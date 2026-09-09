#import "@preview/cetz:0.2.2"
#import "boxes.typ": *
// #import "@preview/ctheorems:1.1.0": *
#import "theorems_bk.typ": *
#import "linalg.typ": *
#import "markers.typ": paragraph-marker
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

#let bpar(body) = {
  [#paragraph-marker() #strong(body + ".")~~]
}
#let sf = text.with(font: "Frutiger")
#let swallow = it => place(hide(it))
#let lecture-bib = state("lecture-bib", ())
#let lecnum = counter("lecnum")

#let lecture_outline = lec_num => {
  locate(loc => {
    for elem in query(heading, loc) {
      if elem.at("numbering") != none {
        let numbering-fn = elem.at("numbering")
        let numbers = counter(heading).at(elem.location())
        let numbering = numbering(numbering-fn, ..numbers)
        let space = "    " * (numbers.len() - 1)
        if numbering.starts-with("L" + str(lec_num) + ".") {
          [#link(elem.location(), space + numbering + "   " + elem.body) #box(
              width: 1fr,
              repeat[~.~],
            )#h(3mm)#box[#align(right)[#elem.location().page()]]] + linebreak()
        }
      }
    }
  })
}

#let gabri_notes(body, lec_num: none, date: none, title: none, show_outline: false, extrathanks: none) = {
  lecture-bib.update(())
  counter(heading).update(0)
  set text(font: "New Computer Modern", size: 10.2pt)
  // set text(font: "Times New Roman", size: 10.2pt)
  set par(justify: true)
  show par: set block(above: 4mm)
  set list(indent: 4.05mm)
  set enum(indent: 4.05mm)
  show figure.caption: body => (
    context pad(
      left: 2em,
      right: 1em,
      align(left)[
        #h(-1em)*#body.supplement #numbering(body.numbering, ..body.counter.get())*#body.separator#body.body
        // #repr(body.fields())
      ],
    )
  )
  let is_web = sys.inputs.at("web", default: "false") == "true"
  set page(
    margin: if is_web {
      1mm
    } else {
      // (left: 1.25in, right: 1.25in, top: 1.3in, bottom: 1.3in)
      (left: 1.3in, right: 1.3in, top: 1.6in, bottom: 1.6in)
      // (left: 1.35in, right: 1.35in, top: 1.6in, bottom: 1.6in)

    },
    numbering: if is_web {
      none
    } else {
      "1"
    },
    width: if is_web {
      8.27in - 1.3in - 1.3in
    } else {
      8.27in
    },
    height: if is_web {
      auto
    } else {
      11.69in
    },
  )

  // set page(
  //   // margin: (left: 1.5in, right: 1.15in, top: 2in, bottom: 2in),
  //   // margin: (left: 1.15in, right: 1.15in, top: 1.75in, bottom: 1.75in),
  //   margin: (left: 1.25in, right: 1.25in, top: 1.3in, bottom: 1.3in),
  //   numbering: "1",
  //   paper: "a4",
  //   // header: context {
  //   //   h(-.6in)
  //   //   if calc.rem(counter(page).get().at(0), 2) == 1 {
  //   //     h(1fr)
  //   //   }
  //   //   sf[#numbering("1", ..counter(page).get())]
  //   // },
  // )
  // set page(margin: 1mm, numbering: none, width: 5.8in, height: auto)
  // set text(font: "PT Sans")
  // set heading(numbering: "1.1  ")
  set cite(style: "alphanum.csl")
  set math.equation(supplement: none)
  show cite: set text(fill: blue.darken(40%))
  show strong: set text(font: "Frutiger", weight: "bold")
  show heading: it => {
    // if it.level == 1 {
    //   v(8mm)
    //   grid(
    //     columns: (30%, 70%),
    //     align: top,
    //     box(baseline: .6mm, line(length: 100%, stroke: black + 1.8mm)), line(length: 100%, stroke: black + .6mm),
    //   )
    // }
    if it.numbering != none {
      // v(1.5mm * (2 / it.level))
      v(5mm)
      [#h(-.4in)#box(width: .3in, fill: gray, height: 2mm)#h(.1in)#box(width: .6in, inset: 0mm, stroke: none)[#strong(
            counter(heading).display(),
          )]#strong(it.body)]
      // v(1.5mm - it.level * 1mm)
    } else [
      // v(2mm * (2 / it.level))
      #h(-.4in)#box(width: .3in, fill: gray, height: 2mm)#h(.1in)#strong(it.body)
      // v(1mm)
    ]
    v(0mm)
  }
  show: thmrules
  show "https://doi.org/": text(10pt, `https://doi.org/`)
  show link: it => {
    if it.body.func() != raw and it.body.has("text") and (
      it.body.text.starts-with("http://") or it.body.text.starts-with("https://") or it.body.text.match(
        regex("^10.\d{4,9}/[-._;()/:a-zA-Z0-9]+$"),
      ) != none
    ) {
      link(it.dest, text(10pt, raw(it.body.text)))
    } else {
      // it.fields()
      it
    }
  }
  show "i.e.": emph
  show "e.g.": emph
  set heading(numbering: (..nums) => {
    "L" + str(lec_num) + "." + nums.pos().map(str).join(".")
  })

  thmcounters.update(x => {
    x.at("counters").at("lecture") = str(lec_num)
    x.at("counters").at("heading") = (1,)
    x.at("latest") = (1,)
    x
  })

  lecnum.update(lec_num)
  swallow[#text[#lec_num #title]<lecture>]
  if sys.inputs.at("combined", default: "false") == "true" {
    v(1cm)
    box(stroke: (bottom: 1.5mm + gray), inset: (y: 4mm))[
      #text(size: 16pt)[#strong[Lecture #lec_num]]#v(2mm)
      #text(size: 18pt)[*#title*]
    ]
    // v(3cm)
    v(1.9cm)
  } else {
    box(
      stroke: .5pt,
      inset: 3mm,
      width: 100%,
      radius: 0mm,
    )[
      #place(top + left)[MIT 6.S890 --- Topics in Multiagent Learning]
      #place(top + right)[#date]
      #v(12mm)
      #align(center)[#text(size: 16pt)[#strong[Lecture #lec_num#v(0mm)*#title*]]]
      #v(5mm)
      Instructor: Prof. Gabriele Farina (#email("gfarina@mit.edu"))#footnote(
        numbering: (_)=>sym.star.filled,
      )[These notes are class material that has not undergone formal peer review. The
        TAs and I are grateful for any reports of typos.]
      #counter(footnote).update(0)
    ]
    v(1cm)
  }

  // if show_outline {
  //   // outline(fill: repeat([~.~]))
  //   v(3mm)
  //   lecture_outline(lec_num)
  //   line(length: 100%, stroke: gray)
  //   v(1.2cm)
  // } else {
  // }
  body
}

#let citep(key) = {
  text(fill: blue.darken(40%), cite(key))
  lecture-bib.update(it => {
    if key not in it {
      it.push(key)
    }
    it
  })
}
#let citet(key, ..supplement) = {
  text(fill: blue.darken(40%), cite(key, form: "prose", ..supplement))
  lecture-bib.update(it => {
    if key not in it {
      it.push(key)
    }
    it
  })
}

#let changelog(body) = [
  // #v(1cm)
  // #line(length: 100%, stroke: gray)
  // #set text(luma(40%))
  // *Changelog*
  // #set text(8pt, font: "Menlo")
  // #body
]

#let lec_bibliography = (path, title: auto) => {
  show cite: set text(black)
  set heading(numbering: none)
  v(3mm)
  if title != none and title != auto {
    [= #title]
    v(2mm)
  } else if title == auto {
    [= Bibliography for this lecture]
    v(2mm)
  }
  let cnt = locate(loc => {
    let rows = ()
    for item in lecture-bib.at(loc) {
      rows.push(cite(item))
      rows.push(cite(item, form: "full"))
    }
    grid(columns: 2, row-gutter: 3.8mm, column-gutter: 2.3mm, ..rows)
  })
  // [
  //   // #show cite: set text(fill: red)
  //   #cnt
  // ]
  cnt

  if sys.inputs.at("combined", default: "false") == "false" {
    swallow[#bibliography("refs.bib", title: none)]
  }
}

#let appendix(body) = (
  context {
    counter(heading).update(0)
    let lec_num = str(lecnum.get().at(0))
    set heading(numbering: (..nums) => {
      "L" + lec_num + "." + numbering("A.1", ..nums)
    })
    body
  }
)
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
  base_level: 0,
  fill: luma(95%),
  stroke: .15mm + luma(80%),
  inset: 3mm,
  radius: 0.65mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let corollary = thmbox(
  "corollary",
  "Corollary",
  base: "heading",
  base_level: 0,
  fill: luma(95%),
  stroke: .15mm + luma(80%),
  inset: 3mm,
  radius: 0.65mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let definition = thmbox(
  "definition",
  "Definition",
  base: "heading",
  base_level: 0,
  fill: luma(95%),
  stroke: .15mm + luma(80%),
  inset: 3mm,
  radius: 0.65mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let example = thmbox(
  "example",
  "Example",
  base: "heading",
  base_level: 0,
  fill: luma(95%),
  stroke: .15mm + luma(80%),
  inset: 3mm,
  radius: 0.65mm,
  padding: none,
  separator: [.#h(1mm)],
  breakable: true,
)
#let remark = thmbox(
  "remark",
  "Remark",
  base: "heading",
  base_level: 0,
  fill: luma(95%),
  stroke: .15mm + luma(80%),
  inset: 3mm,
  radius: 0.65mm,
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

#let manualcite(..lbls) = {
  let rows = ()
  for lbl in lbls.pos() {
    rows.push(cite(lbl))
    rows.push(cite(lbl, form: "full"))
  }
  grid(columns: (1cm, auto), row-gutter: 3.8mm, column-gutter: 2.3mm, ..rows)
}

// #let proofdir(marker, body) = list(indent: 0mm, marker: marker, block(width: 100%, breakable: true, body))
#let proofdir(marker, body) = [#marker~~#body]

// Math notation
#let boxeq(inset: 2mm, bl: 2mm, body, punct: "") = (
  $
    #box(
  baseline: bl,
  stroke: .15mm + luma(80%),
  inset: ("y": inset, "x": 2mm),
  $display0.5ody)$,

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
    stroke: .15mm + luma(50%),
    inset: .3mm,
    text(size: 7pt, font: "New Computer Modern Sans 08", body),
  ),
)
#let dom = math.op("dom")
#let diag = math.op("diag")
// [#math.cal("N")#h(-.8mm)#math.cal("P")]
// #let coNP = [co-#NP]
