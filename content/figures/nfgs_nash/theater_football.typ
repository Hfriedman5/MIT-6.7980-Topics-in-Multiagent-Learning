// Recovered from Costis Gabri monograph/texcontent/figures/L01/theater_football.typ
#set page(width: auto, height: auto, fill: none, margin: 0mm)
#set text(font: "New Computer Modern", size: 10pt)
#import "../libs/nash.typ": brown, game_table, nash_cmap, nashf
#import "@preview/cetz:0.4.1"

#show text: emph

#game_table(
  ((0, 5), (1, 0)),
  ((0, 1), (5, 0)),
  ("insist", "accept"),
  ("insist", "accept"),
  cw: 1.4cm,
)
