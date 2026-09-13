// Recovered from Costis Gabri monograph/texcontent/figures/L03/km_game.typ
#set page(width: auto, height: auto, fill: none, margin: 0mm)
#set text(font: "New Computer Modern", size: 10pt)
#import "../libs/nash.typ": brown, game_table, nash_cmap, nashf
#import "@preview/cetz:0.4.1"

#let sf = text.with(font: "Frutiger")
#let U = ((1, 0, -1), (-1, 0, -1), (1, 0, -2))
#let V = ((1, -1, 1), (0, 0, 0), (-1, -1, -2))

#game_table(U, V, (sf[A], sf[B], sf[C]), (sf[A], sf[B], sf[C]), cw: 1.4cm)
