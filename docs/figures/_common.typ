// Shared palette for the explanatory figures.
#let ink     = rgb("#16181d")
#let muted   = rgb("#596273")
#let hair    = rgb("#aab3c0")
#let blue    = rgb("#2f6feb")
#let green   = rgb("#1b8a4b")
#let amber   = rgb("#a86a0b")
#let red     = rgb("#c23b22")
#let purple  = rgb("#6b4fbb")
#let paper   = rgb("#ffffff")

#let node(w, h, title, sub, accent, body) = box(
  width: w, height: h, radius: 2.2mm,
  stroke: 0.7pt + accent,
  fill: accent.lighten(93%),
  inset: (x: 3.2mm, y: 2.8mm),
)[
  #text(weight: "bold", size: 9pt, fill: accent.darken(22%))[#title]
  #linebreak()
  #text(size: 7pt, fill: muted)[#sub]
  #v(1.4mm)
  #text(size: 7.4pt)[#body]
]

#let tick(s) = text(font: "DejaVu Sans Mono", size: 7pt)[#s]
