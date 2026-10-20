#import "_common.typ": *

#let W = 184mm
#let H = 80mm
#show: setup.with(W, H)

#frame(W, H,
  label: [Figure 01 · Closed loop],
  solid: [Closed], outline: [loop.],
  lede: [over physical hardware — the target \ is never modified.],
  tags: [act · see · judge],
  vertical: ([Hardware], [Loop], [2026]),
  foot-left: [No driver · no agent · no network service on the target],
  foot-right: [Locked desktop · BIOS · console · phone],
)

#let NY = 22mm   // index row
#let RY = 26.5mm // node rule

#let node(x, w, idx, accent, name, sub, body) = {
  at(x, NY, index(accent, idx))
  hline(x, x + w, RY)
  at(x, RY + 2.6mm, block(width: w, spacing: 0pt)[
    #set par(leading: 0.55em)
    #text(size: 14pt, weight: 250, tracking: -0.02em)[#name]
    #v(1.4mm)
    #caps(size: 4.4pt, track: 0.2em)[#sub]
    #v(3.2mm)
    #text(size: 6.4pt, fill: muted)[#body]
  ])
}

#node(62mm, 24mm, "01", lilac, "Agent", [llm · script · cli])[
  Decides what to type. Reads frames back and judges what happened.]

#node(98mm, 26mm, "02", sky, "Bridge", [linux · bluez · capture])[
  HID Device role. L2CAP PSM 17 / 19. #mono[/dev/videoN] frames.]

#node(146mm, 24mm, "03", mint, "Target", [any os · unmodified])[
  Sees a generic Bluetooth keyboard. Outputs HDMI.]

// agent ↔ bridge
#arrow(87.5mm, 96.5mm, 33.6mm, 1, faint)
#arrow(87.5mm, 96.5mm, 35.6mm, -1, faint)

// ACTION: bridge → target
#let AX0 = 126mm
#let AX1 = 144mm
#at(AX0, 30.2mm, caps(size: 4.6pt, track: 0.3em, fill: sky.darken(20%))[action])
#arrow(AX0, AX1, 33.6mm, 1, sky.darken(10%))
#at(AX0, 35mm, text(size: 5.4pt, fill: muted)[Bluetooth HID \ keys · clicks])

// PERCEPTION: target → bridge
#at(AX0, 44.2mm, caps(size: 4.6pt, track: 0.3em, fill: mint.darken(30%))[perception])
#arrow(AX0, AX1, 47.6mm, -1, mint.darken(20%))
#at(AX0, 49mm, text(size: 5.4pt, fill: muted)[HDMI → USB \ capture frames])
