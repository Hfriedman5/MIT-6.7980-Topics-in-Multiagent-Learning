// Recovered from Costis Gabri monograph/texcontent/figures/L06/table.typ
#set page(width: auto, height: auto, fill: none, margin: (left: 1mm, right: 0mm, y: .5mm))
#set text(font: "New Computer Modern", size: 9pt)
#import "../../meta/dyns.typ": dynplot, entropy-prox, euc-prox
#import "@preview/cetz:0.4.1"
#import "@preview/cetz-plot:0.1.2"

#let va = $a$
#let vb = $b$
#let vx = $x$
#let vy = $y$
#let vg = $g$
#let vm = $m$
#let vr = $r$
#let vz = $z$
#let cX = math.cal("X")
#let cY = math.cal("Y")
#let cR = math.cal("R")
#let darkblue = blue.darken(20%)

#let argmax = math.op($arg#h(1mm)max$, limits: true)
#let ip(a, b) = $lr(⟨#a, #b⟩)$

#table(
  columns: (auto, auto, auto),
  align: (horizon + left, horizon + center, horizon + center),
  inset: (y: 1.8mm, x: 1.0mm),
  fill: (j, i) => if i >= 0 and j == 2 {
    blue.lighten(95%)
  } else {
    none
  },
  stroke: (
    j,
    i,
  ) => (
    top: (
      if i == 0 {
        black + .4mm
      } else {
        none
      }
    ),
    bottom: (
      if i == 0 or i == 2 {
        black + .4mm
      } else {
        gray + .2mm
      }
    ),
    left: (
      if j > 0 {
        gray + .2mm
      }
    ),
    right: (
      if j > 0 and j < 2 {
        gray + .2mm
      }
    ),
  ),
  table.header()[][*Non-predictive version*][*Predictive version*],
  [FTRL],
  $
    vx^((t+1)) := argmax_(vx in cal(X)) {ip(sum_(tau = 1)^t vg^((tau)), vx) - 1 / eta psi(vx)}
  $,
  $
    vx^((t+1)) := argmax_(vx in cal(X)) { ip(#text(darkblue, $vm^((t+1))$) + sum_(tau = 1)^t vg^((tau)), vx) - 1 / eta psi(vx) }
  $,

  [OMD],
  $
    vx^((t+1)) := argmax_(vx in cal(X)) {ip(vg^((t)), vx) - 1 / eta upright("D")_psi (vx || vx^((t)))}
  $,
  [
    #align(left)[#sym.circle.filled *Non-reflected version:*]
    $
      vz^((t+1)) &:= argmax_(vz in cal(X)) {ip(vg^((t)), vz) - 1 / eta upright("D")_psi (vz || vz^((t)))} \
      vx^((t+1)) &:= argmax_(vx in cal(X)) { ip(#text(darkblue, $vm^((t+1))$), vx) - 1 / eta upright("D")_psi (vx || vz^((t+1))) }
    $

    #align(left)[#sym.circle.filled *Reflected version:*]
    $
      vx^((t+1)) := argmax_(vx in cal(X)) { ip(vg^((t)) + #text(darkblue)[$vm^((t+1)) - vm^((t))$], vx) - 1 / eta upright("D")_psi (vx || vx^((t))) }
    $],
)
