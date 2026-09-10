#import "@preview/cetz:0.2.2"

#let sperner_w = 0.9
#let sperner_h = 0.7
#let sperner_radius = 1.4mm
#let bcx = sperner_w * 1 / 3
#let bcy = sperner_h * 1 / 3
#let grid_col = luma(40%);
#let trichromatic_col = green.lighten(60%)
// #let trichromatic_col = luma(75%)
#let de = (rel: (bcx + bcx, bcy - sperner_h + bcy))
#let deX = (rel: (bcx + bcx, 0))
#let dw = (rel: (-bcx - bcx, -bcy + sperner_h - bcy))
#let dn = (rel: (bcx - sperner_w + bcx, bcy + bcy))
#let ds = (rel: (-bcx + sperner_w - bcx, -bcy - bcy))
#let dne = (rel: (-bcx + sperner_w - bcx, -bcy + sperner_h - bcy))
#let dsw = (rel: (bcx - sperner_w + bcx, bcy - sperner_h + bcy))

#let _mark_trichromatic(..rows) = {
  import cetz.draw: *
  let N = rows.pos().len()
  for i in range(N - 1) {
    let row = rows.pos().at(i)
    for j in range(row.len() - 1) {
      let c = row.at(j)
      let pos = (j * sperner_w, (N - i - 1) * sperner_h)
      // Upper triangle:
      let x1 = rows.at(i).at(j)
      let x2 = rows.at(i).at(j + 1)
      let x3 = rows.at(i + 1).at(j + 1)
      if (x1 != x2 and x2 != x3 and x1 != x3 and x1 != "o" and x2 != "o" and x3 != "o") {
        line(pos, (rel: (sperner_w, 0)), (rel: (0, -sperner_h)), close: true, stroke: none, fill: trichromatic_col)
      }
      // Lower triangle
      x2 = rows.at(i + 1).at(j)
      if (x1 != x2 and x2 != x3 and x1 != x3 and x1 != "o" and x2 != "o" and x3 != "o") {
        line(
          pos,
          (rel: (sperner_w, -sperner_h)),
          (rel: (-sperner_w, 0)),
          close: true,
          stroke: none,
          fill: trichromatic_col,
        )
      }
    }
  }
}

#let _sperner_grid(bg: white, highlight: true, bottom_left: none, radius: sperner_radius, ..rows) = {
  import cetz.draw: *
  let N = rows.pos().len()
  rect((0, 0), ((rows.pos().at(0).len() - 1) * sperner_w, (N - 1) * sperner_h), stroke: none, fill: bg)
  if bottom_left != none {
    line((0, 0), (rel: (sperner_w, 0)), (rel: (-sperner_w, sperner_h)), close: true, stroke: none, fill: bottom_left)
  }
  if highlight {
    _mark_trichromatic(..rows)
  }

  for i in range(N) {
    let row = rows.pos().at(i)
    for j in range(row.len()) {
      let c = row.at(j)
      let col = (r: red, b: blue, y: yellow, o: white).at(c)
      let pos = (j * sperner_w, (N - i - 1) * sperner_h)
      if j < row.len() - 1 {
        line(pos, (rel: (sperner_w, 0)), stroke: .25mm + grid_col)
      }
      if i < N - 1 {
        line(pos, (rel: (0, -sperner_h)), stroke: .25mm + grid_col)
      }
      if j < row.len() - 1 and i < N - 1 {
        line(pos, (rel: (sperner_w, -sperner_h)), stroke: .2mm + grid_col)
      }
      circle(pos, radius: radius, fill: col, stroke: col.darken(30%) + .3mm)
    }
  }
}

#let sperner_grid(..rows) = cetz.canvas(
  length: 8mm,
  {
    import cetz.draw: *
    rect((0, 0), ((rows.pos().at(0).len() - 1) * sperner_w, (rows.pos().len() - 1) * sperner_h), stroke: .5mm + black)
    _sperner_grid(..rows)
  },
)

#let sperner_path(pos, which, ..mvmt) = {
  import cetz.draw: circle, line, set-style, content
  let p = pos
  p.at(0) *= sperner_w
  p.at(1) *= sperner_h
  assert(which in ("lower", "upper"))
  if which == "lower" {
    p.at(0) += bcx
    p.at(1) += bcy
  } else {
    p.at(0) += sperner_w - bcx
    p.at(1) += sperner_h - bcy
  }
  if pos == (-1, 0) {
    p = (-bcx, bcy)
  }
  let initial_p = p
  set-style(mark: (end: ">", fill: black, scale: .5))
  for m in mvmt.pos() {
    assert(m.rel != none)
    line(p, (rel: (m.rel.at(0) * .9, m.rel.at(1) * .9)))
    p.at(0) += m.rel.at(0)
    p.at(1) += m.rel.at(1)
  }
  // content(p, scale(120%, sym.square.filled))
  circle(p, radius: .65mm, fill: black)
  circle(initial_p, radius: .65mm, fill: black) // fill: white?
}