# Presentation tools

The 30 numbered SVG sources in `_slides` introduce the workshop, cover
the AI fundamentals and Part 1 exercises, and introduce the remaining workshop sections. They can be exported as a
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
`slide-01.svg` through `slide-30.svg`, embedding the fonts, conference logo,
Zure icon, speaker photo, and repository QR code from `_resources`. Use
`-OnlySlides` with slide numbers to regenerate selected slides without
touching the others.

The slides have a 3840 x 2160 canvas and a 1920 x 1080 coordinate system. Keep
important content within the 100-unit horizontal margins and above the footer
at y=985. Use Raleway 700 for headings and Open Sans for body text. XML-escape
text when editing the generator.

Slides 2 through 30 include the repository link, Zure icon, and slide number in
the footer; the title slide has no footer.

## Exercise slide template

Slides 12, 20-25, and lab slide 26 use `ExerciseBody` in `build-slides.ps1`: a hands-on banner, exercise
number badge, three numbered action cards, a clickable project path, and a
takeaway. Reuse this helper for future exercises and labs, supplying the exercise
number, title, subtitle, repository-relative project path, exactly three step
titles/detail arrays, and a short takeaway. Keep card details to at most three short
lines and the title short enough to fit beside the decorative code icon.
For labs, pass `-badge 'LAB'` so the number badge reads LAB instead of
EXERCISE.
Pass the resulting body to `SaveSlide` with the new slide number.

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
