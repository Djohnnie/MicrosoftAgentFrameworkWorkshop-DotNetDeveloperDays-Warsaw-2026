# Presentation tools

The 60 numbered SVG sources in `_slides` introduce the workshop, cover
AI fundamentals, token usage and pricing, and interleave Agent Framework concepts
with Part 1 and Part 2 exercises and labs, Part 3 orchestration exercises and lab,
and Part 4 authentication exercises.
They also introduce the remaining workshop sections. They can be exported as a
full-bleed image-based PowerPoint. The
tools use PowerShell and Microsoft Edge, with no Python, Node.js, or package
installation required.

## Build the SVG sources

From the repository root:

```powershell
.\_tools\build-slides.ps1
```

To regenerate only selected slides without touching the others:

```powershell
.\_tools\build-slides.ps1 -OnlySlides 1
```

Edit the content and layouts in `build-slides.ps1` and rerun it. It generates
`slide-01.svg` through `slide-60.svg`, embedding the fonts, conference logo,
Zure icon, speaker photo, and repository QR code from `_resources`. Use
`-OnlySlides` with slide numbers to regenerate selected slides without
touching the others.

The slides have a 3840 x 2160 canvas and a 1920 x 1080 coordinate system. Keep
important content within the 100-unit horizontal margins and above the footer
at y=985. Use Raleway 700 for headings and Open Sans for body text. XML-escape
text when editing the generator.

Slides 2 through 60 include the repository link, Zure icon, and slide number in
the footer; the title slide has no footer.

## Exercise slide template

Exercise 001 on slide 12, exercises 101-106 on slides 23, 25, 26, 29, 30, and 33,
lab 100 on slide 35, exercises 201-205 on slides 38, 39, 42, 44, and 46,
lab 200 on slides 48-50, exercises 301-302 on slides 52-53,
lab 300 on slide 54, and exercises 401-404 on slides 56-59 use
`ExerciseBody` in `build-slides.ps1`: a hands-on
banner, exercise number badge, three numbered action cards, a clickable project
path, and a takeaway. Reuse this helper for future exercises and labs, supplying
the exercise number, title, subtitle, repository-relative project path, exactly three step
titles/detail arrays, and a short takeaway. Keep card details to at most three short
lines and the title short enough to fit beside the decorative code icon.
For labs, pass `-badge 'LAB'` so the number badge reads LAB instead of
EXERCISE.
Pass the resulting body to `SaveSlide` with the new slide number.

## Concept slides and sources

`ConceptSlide` uses three unnumbered teaching cards, a takeaway, and a source
link. Keep labels short and each card to at most seven short lines. Use the
existing `Text` and `Lines` helpers for escaping, including on custom diagrams
or tables.

Token slides 13-14 adapt slides 205-206 from the
[AI4Dev two-day workshop](https://github.com/Djohnnie/AI4Dev-Workshop-2026/tree/main/content/2-day/chapter-2)
to direct model API usage. Slide 14's prices are a dated OpenAI Standard API
snapshot, not Foundry prices; update the source, date, table, worked calculation,
and root guide together when refreshing prices.

Part 1 spans slides 21-35; Part 2 spans 36-50. The remaining section dividers are
51 and 55. Exercises 301-302 are slides 52-53, Lab 300 is slide 54,
Part 4 exercises are 56-59, and the closing slide is 60. When inserting
slides, update the explicit section-divider numbers, all affected
`SaveSlide` / `ConceptSlide` numbers,
the root guide, and these references before regenerating the SVGs and deck.

## Export PowerPoint

```powershell
.\_tools\svg_to_pptx.ps1
```

The exporter collects numbered `slide-NN.svg` files, sorts them by name,
renders each at 3840 x 2160 using headless Edge, and writes
`MicrosoftAgentFrameworkWorkshop-DotNetDeveloperDays-Warsaw-2026.pptx` at the
repository root.
Rendering failures stop generation without replacing an existing deck.

**The exported PowerPoint slides are images, not editable text or shapes.**
Edit the SVG source and export again.
