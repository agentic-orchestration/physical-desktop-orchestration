#import "_common.typ": *
#set page(width: 184mm, height: 104mm, margin: 0mm, fill: paper)
#set text(font: "DejaVu Sans", size: 8.5pt, fill: ink)

#place(top + left, dx: 4mm, dy: 3mm,
  text(weight: "bold", size: 10.5pt)[One radio, many clients, one link at a time])
#place(top + left, dx: 4mm, dy: 8.6mm, box(width: 176mm,
  text(size: 7.6pt, fill: muted)[Each client is bonded once and remembered. Switching drops one link and raises another.]))

#place(top + left, dx: 6mm, dy: 36mm,
  box(width: 54mm, height: 30mm, radius: 2.2mm,
      stroke: 0.7pt + blue, fill: blue.lighten(93%), inset: 3.2mm)[
    #text(weight: "bold", size: 9pt, fill: blue.darken(22%))[Bridge]
    #linebreak()
    #text(size: 7pt, fill: muted)[one adapter, one descriptor]
    #v(1.4mm)
    #text(size: 7.4pt)[Keyboard and mouse ride \ the same bond.]
  ])

#let client(y, label, sub, active) = {
  let a = if active { green } else { hair }
  place(top + left, dx: 122mm, dy: y,
    box(width: 56mm, height: 20mm, radius: 2mm,
        stroke: 0.7pt + a, fill: if active { green.lighten(93%) } else { rgb("#f7f8fa") },
        inset: 3mm)[
      #text(weight: "bold", size: 8.2pt, fill: if active { green.darken(20%) } else { muted })[#label]
      #linebreak()
      #text(size: 6.9pt, fill: muted)[#sub]
    ])
  let ly = y + 10mm
  if active {
    place(top + left, line(start: (60mm, 51mm), end: (121mm, ly), stroke: 1.4pt + green))
    place(top + left, dx: 82mm, dy: ly - 7.4mm,
      text(size: 7pt, weight: "bold", fill: green.darken(12%))[active link])
  } else {
    place(top + left, line(start: (60mm, 51mm), end: (121mm, ly),
      stroke: (paint: hair, thickness: 1pt, dash: "dashed")))
  }
}

#client(16mm, "Client A", "bonded · idle", false)
#client(41mm, "Client B", "bonded · connected", true)
#client(66mm, "Client C", "bonded · idle", false)

#place(top + left, dx: 4mm, dy: 91mm, box(width: 176mm,
  text(size: 7.2pt, fill: muted)[*Count your hardware this way*: one radio on the bridge covers every client and every HID role, while each client machine needs a radio of its own. Holding several links live at once would make the bridge a member of several piconets, which controllers support unevenly, so treat simultaneous clients as unproven rather than routine.]))
