#import "_common.typ": *

#let W = 184mm
#let H = 84mm
#show: setup.with(W, H)

#frame(W, H,
  label: [Figure 03 · Clients],
  solid: [One], outline: [radio.],
  lede: [many clients, one link at a time — \ each bonded once and remembered.],
  tags: [bond · switch · drop],
  vertical: ([One], [Radio], [2026]),
  foot-left: [One radio on the bridge · one radio per client],
  foot-right: [Simultaneous links · unproven],
)

// ── bridge ───────────────────────────────────────────────────────────────
#let BX = 62mm
#let BW = 34mm
#at(BX, 22mm, index(sky, "01"))
#hline(BX, BX + BW, 26.5mm)
#at(BX, 29.1mm, block(width: BW, spacing: 0pt)[
  #set par(leading: 0.55em)
  #text(size: 14pt, weight: 250, tracking: -0.02em)[Bridge]
  #v(1.4mm)
  #caps(size: 4.4pt, track: 0.2em)[one adapter · one descriptor]
  #v(3.2mm)
  #text(size: 6.4pt, fill: muted)[Keyboard and mouse ride the same bond. Switching drops one link and raises another.]
])
#at(BX, 58mm, block(width: BW, text(size: 5.4pt, fill: faint)[
  Several live links would put the bridge in several piconets, which controllers support unevenly.]))

// ── clients ──────────────────────────────────────────────────────────────
#let CX = 138mm
#let CW = 30mm
#let OX = BX + BW + 2mm  // where the links leave the bridge
#let OY = 33.6mm

#let client(y, idx, name, sub, active) = {
  at(CX, y, index(if active { mint } else { ink.transparentize(75%) }, idx))
  hline(CX, CX + CW, y + 4.5mm)
  at(CX, y + 6.6mm, stack(spacing: 2mm,
    text(size: 11pt, weight: 250, tracking: -0.02em,
         fill: if active { ink } else { faint })[#name],
    caps(size: 4.4pt, track: 0.2em, fill: if active { mint.darken(30%) } else { faint })[#sub]))
  let ty = y + 8.8mm
  if active {
    at(0mm, 0mm, line(start: (OX, OY), end: (CX - 3mm, ty), stroke: 0.6pt + mint.darken(20%)))
  } else {
    at(0mm, 0mm, line(start: (OX, OY), end: (CX - 3mm, ty),
      stroke: (paint: ink.transparentize(70%), thickness: 0.4pt, dash: (1.2pt, 1.6pt))))
  }
}

#client(10mm, "A", "Client A", [bonded · idle], false)
#client(31mm, "B", "Client B", [bonded · connected], true)
#client(52mm, "C", "Client C", [bonded · idle], false)

#at(104mm, 30mm, caps(size: 4.6pt, track: 0.3em, fill: mint.darken(30%))[active link])
