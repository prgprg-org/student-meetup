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
#set text(lang: "cs")

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
      #text(size: 28pt, weight: 600, fill: white, font: "Neuton")[PRG • PRG]
    ]
    #v(-5pt)
    #block(
      fill: accent, inset: (left: 16pt, right: 16pt, top: 2pt, bottom: 20pt), width: 100%,
    )[
      #text(
        size: 48pt, weight: 600, fill: white, font: "Neuton",
      )[Student Programming Language Meetup]
    ]
    #block(
      inset: (left: 0pt, right: 0pt, top: 2pt, bottom: 12pt), width: 100%,
    )[
      #set text(size: 17.7pt, weight: 600, fill: accent, font: "Manrope")
      #show " • ": [#h(6pt) • #h(6pt)]
      #align(
        horizon + center, [Talky a prezentace • Externí hosté • Diskuse • Komunita],
      )
    ]
  ],
)

#set par(leading: 0.75em, justify: true)

Přidejte se ke komunitě studentů a absolventů #h(4pt) *FEL ČVUT*, #h(4pt) *FIT ČVUT*, #h(4pt) *MFF UK* a přijďte se dozvědět více o nejrůznějších zákoutích programovacích jazyků, compilerů a runtime systémů.

#v(16pt)
#block(fill: none)[
  #set text(size: 11pt)
  #set par(justify: true)
  #text(weight: 600, fill: accent)[Minulá témata] \
  #show " · ": [#h(2pt) • #h(2pt)]
  Zig Compiler Internals · Building a High-Performance Linker · How to Build and Break LLVM · Transpiling LLVM · Inside Rust Borrow Checker · Flow-Sensitive Typing (Kotlin) · Lua Register VM · Dependent Type Theory · Algebraic Effects · Type Kinds · Expression Problem · Continuations · Costs of Mutability · Theorems for Free · Automated Theorem Proving = Logic Programming · Isabelle/HOL · Symbolic Execution · Typst Template Lessons · Scalene Profiler · Breaking Python · Slightly Less Broken C · Inside PDF · APL · Φ Nodes are Functions! · WAT: Hardware Edition · Weird Stuff PowerShell Does  ·  (a mnohem více)
]
#v(1fr)

#grid(
  columns: (6fr, 2fr), align: bottom, [
    #block(
      fill: accent, inset: 16pt, width: 100%,
    )[
      #text(size: 14pt, weight: 600, fill: white)[*Příští meetup*]
      #v(3pt)
      #set text(fill: white, size: 12pt)


      - *Povídání o děrovacích štítcích a páskách*:\ speciální hosté Dr. Božena Mannová
        a prof. Oldřich Starý
      - *Zig comptime a co se s ním dá dělat*: Max Hollmann
      - *Stacking monads*: Michal Atlas

      #v(4pt)

      📅 *20.10.* *18:00-21:00* #h(1fr)
      📍 *FEL ČVUT Dejvice (T2:C3-132)* #h(1fr)
    ]
  ], [
    #block(
      fill: none, [
        #block(fill: white, inset: 15pt, [
          #set text(weight: 900, fill: accent, size: 20pt)
          #set align(center)
          #qr-code("https://discord.gg/eBznsEpD2V", width: 100%, color: accent)
          #v(-13pt)
          Discord
        ])
      ],
    )
  ],
)

#block(width: 100%)[
  #set align(center)
  #set text(size: 32pt, weight: 600, fill: accent-alt, font: "Neuton")
  #align(horizon + center, "student-meetup.prgprg.org")
]#v(15pt)#align(center)[
  #set text(size: 9pt, style: "italic", fill: luma(30%))
  Prague Programming Languages & Systems Research Network

  Zodpovědná osoba FEL ČVUT: Jakub Dupák \<dupakjak\@fel.cvut.cz>
]
