#import "_common.typ": *
#set page(width: 184mm, height: 74mm, margin: 0mm, fill: paper)
#set text(font: "DejaVu Sans", size: 8.5pt, fill: ink)

#place(top + left, dx: 4mm, dy: 3mm,
  text(weight: "bold", size: 10.5pt)[A closed loop over physical hardware])
#place(top + left, dx: 4mm, dy: 8.4mm,
  text(size: 7.6pt, fill: muted)[The target is never modified. It sees an ordinary Bluetooth keyboard and sends out ordinary video.])

#let BY = 15mm
#let BH = 40mm

#place(top + left, dx: 4mm, dy: BY,
  node(40mm, BH, "Your agent", "LLM, script or CLI", purple)[
    Decides what to type. \
    Reads frames back and \
    judges what happened.
  ], )

#place(top + left, dx: 60mm, dy: BY,
  node(46mm, BH, "Bridge host", "Linux + BlueZ + capture", blue)[
    HID Device role. \
    L2CAP PSM 17 / 19. \
    #tick("/dev/videoN") frames.
  ], )

#place(top + left, dx: 142mm, dy: BY,
  node(38mm, BH, "Target", "any OS, unmodified", green)[
    Sees a generic \
    Bluetooth keyboard. \
    Outputs HDMI.
  ], )

// agent <-> bridge
#place(top + left, dx: 0mm, dy: 0mm,
  line(start: (45.5mm, 35mm), end: (58.5mm, 35mm), stroke: 0.9pt + hair))
#place(top + left, dx: 44.3mm, dy: 32.1mm, text(size: 8pt, fill: hair)[◀])
#place(top + left, dx: 56.6mm, dy: 32.1mm, text(size: 8pt, fill: hair)[▶])

// ACTION: bridge -> target
#place(top + left, dx: 0mm, dy: 0mm,
  line(start: (107mm, 27mm), end: (139mm, 27mm), stroke: 1.1pt + blue))
#place(top + left, dx: 137.2mm, dy: 24.1mm, text(size: 8.5pt, fill: blue)[▶])
#place(top + left, dx: 108mm, dy: 19.2mm,
  text(size: 7.2pt, weight: "bold", fill: blue)[ACTION])
#place(top + left, dx: 108mm, dy: 28.4mm,
  text(size: 7pt, fill: muted)[Bluetooth HID \ keys · clicks])

// PERCEPTION: target -> bridge
#place(top + left, dx: 0mm, dy: 0mm,
  line(start: (139mm, 46mm), end: (107mm, 46mm), stroke: 1.1pt + green))
#place(top + left, dx: 106.2mm, dy: 43.1mm, text(size: 8.5pt, fill: green)[◀])
#place(top + left, dx: 108mm, dy: 38.2mm,
  text(size: 7.2pt, weight: "bold", fill: green)[PERCEPTION])
#place(top + left, dx: 108mm, dy: 47.4mm,
  text(size: 7pt, fill: muted)[HDMI → USB capture \ frames])

#place(top + left, dx: 4mm, dy: 62mm,
  box(width: 176mm, inset: (x: 3mm, y: 2.2mm), radius: 1.6mm,
      fill: rgb("#f3f5f8"), stroke: 0.5pt + hair)[
    #text(size: 7.4pt, fill: muted)[*Why it matters* — no driver, no agent and no network service is installed on the target, so the same method reaches a locked desktop, a BIOS screen, a games console or a phone.]
  ])
