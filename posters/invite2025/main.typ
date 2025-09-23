#import "@preview/one-liner:0.1.0": fit-to-width
#import "@preview/cades:0.3.0": qr-code

#set page(paper: "a4", margin: 1.5cm, fill: rgb("#E5E3DA"))

#let brand-green = rgb("#4F7740")
#let brand-green-dark = rgb("#38572d")
#let brand-red = rgb("#822D1C")
#let brand-red-bright = rgb("#a92b12")
#let brand-paper = rgb("#FCF8F4")
#let brand-gray = rgb("#4a4a4a")
#let brand-light = rgb("#E5E3DA")

#let accent = brand-green
#let accent-alt = brand-red
#let accent-bright = brand-red-bright
#let dark = brand-gray
#let soft = brand-paper

#set text(fill: dark, font: "Manrope", size: 14pt)

#show heading.where(level: 1): set text(size: 56pt, weight: 700, fill: accent-alt, font: "Neuton")
#show heading.where(level: 2): set text(size: 24pt, weight: 600, fill: accent-alt, font: "Neuton")
#show heading.where(level: 3): set text(size: 16pt, weight: 600, fill: accent, font: "Neuton")

#block(
  [
    #set par(leading: 0.1em, justify: false)

    #block(
      fill: accent-alt, inset: (left: 16pt, right: 16pt, top: 2pt, bottom: 8pt),
      // width: 120%,
    )[
      #text(size: 28pt, weight: 900, fill: white, font: "Neuton")[PRG • PRG]
    ]
    #v(-5pt)
    #block(
      fill: accent, inset: (left: 16pt, right: 16pt, top: 2pt, bottom: 20pt), width: 100%,
    )[
      #text(
        size: 54pt, weight: 200, fill: white, font: "Neuton",
      )[Student Programming Language Meetup]
    ]
    #v(6pt)
    #block(
      inset: (left: 0pt, right: 0pt, top: 2pt, bottom: 20pt), width: 100%,
    )[
      #set text(size: 19pt, weight: 600, fill: accent, font: "Manrope")
      #align(
        horizon + center, fit-to-width[Talks • Invited Speakers • Discussion • Community],
      )
    ]
  ],
)

#set par(leading: 0.7em, justify: false)

// == What it is?

Student & alumni community from *FIT ČVUT* • *FEL ČVUT* • *MFF UK*
meeting to discuss programming languages and related topics.

#set list(marker: text(fill: accent-bright, "▸"))
#list(
  [Share lightning & deep-dive talks], [Discuss PL concepts, compilers, runtimes], [Explore research ideas & language design], [Grow a supportive local PL network],
)

#v(1fr)

#grid(
  columns: (3fr, 1fr), align: bottom, [
    #block(
      fill: accent, inset: 16pt, width: 100%,
    )[
      #text(size: 18pt, weight: 600, fill: white)[Next Meetup (vol. VOL)]
      #v(8pt)
      #set text(fill: white)
      #list(
        [📅 *DATE* at *TIME*], [📍 *VENUE / ROOM*], [⏱ Talks ~ 5–30 min — mix of formats],
      )
    ]
  ], [
    #block(fill: none, [
      #block(fill: white, inset: 15pt, [
        #set text(weight: 900, fill: accent, size: 20pt)
        #set align(center)
        #qr-code("https://discord.gg/eBznsEpD2V", width: 100%, color: accent)
        #v(-13pt)
        Discord
      ])
    ])
  ],
)

#v(10pt)

#block()[
  #set text(size: 19pt, weight: 600, fill: accent-alt, font: "Neuton")
  #align(horizon + center, fit-to-width[student-meetup.prgprg.org])
]#v(30pt)#align(center)[
  #set text(size: 9pt, style: "italic", fill: luma(30%))
  Prague Programming Languages & Systems Research Network

  Responsible FEL CVUT employee: Jakub Dupák \<dupakjak\@fel.cvut.cz>
]
