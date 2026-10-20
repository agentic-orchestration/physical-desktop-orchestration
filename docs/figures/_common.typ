// Shared style for the explanatory figures: thin display type, wide-tracked
// uppercase labels, hairlines, a gradient edge accent and a faint wash
// instead of filled boxes.
#let ink    = rgb("#16181d")
#let muted  = rgb("#596273")
#let paper  = rgb("#ffffff")
#let lilac  = rgb("#a78bfa")
#let mint   = rgb("#34d399")
#let sky    = rgb("#60a5fa")
#let amber  = rgb("#f59e0b")
#let faint  = ink.transparentize(38%)
#let rule-c = ink.transparentize(88%)

// Page and text defaults. Use as `#show: setup.with(W, H)`.
#let setup(W, H, body) = {
  set page(width: W, height: H, margin: 0mm, fill: paper)
  set text(font: "Ubuntu", weight: 300, size: 7pt, fill: ink)
  body
}

// Tracked uppercase label.
#let caps(s, size: 5.2pt, track: 0.45em, fill: faint) = text(
  size: size, weight: 300, tracking: track, fill: fill, upper(s))

#let mono(s, size: 6.4pt) = text(font: "Ubuntu Mono", size: size, s)

#let at(x, y, body) = place(top + left, dx: x, dy: y, body)
#let hline(x0, x1, y, stroke: 0.4pt + rule-c) = at(0mm, 0mm,
  line(start: (x0, y), end: (x1, y), stroke: stroke))
#let vline(x, y0, y1, stroke: 0.4pt + rule-c) = at(0mm, 0mm,
  line(start: (x, y0), end: (x, y1), stroke: stroke))

// Hairline arrow with an open chevron head. dir: 1 = right, -1 = left.
#let arrow(x0, x1, y, dir, color) = {
  hline(x0, x1, y, stroke: 0.5pt + color)
  let tip = if dir > 0 { x1 } else { x0 }
  let back = tip - dir * 1.4mm
  at(0mm, 0mm, line(start: (tip, y), end: (back, y - 0.9mm), stroke: 0.5pt + color))
  at(0mm, 0mm, line(start: (tip, y), end: (back, y + 0.9mm), stroke: 0.5pt + color))
}

// Coloured dot followed by a small tracked label.
#let index(accent, s) = {
  box(baseline: -0.4mm, circle(radius: 0.7mm, fill: accent, stroke: none))
  h(1.6mm)
  caps(size: 5pt, track: 0.35em)[#s]
}

// Everything but the diagram: wash, edge accent, headline column,
// vertical right column and the bottom strip.
#let frame(W, H, label: none, solid: none, outline: none, lede: none,
           tags: none, vertical: (), foot-left: none, foot-right: none) = {
  // Watercolor wash, top-right.
  at(W - 82mm, -34mm, circle(radius: 52mm, stroke: none, fill: gradient.radial(
    lilac.transparentize(91%), sky.transparentize(95%), paper.transparentize(100%), paper.transparentize(100%),
  )))
  // Thin accent on the left edge.
  at(0mm, 0mm, rect(width: 0.8mm, height: H, stroke: none,
    fill: gradient.linear(lilac, mint, sky, angle: 90deg)))
  // Bottom strip.
  hline(0.8mm, W, H - 11mm, stroke: 0.4pt + ink.transparentize(90%))

  // Headline column.
  at(9mm, 10mm, caps(label))
  at(8.4mm, 17mm, block(spacing: 0pt)[
    #set par(leading: 0.1em)
    #text(size: 38pt, weight: 250, tracking: -0.04em)[#solid] \
    #text(size: 38pt, weight: 300, tracking: -0.04em,
          fill: paper.transparentize(100%), stroke: 0.35pt + ink.transparentize(40%))[#outline]
  ])
  at(9mm, 50mm, text(size: 6.6pt, tracking: 0.1em, fill: faint, lede))
  hline(9mm, 21mm, 62.6mm, stroke: 0.4pt + ink)
  at(25mm, 61.5mm, caps(size: 5pt, track: 0.3em, tags))

  // Vertical right column.
  at(W - 7.5mm, 0mm, block(height: H - 11mm, width: 4mm,
    align(horizon + center, rotate(90deg, reflow: true,
      caps(size: 4.8pt, track: 0.4em, vertical.join(h(5mm)))))))

  // Bottom strip text.
  at(9mm, H - 6.6mm, caps(size: 4.8pt, track: 0.4em, foot-left))
  at(0mm, H - 6.6mm, block(width: W - 9mm, align(right, caps(size: 4.8pt, track: 0.4em, foot-right))))
}
