#import "_common.typ": *

#let W = 184mm
#let H = 118mm
#show: setup.with(W, H)

#frame(W, H,
  label: [Figure 02 · HID reports],
  solid: [Report], outline: [bytes.],
  lede: [what actually goes over the air — \ written to PSM 19, unacknowledged.],
  tags: [press · release · chord],
  vertical: ([Interrupt], [Channel], [2026]),
  foot-left: [Fire and forget · nothing acknowledges a report],
  foot-right: [Keyboard + mouse · one descriptor · one bond],
)

#let X0 = 62mm
#let XW = 108mm  // diagram width
#let pitch = 10.8mm
#let cw = 9.6mm  // cell width

// One byte: value over a hairline, coloured when it carries data.
#let byte(i, y, v, accent) = {
  let x = X0 + pitch * i
  let c = if accent == none { rule-c } else { accent }
  at(x, y, block(width: cw, height: 6mm, align(center + horizon,
    text(fill: if accent == none { faint } else { ink }, mono(size: 8pt)[#v]))))
  hline(x, x + cw, y + 6.6mm, stroke: (if accent == none { 0.4pt } else { 0.8pt }) + c)
}

#let row(y, items) = for (i, it) in items.enumerate() { byte(i, y, it.at(0), it.at(1)) }

// Bracket under byte indices a..b with a tracked caption.
#let span(y, a, b, label, accent) = {
  let xa = X0 + pitch * a
  let xb = X0 + pitch * b + cw
  let c = if accent == none { faint } else { accent.darken(20%) }
  hline(xa, xb, y, stroke: 0.4pt + c)
  vline(xa, y, y - 1mm, stroke: 0.4pt + c)
  vline(xb, y, y - 1mm, stroke: 0.4pt + c)
  at(xa - 4mm, y + 1.4mm, block(width: xb - xa + 8mm, align(center,
    caps(size: 4.2pt, track: 0.18em, fill: c, label))))
}

#let section(y, idx, accent, name) = {
  at(X0, y, { index(accent, idx); h(2.4mm); caps(size: 5pt, track: 0.35em, fill: ink)[#name] })
  hline(X0, X0 + XW, y + 4.2mm)
}

#let note(y, body) = at(X0, y, block(width: XW, text(size: 6.2pt, fill: muted, body)))

// ── keyboard ─────────────────────────────────────────────────────────────
#section(10mm, "01", sky, [Keyboard · report id 1])
#row(17mm, (
  ("A1", none), ("01", none), ("mod", sky), ("00", none),
  ("k1", sky), ("k2", sky), ("k3", sky), ("k4", sky), ("k5", sky), ("k6", sky),
))
#span(26.6mm, 0, 1, [header + id], none)
#span(26.6mm, 2, 2, [modifiers], sky)
#span(26.6mm, 3, 3, [reserved], none)
#span(26.6mm, 4, 9, [up to six usages held at once], sky)
#note(33mm)[A keypress is two reports: one with the usage set, one with it cleared. That release is what makes a repeated letter register twice.]

// ── mouse ────────────────────────────────────────────────────────────────
#section(44mm, "02", amber, [Mouse · report id 2 · same descriptor, same bond])
#row(51mm, (
  ("A1", none), ("02", none), ("btn", amber), ("dx", amber), ("dy", amber), ("whl", amber),
))
#span(60.6mm, 0, 1, [header + id], none)
#span(60.6mm, 2, 2, [buttons], amber)
#span(60.6mm, 3, 4, [signed −127…127], amber)
#span(60.6mm, 5, 5, [wheel], amber)
#note(67mm)[Movement is a delta per report, not a coordinate, so crossing the screen is a stream of small reports. An absolute-pointer collection is what lets you say “go to x, y”.]

// ── modifier bits ────────────────────────────────────────────────────────
#section(78mm, "03", lilac, [The modifier byte, bit by bit])
#let mods = (
  ("0x01", "L-Ctrl"), ("0x02", "L-Shift"), ("0x04", "L-Alt"), ("0x08", "L-GUI"),
  ("0x10", "R-Ctrl"), ("0x20", "R-Shift"), ("0x40", "R-Alt"), ("0x80", "R-GUI"),
)
#let mp = XW / 8
#for (i, m) in mods.enumerate() {
  let x = X0 + mp * i
  at(x, 85mm, block(width: mp - 1.6mm, spacing: 0pt)[
    #mono(size: 7pt)[#m.at(0)]
    #v(1.2mm)
    #caps(size: 4.2pt, track: 0.18em)[#m.at(1)]
  ])
  hline(x, x + mp - 1.6mm, 93.6mm, stroke: 0.6pt + lilac)
}
#note(97mm)[Modifiers live in the same report as the key, so a chord is one report with both fields set — never two separate events.]
