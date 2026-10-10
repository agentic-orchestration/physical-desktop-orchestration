#import "_common.typ": *
#set page(width: 184mm, height: 116mm, margin: 0mm, fill: paper)
#set text(font: "DejaVu Sans", size: 8.5pt, fill: ink)

#let byte(v, accent) = box(
  width: 13.4mm, height: 9mm, radius: 1.4mm,
  stroke: 0.7pt + accent, fill: accent.lighten(93%),
)[
  #set align(center + horizon)
  #text(font: "DejaVu Sans Mono", size: 9pt, weight: "bold", fill: accent.darken(22%))[#v]
]

#let pitch = 15.0mm
#let x0 = 6mm

#let row(y, items) = {
  for (i, it) in items.enumerate() {
    place(top + left, dx: x0 + pitch * i, dy: y, byte(it.at(0), it.at(1)))
  }
}

// a bracket spanning byte indices a..b with a caption
#let span(y, a, b, label, accent) = {
  let xa = x0 + pitch * a
  let xb = x0 + pitch * b + 13.4mm
  place(top + left, line(start: (xa, y), end: (xb, y), stroke: 0.7pt + accent))
  place(top + left, line(start: (xa, y), end: (xa, y - 1.4mm), stroke: 0.7pt + accent))
  place(top + left, line(start: (xb, y), end: (xb, y - 1.4mm), stroke: 0.7pt + accent))
  place(top + left, dx: xa, dy: y + 1.0mm,
    box(width: xb - xa)[
      #set align(center)
      #text(size: 6.9pt, fill: accent.darken(10%))[#label]
    ])
}

#place(top + left, dx: 4mm, dy: 3mm,
  text(weight: "bold", size: 10.5pt)[What actually goes over the air])
#place(top + left, dx: 4mm, dy: 8.4mm,
  text(size: 7.6pt, fill: muted)[Every report is written to the interrupt channel (PSM 19). Fire and forget: nothing acknowledges it.])

// ---------- keyboard ----------
#place(top + left, dx: 4mm, dy: 16mm,
  text(weight: "bold", size: 8.4pt, fill: blue)[Keyboard · Report ID 1])

#row(21mm, (
  ("A1", hair), ("01", hair), ("mod", blue), ("00", hair),
  ("k1", blue), ("k2", blue), ("k3", blue), ("k4", blue), ("k5", blue), ("k6", blue),
))
#span(33mm, 0, 1, "transaction header + report id", muted)
#span(33mm, 2, 2, "modifiers", blue)
#span(33mm, 3, 3, "reserved", muted)
#span(33mm, 4, 9, "up to six usages held down at the same time", blue)

#place(top + left, dx: 6mm, dy: 40mm, box(width: 172mm,
  text(size: 7.2pt, fill: muted)[A keypress is two reports: one with the usage set, one with it cleared. That release is what makes a repeated letter register twice.]))

// ---------- mouse ----------
#place(top + left, dx: 4mm, dy: 50mm,
  text(weight: "bold", size: 8.4pt, fill: amber)[Mouse · Report ID 2 — same descriptor, same bond])

#row(55mm, (
  ("A1", hair), ("02", hair), ("btn", amber), ("dx", amber), ("dy", amber), ("whl", amber),
))
#span(67mm, 0, 1, "header + report id", muted)
#span(67mm, 2, 2, "buttons", amber)
#span(67mm, 3, 4, "signed −127…127", amber)
#span(67mm, 5, 5, "wheel", amber)

#place(top + left, dx: 6mm, dy: 74mm, box(width: 172mm,
  text(size: 7.2pt, fill: muted)[Movement is a delta per report, not a coordinate, so crossing the screen is a stream of small reports. An absolute-pointer collection, instead of a relative one, is what lets you say "go to x, y".]))

// ---------- modifier bits ----------
#place(top + left, dx: 4mm, dy: 86mm,
  text(weight: "bold", size: 8.4pt, fill: blue)[The modifier byte, bit by bit])

#let mods = (
  ("0x01", "L-Ctrl"), ("0x02", "L-Shift"), ("0x04", "L-Alt"), ("0x08", "L-GUI"),
  ("0x10", "R-Ctrl"), ("0x20", "R-Shift"), ("0x40", "R-Alt"), ("0x80", "R-GUI"),
)
#for (i, m) in mods.enumerate() {
  place(top + left, dx: 6mm + 21.6mm * i, dy: 91mm,
    box(width: 20mm, height: 10mm, radius: 1.4mm,
        stroke: 0.6pt + hair, fill: rgb("#f6f8fb"))[
      #set align(center + horizon)
      #stack(spacing: 0.6mm,
        text(font: "DejaVu Sans Mono", size: 7.4pt, weight: "bold", fill: blue)[#m.at(0)],
        text(size: 6.6pt, fill: muted)[#m.at(1)])
    ])
}
#place(top + left, dx: 6mm, dy: 103.5mm, box(width: 172mm,
  text(size: 7.2pt, fill: muted)[Modifiers live in the same report as the key, so a chord is one report with both fields set — never two separate events.]))
