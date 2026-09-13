// Recovered from Costis Gabri monograph/texcontent/figures/L06/plots.typ
#set page(width: auto, height: auto, fill: none, margin: (left: 1mm, right: 0mm, y: .5mm))
#set text(font: "New Computer Modern", size: 9pt)
#import "../../meta/dyns.typ": dynplot, entropy-prox, euc-prox
#import "@preview/cetz:0.4.1"
#import "@preview/cetz-plot:0.1.2"

#show text: emph

#stack(
  dir: ltr,
  spacing: 1mm,
  box(width: 3.1cm, scale(62%, reflow: true, include "ftr_ent.typ")),
  box(width: 2.75cm, scale(62%, reflow: true, include "ftr_euc.typ")),
  box(width: 2.75cm, scale(62%, reflow: true, include "ftr_log.typ")),
  box(width: 2.9cm, scale(62%, reflow: true, include "omd_euc.typ")),
)
