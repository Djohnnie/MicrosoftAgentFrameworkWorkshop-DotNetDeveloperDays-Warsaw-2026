# Presentation tools

The 79 numbered SVG sources in `_slides` introduce the workshop, cover
AI fundamentals, token usage and pricing, and interleave Agent Framework concepts
with Part 1 and Part 2 exercises and labs, Part 3 orchestration exercises and lab,
and Part 4 authentication exercises, a Foundry agent invocation, in-memory vector RAG, and the hybrid
Foundry/local-agent planner lab.
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
`slide-01.svg` through `slide-79.svg`, embedding the fonts, conference logo,
Zure icon, speaker photo, and repository QR code from `_resources`. Use
`-OnlySlides` with slide numbers to regenerate selected slides without
touching the others.

The slides have a 3840 x 2160 canvas and a 1920 x 1080 coordinate system. Keep
important content within the 100-unit horizontal margins and above the footer
at y=985. Use Raleway 700 for headings and Open Sans for body text. XML-escape
text when editing the generator.

Slides 2 through 79 include the repository link, Zure icon, and slide number in
the footer; the title slide has no footer.

## Exercise slide template

Exercise 001 on slide 14, exercises 101-109 on slides 26, 28, 30, 32, 35, 37, 40, 42, and 43,
lab 100 on slide 45, exercises 201-206 on slides 48, 51, 54, 56, 59, and 60,
lab 200 on slides 62-64, exercises 301-304 on slides 66-69,
lab 300 on slide 70, exercises 401-406 on slides 72-77, and lab 400 on slide 78 use
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

Token slides 15-16 adapt slides 207-208 from the
[AI4Dev two-day workshop](https://github.com/Djohnnie/AI4Dev-Workshop-2026/tree/main/content/2-day/chapter-2)
to direct model API usage. Slide 16 uses workshop-supplied Foundry Global EUR
figures for five models. Keep deployment types, dates, and unverified or missing
rates explicit; update the sources,
table, worked calculation, and root guide together when refreshing prices.

Slide 17 explains internal reasoning tokens, output billing, and API-reported
usage. Keep its no-double-counting example aligned with the reasoning sources.

Slide 29 introduces the shared `UsageDetails` contract on chat and agent
responses, provider-reported counts, and cost and context-budget monitoring
before exercise 103 on slide 30.

Slide 31 introduces system messages for persona, task context, and response
style before exercise 104 on slide 32. Keep the distinction between guiding
behavior and changing model knowledge explicit.

Slide 36 explains Agent Framework's backend abstraction through `IChatClient`
and local model hosting with Ollama before exercise 106 on slide 37. Distinguish
the agent layer, provider adapter, and model runtime; do not imply feature parity.

Slide 41 introduces multimodal models and Agent Framework's typed media content
before exercise 108 on slide 42. Keep model/API/adapter capability limits explicit
and preserve exercise 109's direct audio SDK boundary.

Slide 49 is a debugging walkthrough for exercise 201: break in both date/time
methods, follow invocation, and inspect the actual session through `DebugHistory`
in `Program.cs`. Match function calls and results by `CallId`; do not promise a
fixed model-selected tool order.

Slide 50 introduces tool-capable local models through Ollama before exercise
202 on slide 51. Distinguish model-requested calls from application execution,
and make clear that tool support depends on the model, runtime, and adapter.

Slide 58 introduces ASP.NET Core MCP hosting before exercise 205 on slide 59.
Keep the SDK registration, tool attributes, `/mcp` endpoint, and client discovery
aligned with that exercise. Distinguish SSE streaming inside Streamable HTTP from
the replaced legacy HTTP+SSE transport.

Slide 60 demonstrates `ApprovalRequiredAIFunction` with exercise 201's unchanged
date and time tools. Keep the displayed arguments, correlated decisions, default denial,
and distinction from exercise 303's workflow input aligned with exercise 206.

Slide 69 adds concurrent pitch reviews with three investor personas, an explicit
concurrent execution environment, and a fan-in barrier. Slide 77 demonstrates
real embeddings and cosine retrieval in an ephemeral in-memory vector store;
do not describe local storage as offline inference.

Part 1 spans slides 24-45; Part 2 spans 46-64. The remaining section dividers are
65 and 71. Exercises 301-304 are slides 66-69, Lab 300 is slide 70,
Part 4 exercises are 72-77, Lab 400 is slide 78, and the closing slide is 79. When inserting
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
