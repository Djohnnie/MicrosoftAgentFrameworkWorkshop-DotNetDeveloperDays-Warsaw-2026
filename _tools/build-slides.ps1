[CmdletBinding()]
param(
    [int[]]$OnlySlides
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$slides = Join-Path $root '_slides'
$resources = Join-Path $root '_resources'
[IO.Directory]::CreateDirectory($slides) | Out-Null

function DataUri([string]$path, [string]$mime) {
    "data:$mime;base64,$([Convert]::ToBase64String([IO.File]::ReadAllBytes($path)))"
}

$regular = DataUri (Join-Path $resources 'fonts\OpenSans-Regular.ttf') 'font/ttf'
$bold = DataUri (Join-Path $resources 'fonts\OpenSans-Bold.ttf') 'font/ttf'
$heading = DataUri (Join-Path $resources 'fonts\Raleway-Bold.ttf') 'font/ttf'
$logo = DataUri (Join-Path $resources 'developerdays-logo.png') 'image/png'
$speakerPhoto = DataUri (Join-Path $resources 'speaker-photo.jpg') 'image/jpeg'
$qrCode = DataUri (Join-Path $resources 'qrcode.svg') 'image/svg+xml'
$zureSvg = [IO.File]::ReadAllText((Join-Path $resources 'zure.svg')).Replace('currentColor', '#ffffff')
$zureLogo = "data:image/svg+xml;base64,$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($zureSvg)))"
$repoUrl = 'https://github.com/Djohnnie/MicrosoftAgentFrameworkWorkshop-DotNetDeveloperDays-Warsaw-2026'
$defs = @"
<defs>
  <clipPath id="speaker-photo-clip"><circle cx="360" cy="560" r="215"/></clipPath>
  <style>
    @font-face{font-family:'Open Sans';font-weight:400;src:url('$regular') format('truetype')}
    @font-face{font-family:'Open Sans';font-weight:700;src:url('$bold') format('truetype')}
    @font-face{font-family:Raleway;font-weight:700;src:url('$heading') format('truetype')}
    text{font-family:'Open Sans',sans-serif;fill:#cccccc}
    .heading{font-family:Raleway,sans-serif;font-weight:700;fill:#ffffff;letter-spacing:-2px}
    .label{font-size:20px;letter-spacing:3px;font-weight:700;fill:#ff6a3f}
    .agenda-time{font-weight:700;fill:#ff6a3f}
    .agenda-pause{fill:#a6a6a6}
    .accent{fill:#ff6a3f;font-weight:700}
    .muted{fill:#999999}
    .diagram-arrow{fill:none;stroke:#ff6a3f;stroke-width:4;marker-end:url(#arrowhead)}
  </style>
  <linearGradient id="accent" x1="0" y1="1" x2="1" y2="0">
    <stop stop-color="#bd0926"/><stop offset="1" stop-color="#ff6a3f"/>
  </linearGradient>
  <marker id="arrowhead" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto">
    <path d="M0 0L10 5L0 10Z" fill="#ff6a3f"/>
  </marker>
</defs>
"@

function Text([int]$x, [int]$y, [string]$value, [int]$size = 32, [string]$class = '') {
    '<text x="{0}" y="{1}" font-size="{2}" class="{3}">{4}</text>' -f $x, $y, $size, $class, [Security.SecurityElement]::Escape($value)
}

function Lines([int]$x, [int]$y, [string[]]$values, [int]$size = 32, [int]$gap = 52, [string]$class = '') {
    for ($i = 0; $i -lt $values.Count; $i++) {
        Text $x ($y + $i * $gap) $values[$i] $size $class
    }
}

function Card([int]$x, [int]$y, [int]$width, [int]$height) {
    @(
        "<rect x='$x' y='$y' width='$width' height='$height' rx='18' fill='#202020' stroke='#383838' stroke-width='2'/>"
        "<path d='M$($x + 18) $y H$($x + $width - 18)' stroke='url(#accent)' stroke-width='5'/>"
    ) -join "`n"
}

function ExerciseBody([string]$exerciseNumber, [string]$title, [string]$subtitle, [string]$projectPath, [string[]]$stepTitles, [string[][]]$stepDetails, [string]$takeaway, [string]$badge = 'EXERCISE') {
    if ($stepTitles.Count -ne 3 -or $stepDetails.Count -ne 3) {
        throw 'Exercise slides require exactly three steps.'
    }
    $exerciseUrl = "$repoUrl/tree/main/$($projectPath.Replace('\', '/'))"
    @(
        '<rect x="100" y="185" width="1720" height="280" rx="24" fill="#202020" stroke="#383838" stroke-width="2"/>'
        '<path d="M124 185 H1796" stroke="url(#accent)" stroke-width="6"/>'
        '<path d="M555 220 L510 430 M610 275 L655 320 L610 365 M470 275 L425 320 L470 365" fill="none" stroke="#444444" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>'
        '<text x="1775" y="248" text-anchor="end" font-size="20" class="label">HANDS-ON / YOUR TURN</text>'
        "<text x='1775' y='335' text-anchor='end' font-size='64' class='heading'>$([Security.SecurityElement]::Escape($title))</text>"
        "<text x='1775' y='401' text-anchor='end' font-size='27' fill='#cccccc'>$([Security.SecurityElement]::Escape($subtitle))</text>"
        '<rect x="130" y="235" width="250" height="170" rx="18" fill="url(#accent)"/>'
        "<text x=`"255`" y=`"282`" text-anchor=`"middle`" font-size=`"18`" font-weight=`"700`" style=`"fill:#ffffff;letter-spacing:3px`">$([Security.SecurityElement]::Escape($badge))</text>"
        "<text x='255' y='365' text-anchor='middle' font-size='76' class='heading'>$([Security.SecurityElement]::Escape($exerciseNumber))</text>"
        for ($i = 0; $i -lt 3; $i++) {
            $x = 100 + $i * 590
            (Card $x 510 540 230)
            "<circle cx='$($x + 48)' cy='563' r='22' fill='#3a2422' stroke='#ff6a3f'/>"
            "<text x='$($x + 48)' y='571' text-anchor='middle' font-size='21' class='accent'>$($i + 1)</text>"
            (Text ($x + 85) 574 $stepTitles[$i] 31 'heading')
            (Lines ($x + 30) 630 $stepDetails[$i] 24 40)
        }
        '<rect x="100" y="780" width="1720" height="70" rx="14" fill="#242424"/>'
        (Text 130 824 'OPEN' 18 'accent')
        "<a href='$exerciseUrl'>$(Text 220 825 $projectPath 26 'heading')</a>"
        (Text 1300 825 'dotnet run' 26)
        (Text 100 915 'TAKEAWAY' 18 'accent')
        (Text 255 915 $takeaway 24)
    ) -join "`n"
}

function SaveSlide([string]$name, [string]$title, [string]$description, [string]$body, [string]$number, [string]$section = 'MICROSOFT AGENT FRAMEWORK') {
    if ($OnlySlides.Count -gt 0 -and [int]($name -replace '\D', '') -notin $OnlySlides) {
        return
    }
    $safeTitle = [Security.SecurityElement]::Escape($title)
    $safeDescription = [Security.SecurityElement]::Escape($description)
    if ($number -eq '01') {
        $slideHeader = "<image x='1170' y='405' width='600' height='273' href='$logo'/>"
        $slideFooter = "<image x='1526' y='880' width='294' height='75' href='$zureLogo'/>"
    } else {
        $slideHeader = @(
            (Text 100 100 $section 20 'label')
            "<image x='1580' y='55' width='240' height='109' href='$logo'/>"
        ) -join "`n"
        $slideFooter = @(
            '<path d="M100 985H1820" stroke="#444444"/>'
            "<a href='$repoUrl'>$(Text 100 1030 'github.com/Djohnnie/MicrosoftAgentFrameworkWorkshop-DotNetDeveloperDays-Warsaw-2026' 24)</a>"
            "<text x='1820' y='1032' text-anchor='end' font-size='24' fill='#ffffff'>$number</text>"
            "<image x='1526' y='880' width='294' height='75' href='$zureLogo'/>"
        ) -join "`n"
    }
    $svg = @"
<?xml version="1.0" encoding="utf-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 1920 1080" role="img" aria-labelledby="title description">
<title id="title">$safeTitle</title>
<desc id="description">$safeDescription</desc>
$defs
<rect width="1920" height="1080" fill="#161616"/>
<rect width="1920" height="8" fill="url(#accent)"/>
$slideHeader
$body
$slideFooter
</svg>
"@
    [IO.File]::WriteAllText((Join-Path $slides $name), $svg, [Text.UTF8Encoding]::new($false))
}

$body = @(
    (Lines 100 335 @('Hands-on building GenAI enabled', '.NET applications using the', 'Microsoft Agent Framework') 58 78 'heading')
    '<rect x="100" y="590" width="180" height="8" fill="url(#accent)"/>'
    (Text 100 805 'Johnny Hooyberghs' 34 'heading')
    (Text 100 860 '.NET DeveloperDays / Warsaw / 2026' 26)
) -join "`n"
SaveSlide 'slide-01.svg' 'Hands-on building GenAI enabled .NET applications using the Microsoft Agent Framework' 'Workshop opening slide for hands-on building GenAI-enabled .NET applications using the Microsoft Agent Framework at .NET DeveloperDays Warsaw 2026.' $body '01' 'MICROSOFT AGENT FRAMEWORK'

$body = @(
    (Text 100 245 'Johnny Hooyberghs' 72 'heading')
    "<image x='145' y='345' width='430' height='430' preserveAspectRatio='xMidYMid slice' clip-path='url(#speaker-photo-clip)' href='$speakerPhoto'/>"
    '<circle cx="360" cy="560" r="215" fill="none" stroke="#bd0926" stroke-width="3"/>'
    '<circle cx="750" cy="340" r="7" fill="#ff6a3f"/>'
    (Text 780 350 'Azure Architect at Zure' 34)
    '<circle cx="750" cy="419" r="7" fill="#ff6a3f"/>'
    (Lines 780 429 @('Focus on .NET application development,', 'Azure cloud, and generative AI') 34 44)
    '<circle cx="750" cy="542" r="7" fill="#ff6a3f"/>'
    (Lines 780 552 @('18 years of professional experience', 'as a software enthusiast') 34 44)
    '<circle cx="750" cy="665" r="7" fill="#ff6a3f"/>'
    (Lines 780 675 @('Microsoft MVP in Developer Technologies', 'and Azure since 2020') 34 44)
    '<circle cx="750" cy="788" r="7" fill="#ff6a3f"/>'
    (Text 780 798 'Public speaker and trainer' 34)
) -join "`n"
SaveSlide 'slide-02.svg' 'Johnny Hooyberghs' 'Speaker introduction with photo, professional background, and interests.' $body '02' 'ABOUT THE SPEAKER'

$body = @(
    (Text 100 245 'Explore the workshop materials.' 68 'heading')
    (Text 100 315 'Scan to open the Microsoft Agent Framework workshop repository' 30)
    "<a href='$repoUrl'><image x='690' y='370' width='540' height='540' href='$qrCode'/></a>"
) -join "`n"
SaveSlide 'slide-03.svg' 'Explore the workshop materials' 'QR code linking to the Microsoft Agent Framework workshop repository.' $body '03' 'FOLLOW ALONG'

$agenda = @(
    [pscustomobject]@{ Time = '09:00 - 09:30'; Topic = 'Introduction to GenAI' }
    [pscustomobject]@{ Time = '09:30 - 11:00'; Topic = 'Part 1: From LLM calls to agents' }
    [pscustomobject]@{ Time = '11:00 - 11:15'; Topic = 'Break' }
    [pscustomobject]@{ Time = '11:15 - 13:00'; Topic = 'Part 2: Giving agents capabilities: tools and MCP' }
    [pscustomobject]@{ Time = '13:00 - 13:45'; Topic = 'Lunch' }
    [pscustomobject]@{ Time = '13:45 - 15:15'; Topic = 'Part 3: Orchestrating agents and workflows' }
    [pscustomobject]@{ Time = '15:15 - 15:30'; Topic = 'Break' }
    [pscustomobject]@{ Time = '15:45 - 17:00'; Topic = 'Part 4: Making agents reliable and production-ready' }
)
$bodyParts = [Collections.Generic.List[string]]::new()
$bodyParts.Add((Text 100 245 'Full-day workshop agenda' 68 'heading'))
$bodyParts.Add('<rect x="100" y="280" width="180" height="8" fill="url(#accent)"/>')
for ($i = 0; $i -lt $agenda.Count; $i++) {
    $y = 365 + $i * 70
    $rowClass = if ($agenda[$i].Topic -in @('Break', 'Lunch')) { 'agenda-pause' } else { '' }
    $bodyParts.Add((Text 130 $y $agenda[$i].Time 29 'agenda-time'))
    $bodyParts.Add((Text 460 $y $agenda[$i].Topic 29 $rowClass))
    if ($i -lt $agenda.Count - 1) {
        $ruleY = $y + 25
        $bodyParts.Add("<path d='M100 $ruleY H1450' stroke='#333333'/>")
    }
}
$body = $bodyParts -join "`n"
SaveSlide 'slide-04.svg' 'Full-day workshop agenda' 'Agenda and timings for the full-day Microsoft Agent Framework workshop.' $body '04' 'WORKSHOP AGENDA'

$body = @(
    (Text 100 235 'From hand-written rules to systems that create' 48 'heading')
    (Text 100 282 'Each shift made AI more capable by learning richer patterns from data.' 27)
    (Card 100 365 390 340)
    (Text 130 425 '01 / RULES' 20 'accent')
    (Text 130 495 'Rules-based' 35 'heading')
    (Lines 130 555 @('People define the logic.', 'Predictable, but brittle.') 25 40)
    '<path d="M490 535 H525" class="diagram-arrow"/>'
    (Card 535 365 390 340)
    (Text 565 425 '02 / DATA' 20 'accent')
    (Text 565 495 'Machine learning' 33 'heading')
    (Lines 565 555 @('Models learn patterns', 'from examples.') 25 40)
    '<path d="M925 535 H960" class="diagram-arrow"/>'
    (Card 970 365 390 340)
    (Text 1000 425 '03 / SCALE' 20 'accent')
    (Text 1000 495 'Deep learning' 35 'heading')
    (Lines 1000 555 @('Neural networks learn', 'richer representations.') 25 40)
    '<path d="M1360 535 H1395" class="diagram-arrow"/>'
    (Card 1405 365 390 340)
    (Text 1435 425 '04 / GENERATION' 20 'accent')
    (Text 1435 495 'Generative AI' 35 'heading')
    (Lines 1435 555 @('Models create new text,', 'images, audio, and code.') 25 40)
    (Text 100 795 'A progression of techniques—not a replacement of every earlier kind of AI.' 25 'muted')
) -join "`n"
SaveSlide 'slide-06.svg' 'The evolution of AI' 'A concise progression from rules-based systems through machine learning and deep learning to generative AI.' $body '06' 'THE EVOLUTION OF AI'

$body = @(
    (Text 100 235 'Different learning signals lead to different capabilities' 46 'heading')
    (Card 100 340 535 420)
    (Text 135 405 'SUPERVISED' 21 'accent')
    (Text 135 475 'Learn from labeled examples' 32 'heading')
    (Lines 135 540 @('Input + known answer -> learned mapping', 'Examples: spam detection, image labels') 24 48)
    (Text 135 690 'FEEDBACK: correct answers' 19 'muted')
    (Card 692 340 535 420)
    (Text 727 405 'UNSUPERVISED' 21 'accent')
    (Text 727 475 'Find structure in data' 32 'heading')
    (Lines 727 540 @('Discover patterns without answer labels', 'Examples: clustering, anomaly detection') 24 48)
    (Text 727 690 'FEEDBACK: patterns in data' 19 'muted')
    (Card 1284 340 535 420)
    (Text 1319 405 'REINFORCEMENT' 21 'accent')
    (Text 1319 475 'Learn by trial and reward' 32 'heading')
    (Lines 1319 540 @('Actions change an environment; feedback', 'rewards outcomes over time') 24 48)
    (Text 1319 690 'FEEDBACK: rewards / penalties' 19 'muted')
    (Text 100 820 'Same broad field, different objectives and feedback loops.' 25 'muted')
) -join "`n"
SaveSlide 'slide-07.svg' 'Types of machine learning' 'Supervised, unsupervised, and reinforcement learning compared by objective and feedback.' $body '07' 'TYPES OF MACHINE LEARNING'

$body = @(
    (Text 100 235 'An agent improves through repeated interaction' 48 'heading')
    (Card 720 310 480 145)
    (Text 760 370 'AGENT' 22 'accent')
    (Text 760 420 'Chooses an action' 30 'heading')
    (Card 1260 485 450 145)
    (Text 1300 545 'ACTION' 22 'accent')
    (Text 1300 600 'Changes the state' 28 'heading')
    (Card 720 665 480 145)
    (Text 760 725 'ENVIRONMENT' 22 'accent')
    (Text 760 780 'Returns a new state' 28 'heading')
    (Card 210 485 450 145)
    (Text 250 545 'REWARD' 22 'accent')
    (Text 250 600 'Scores the outcome' 28 'heading')
    '<path d="M1180 390 Q1315 405 1390 480" class="diagram-arrow"/>'
    '<path d="M1485 640 Q1370 730 1215 738" class="diagram-arrow"/>'
    '<path d="M710 740 Q590 720 545 640" class="diagram-arrow"/>'
    '<path d="M430 480 Q520 375 700 380" class="diagram-arrow"/>'
    (Text 100 860 'The reward signal updates the policy, shaping what the agent tries next.' 24 'muted')
) -join "`n"
SaveSlide 'slide-08.svg' 'The reinforcement loop' 'An agent acts in an environment, receives feedback, and uses rewards to improve future choices.' $body '08' 'THE REINFORCEMENT LOOP'

$body = @(
    (Text 100 235 'AI is a broad family of techniques—not one product' 46 'heading')
    (Card 100 325 1720 125)
    (Text 140 385 'ARTIFICIAL INTELLIGENCE' 23 'accent')
    (Text 570 385 'Systems that perform tasks associated with human intelligence' 26)
    (Card 100 500 400 220)
    (Text 130 560 'PREDICTION' 20 'accent')
    (Lines 130 615 @('Forecasting', 'Fraud detection') 26 42)
    (Card 540 500 400 220)
    (Text 570 560 'PERCEPTION' 20 'accent')
    (Lines 570 615 @('Computer vision', 'Speech recognition') 26 42)
    (Card 980 500 400 220)
    (Text 1010 560 'RECOMMENDATION' 20 'accent')
    (Lines 1010 615 @('Ranking', 'Personalization') 26 42)
    (Card 1420 500 400 220)
    (Text 1450 560 'GENERATION' 20 'accent')
    (Lines 1450 615 @('Text and code', 'Images and audio') 26 42)
    '<path d="M1620 720 V770 H960" class="diagram-arrow"/>'
    (Card 685 785 550 90)
    (Text 725 842 'LLMs are one kind of generative AI model.' 26 'heading')
) -join "`n"
SaveSlide 'slide-09.svg' 'AI is not one thing' 'AI includes many distinct capabilities; large language models are one type of generative AI model.' $body '09' 'AI IS NOT ONE THING'

$body = @(
    (Text 100 235 'A model is a learned mapping from input to output' 47 'heading')
    (Text 100 300 'Training finds parameters that capture useful patterns from examples.' 27)
    (Text 100 375 'TRAINING' 20 'accent')
    (Card 100 405 450 135)
    (Text 135 465 'Training examples' 30 'heading')
    '<path d="M550 470 H705" class="diagram-arrow"/>'
    (Card 720 405 450 135)
    (Text 755 465 'Learning algorithm' 30 'heading')
    '<path d="M1170 470 H1325" class="diagram-arrow"/>'
    (Card 1340 405 480 135)
    (Text 1375 465 'Trained model' 30 'heading')
    (Text 100 615 'IN USE' 20 'accent')
    (Card 100 655 450 135)
    (Text 135 715 'New input' 30 'heading')
    '<path d="M550 720 H705" class="diagram-arrow"/>'
    (Card 720 655 450 135)
    (Text 755 715 'Model applies patterns' 27 'heading')
    '<path d="M1170 720 H1325" class="diagram-arrow"/>'
    (Card 1340 655 480 135)
    (Text 1375 715 'Prediction or generation' 26 'heading')
    (Text 100 850 'An LLM is a model specialized in generating language token by token.' 24 'muted')
) -join "`n"
SaveSlide 'slide-10.svg' 'What is a model?' 'A model is a trained system that applies learned patterns to map new inputs to predictions or generated outputs.' $body '10' 'WHAT IS A MODEL?'

$body = @(
    (Text 100 235 'An LLM repeatedly predicts what token comes next' 46 'heading')
    (Text 100 300 'It processes a sequence of token representations and generates one continuation at a time.' 26)
    (Card 100 390 300 240)
    (Text 130 445 '01 / INPUT' 19 'accent')
    (Lines 130 505 @('Your prompt', 'arrives as text.') 25 43)
    '<path d="M400 510 H430" class="diagram-arrow"/>'
    (Card 445 390 300 240)
    (Text 475 445 '02 / TOKENS' 19 'accent')
    (Lines 475 505 @('Text is split', 'into token IDs.') 25 43)
    '<path d="M745 510 H775" class="diagram-arrow"/>'
    (Card 790 390 300 240)
    (Text 820 445 '03 / EMBEDDINGS' 19 'accent')
    (Lines 820 505 @('IDs become', 'vectors the model', 'can process.') 25 43)
    '<path d="M1090 510 H1120" class="diagram-arrow"/>'
    (Card 1135 390 300 240)
    (Text 1165 445 '04 / PREDICT' 19 'accent')
    (Lines 1165 505 @('The model scores', 'possible next', 'tokens.') 25 43)
    '<path d="M1435 510 H1465" class="diagram-arrow"/>'
    (Card 1480 390 300 240)
    (Text 1510 445 '05 / SAMPLE' 19 'accent')
    (Lines 1510 505 @('One token is', 'selected and', 'appended.') 25 43)
    '<path d="M1630 640 V715 H250 V650" class="diagram-arrow"/>'
    (Text 100 785 'Repeat this loop until the model reaches a stopping condition.' 26 'heading')
    (Text 100 835 'Token counts—not words or lines—shape context limits and usage.' 23 'muted')
) -join "`n"
SaveSlide 'slide-11.svg' 'How LLMs work' 'Large language models tokenize input and generate output by repeatedly predicting and selecting the next token.' $body '11' 'HOW LLMS WORK'

$body = ExerciseBody -exerciseNumber '001' -title 'Tokenization demo' `
    -subtitle 'See how a language model reads your text and code.' `
    -projectPath 'exercises\exercise-001' `
    -stepTitles @('Configure', 'Run', 'Explore') `
    -stepDetails @(
        ,@('Set FOUNDRY_ENDPOINT,', 'FOUNDRY_API_KEY, and', 'FOUNDRY_MODEL_DEPLOYMENT.')
        ,@('Start the Token Visualizer console app.', 'Send a message; inspect its tokens.')
        ,@('Compare local counts with API usage.', 'Full history counts toward input;', 'type clear to reset; quit to exit.')
    ) `
    -takeaway 'Tokens shape context size and cost. Wording and formatting matter.'
SaveSlide 'slide-12.svg' 'Exercise 001: Tokenization demo' 'Hands-on exercise 001: configure Microsoft Foundry, run the Token Visualizer, and explore token streams and usage. Open exercises\exercise-001.' $body '12' 'EXERCISE 001'

$body = @(
    (Text 100 235 'Fluent output is not the same as verified truth' 48 'heading')
    (Card 100 340 535 315)
    (Text 135 400 '01 / OBJECTIVE' 20 'accent')
    (Text 135 465 'Predict likely text' 32 'heading')
    (Lines 135 530 @('The model generates what fits', 'the context—not a fact-check.') 25 43)
    (Card 692 340 535 315)
    (Text 727 400 '02 / CONTEXT' 20 'accent')
    (Text 727 465 'Gaps invite guesses' 32 'heading')
    (Lines 727 530 @('Missing or stale information', 'can produce plausible errors.') 25 43)
    (Card 1284 340 535 315)
    (Text 1319 400 '03 / CONFIDENCE' 20 'accent')
    (Text 1319 465 'Style can mislead' 32 'heading')
    (Lines 1319 530 @('A confident tone does not', 'measure whether a claim is true.') 25 43)
    (Text 100 730 'Reduce risk' 25 'accent')
    (Text 100 785 'Ground answers in evidence  •  Verify important claims  •  Use tools for current facts' 25 'heading')
    (Text 100 845 'Human review remains essential when accuracy or safety matters.' 23 'muted')
) -join "`n"
SaveSlide 'slide-13.svg' 'Why LLMs hallucinate' 'LLMs optimize for plausible continuations rather than verified facts; missing context and misleading confidence increase risk.' $body '13' 'WHY LLMS HALLUCINATE'

$body = @(
    (Text 100 235 'Give the model relevant knowledge at answer time' 47 'heading')
    (Text 100 300 'Retrieval-Augmented Generation (RAG) connects a language model to trusted information.' 26)
    (Card 100 405 460 240)
    (Text 135 465 '01 / ASK' 20 'accent')
    (Lines 135 525 @('User question', 'and intent') 28 46)
    '<path d="M560 525 H690" class="diagram-arrow"/>'
    (Card 705 405 460 240)
    (Text 740 465 '02 / RETRIEVE' 20 'accent')
    (Lines 740 525 @('Search relevant', 'documents / chunks') 28 46)
    '<path d="M1165 525 H1295" class="diagram-arrow"/>'
    (Card 1310 405 510 240)
    (Text 1345 465 '03 / GENERATE' 20 'accent')
    (Lines 1345 525 @('Use retrieved context', 'to draft an answer') 28 46)
    '<path d="M1590 650 V720 H930" class="diagram-arrow"/>'
    (Card 625 740 650 105)
    (Text 665 805 'Answer with evidence in the model context.' 27 'heading')
    (Text 100 885 'RAG adds context; quality depends on retrieval, source trust, and generation.' 22 'muted')
) -join "`n"
SaveSlide 'slide-14.svg' 'RAG: giving an LLM the right knowledge' 'Retrieval-augmented generation retrieves relevant external information and adds it to the model context before answering.' $body '14' 'RAG: GIVING AN LLM THE RIGHT KNOWLEDGE'

$body = @(
    (Text 100 235 'Agents move from answering to pursuing a goal' 47 'heading')
    (Card 100 340 750 420)
    (Text 140 400 'CHATBOT' 21 'accent')
    (Text 140 475 'Responds to a prompt' 34 'heading')
    (Lines 140 555 @('- Answers a question', '- Usually one turn at a time', '- No action unless connected to tools') 25 55)
    (Card 970 340 850 420)
    (Text 1010 400 'AGENT' 21 'accent')
    (Text 1010 475 'Works toward an outcome' 34 'heading')
    (Lines 1010 555 @('- Interprets a goal and current state', '- Chooses tools or actions', '- Observes results and continues') 25 55)
    '<path d="M850 550 H950" class="diagram-arrow"/>'
    (Text 100 820 'Agents can use chat, but add decision-making and action around the model.' 25 'muted')
) -join "`n"
SaveSlide 'slide-15.svg' 'Beyond chatbots' 'An agent extends conversational AI with goal-directed decisions, tools, actions, and feedback from results.' $body '15' 'BEYOND CHATBOTS'

$body = @(
    (Text 100 235 'Coordinate focused agents around a shared outcome' 46 'heading')
    (Card 690 315 540 140)
    (Text 730 375 'ORCHESTRATOR' 21 'accent')
    (Text 730 425 'Routes work and manages handoffs' 27 'heading')
    '<path d="M960 455 V505 H355 V540" class="diagram-arrow"/>'
    '<path d="M960 455 V540" class="diagram-arrow"/>'
    '<path d="M960 505 H1565 V540" class="diagram-arrow"/>'
    (Card 100 550 510 205)
    (Text 135 610 'PLANNER' 20 'accent')
    (Lines 135 665 @('Breaks a goal into', 'clear tasks.') 25 42)
    (Card 705 550 510 205)
    (Text 740 610 'RESEARCHER' 20 'accent')
    (Lines 740 665 @('Finds relevant facts', 'and context.') 25 42)
    (Card 1310 550 510 205)
    (Text 1345 610 'BUILDER / REVIEWER' 20 'accent')
    (Lines 1345 665 @('Creates a result and', 'checks it against needs.') 25 42)
    '<path d="M355 755 V800 H960 M960 755 V800 M1565 755 V800 H960 V810" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Text 100 850 'Specialize, coordinate, and keep people in control of consequential actions.' 23 'muted')
) -join "`n"
SaveSlide 'slide-16.svg' 'Agent orchestration' 'Orchestration coordinates specialized agents, routes tasks, and manages handoffs toward a shared goal.' $body '16' 'AGENT ORCHESTRATION'

$body = @(
    (Text 100 225 'A framework for building production-grade agents and workflows' 43 'heading')
    (Text 100 275 'Build individual AI agents, then connect them to tools, services, and each other.' 26)
    (Card 100 345 400 360)
    (Text 135 405 'AGENTS' 21 'accent')
    (Lines 135 470 @('Use models to process', 'requests, call tools or', 'MCP servers, and respond.') 24 44)
    (Card 535 345 400 360)
    (Text 570 405 'HARNESS AGENT' 21 'accent')
    (Lines 570 470 @('Support long tasks with', 'planning, memory, file', 'access, and approvals.') 24 44)
    (Card 970 345 400 360)
    (Text 1005 405 'WORKFLOWS' 21 'accent')
    (Lines 1005 470 @('Connect agents and', 'functions through explicit', 'execution paths.') 24 44)
    (Card 1405 345 415 360)
    (Text 1440 405 'INTEGRATIONS' 21 'accent')
    (Lines 1440 470 @('Connect model providers,', 'tools, context, middleware,', 'evaluation, and UI.') 24 44)
    (Text 100 785 'Build in .NET and Python with provider choice, state, middleware, and observability.' 25 'heading')
    "<a href='https://learn.microsoft.com/en-us/agent-framework/overview/?pivots=programming-language-csharp'>$(Text 100 880 'Source: Microsoft Learn overview' 20 'muted')</a>"
    "<a href='https://github.com/microsoft/agent-framework/blob/main/README.md'>$(Text 460 880 'Microsoft Agent Framework on GitHub' 20 'muted')</a>"
) -join "`n"
SaveSlide 'slide-17.svg' 'What is Microsoft Agent Framework?' 'Microsoft Agent Framework brings together agents, harness agents, workflows, and integrations to build production-grade AI applications.' $body '17' 'WHAT IS MICROSOFT AGENT FRAMEWORK?'

$body = @(
    (Text 100 230 'Choose the simplest pattern that fits the task' 48 'heading')
    (Card 100 335 790 390)
    (Text 145 400 'USE AN AGENT WHEN' 21 'accent')
    (Lines 145 475 @('The task is open-ended or conversational.', 'The model needs to plan and choose tools.', 'One model call, possibly with tools, is enough.') 27 74)
    (Card 1030 335 790 390)
    (Text 1075 400 'USE A WORKFLOW WHEN' 21 'accent')
    (Lines 1075 475 @('The process follows well-defined steps.', 'You need explicit control over execution order.', 'Multiple agents or functions must coordinate.') 27 74)
    (Text 100 805 'If a regular function can handle the task, use the function.' 29 'heading')
    "<a href='https://learn.microsoft.com/en-us/agent-framework/overview/?pivots=programming-language-csharp'>$(Text 100 880 'Source: Microsoft Learn overview' 20 'muted')</a>"
    "<a href='https://github.com/microsoft/agent-framework/blob/main/README.md'>$(Text 460 880 'Microsoft Agent Framework on GitHub' 20 'muted')</a>"
) -join "`n"
SaveSlide 'slide-18.svg' 'Agents or workflows?' 'Use an agent for open-ended tasks that need autonomous planning; use a workflow for defined steps that need explicit execution control.' $body '18' 'AGENTS OR WORKFLOWS?'

$sections = @(
    [pscustomobject]@{ Title = 'Part 1'; Subtitle = 'From LLM calls to agents'; Time = '09:30 - 11:00' }
    [pscustomobject]@{ Title = 'Part 2'; Subtitle = 'Giving agents capabilities: tools and MCP'; Time = '11:15 - 13:00' }
    [pscustomobject]@{ Title = 'Part 3'; Subtitle = 'Orchestrating agents and workflows'; Time = '13:45 - 15:15' }
    [pscustomobject]@{ Title = 'Part 4'; Subtitle = 'Making agents reliable and production-ready'; Time = '15:45 - 17:00' }
)
for ($i = 0; $i -lt $sections.Count; $i++) {
    $section = $sections[$i]
    $slideNumber = $i + 19 + 7 * [int]($i -gt 0) + 5 * [int]($i -gt 1)
    $displayTitle = $section.Title.ToUpperInvariant()
    $body = @(
        (Text 100 435 $displayTitle 76 'heading')
        '<rect x="100" y="485" width="180" height="8" fill="url(#accent)"/>'
        (Text 100 570 $section.Subtitle 50)
        (Text 100 660 $section.Time 28 'agenda-time')
    ) -join "`n"
    SaveSlide ("slide-{0:D2}.svg" -f $slideNumber) "$($section.Title): $($section.Subtitle)" "Section divider for $($section.Title), $($section.Subtitle), scheduled $($section.Time)." $body ("{0:D2}" -f $slideNumber) 'Hands-on building GenAI enabled .NET applications using the Microsoft Agent Framework'

    if ($i -eq 0) {
        $body = ExerciseBody -exerciseNumber '101' -title 'Simple Chatbot' `
            -subtitle 'Talk to a language model, one message at a time.' `
            -projectPath 'exercises\exercise-101' `
            -stepTitles @('Configure', 'Chat', 'Observe') `
            -stepDetails @(
                ,@('Use the Foundry settings from', 'exercise 001.')
                ,@('Use IChatClient.GetResponseAsync;', 'print response.Text.')
                ,@('Try a follow-up. The model', 'does not know earlier turns.')
            ) `
            -takeaway 'A direct model call with only the current message; no agent or conversation history.'
        SaveSlide 'slide-20.svg' 'Exercise 101: Simple Chatbot' 'Part 1 exercise 101: chat with a Foundry model through independent requests that do not retain conversation history. Open exercises\exercise-101.' $body '20' 'EXERCISE 101'

        $body = ExerciseBody -exerciseNumber '102' -title 'Chatbot with History' `
            -subtitle 'Give each follow-up the conversation so far.' `
            -projectPath 'exercises\exercise-102' `
            -stepTitles @('Keep', 'Append', 'Compare') `
            -stepDetails @(
                ,@('Keep a List<ChatMessage>', 'outside the conversation loop.')
                ,@('Add the user message, call', 'GetResponseAsync(history), then', 'append response.Messages.')
                ,@('Try a follow-up, then compare', 'with exercise 101. Restart', 'the app to discard history.')
            ) `
            -takeaway 'Send the full conversation on every request; more history means more input tokens.'
        SaveSlide 'slide-21.svg' 'Exercise 102: Chatbot with History' 'Part 1 exercise 102: retain user messages and assistant replies and send the full conversation with every request. Open exercises\exercise-102.' $body '21' 'EXERCISE 102'

        $body = ExerciseBody -exerciseNumber '103' -title 'Chatbot Personas' `
            -subtitle 'Change the age persona with each question.' `
            -projectPath 'exercises\exercise-103' `
            -stepTitles @('Define', 'Include', 'Compare') `
            -stepDetails @(
                ,@('Start at age 10; put the age', 'in a system prompt template.')
                ,@('Replace the system message;', 'keep the conversation history.')
                ,@('Lower the age by 2 per reply:', '10, 8, 6, 4, 2, 0. Stay at 0.', 'Compare vocabulary and tone.')
            ) `
            -takeaway 'A system prompt guides style and behavior; it does not change the model or ensure facts.'
        SaveSlide 'slide-22.svg' 'Exercise 103: Chatbot Personas' 'Part 1 exercise 103: update the system persona from age 10 down to 0 in steps of 2, staying at 0 and retaining conversation history. Open exercises\exercise-103.' $body '22' 'EXERCISE 103'

        $body = ExerciseBody -exerciseNumber '104' -title 'Structured Output' `
            -subtitle 'Generate a typed employee instead of free-form text.' `
            -projectPath 'exercises\exercise-104' `
            -stepTitles @('Define', 'Generate', 'Inspect') `
            -stepDetails @(
                ,@('Create an Employee record:', 'name, first name, birth date,', 'salary, and function title.')
                ,@('Use GetResponseAsync<Employee>', 'with JSON-schema output;', 'choose a supporting deployment.')
                ,@('Read the typed result; compare', 'employees from different prompts.')
            ) `
            -takeaway 'The C# type defines the output shape; application code still validates the values.'
        SaveSlide 'slide-23.svg' 'Exercise 104: Structured Output' 'Part 1 exercise 104: use a generic structured-output call to generate an Employee with name, first name, birth date, salary, and function title. Open exercises\exercise-104.' $body '23' 'EXERCISE 104'

        $body = ExerciseBody -exerciseNumber '105' -title 'Local Ollama Chatbot' `
            -subtitle 'Keep the chat loop; run the model on your machine.' `
            -projectPath 'exercises\exercise-105' `
            -stepTitles @('Prepare', 'Connect', 'Compare') `
            -stepDetails @(
                ,@('Start Ollama and download:', 'ollama pull qwen2.5:7b')
                ,@('Use OllamaApiClient as IChatClient', 'at http://localhost:11434.')
                ,@('Keep the history from 102.', 'Compare local and cloud replies;', 'no Foundry credentials needed.')
            ) `
            -takeaway 'IChatClient lets you change providers while keeping the same conversation code.'
        SaveSlide 'slide-24.svg' 'Exercise 105: Local Ollama Chatbot' 'Part 1 exercise 105: use a local qwen2.5:7b model through Ollama and keep the IChatClient conversation history from exercise 102. Open exercises\exercise-105.' $body '24' 'EXERCISE 105'

        $body = ExerciseBody -exerciseNumber '106' -title 'Chatbot Agent' `
            -subtitle 'Give an agent instructions and a conversation session.' `
            -projectPath 'exercises\exercise-106' `
            -stepTitles @('Create', 'Instruct', 'Inspect') `
            -stepDetails @(
                ,@('AsAIAgent with', 'ChatClientAgentOptions and', 'InMemoryChatHistoryProvider.')
                ,@('ChatOptions: cheerful age 10;', 'RawRepresentationFactory sets', 'StoredOutputEnabled = false.')
                ,@('Reuse one session in RunAsync.', 'DebugHistory reads local messages', 'with TryGetInMemoryChatHistory.')
            ) `
            -takeaway 'The agent keeps history in a local session; each model call still sends it to Foundry.'
        SaveSlide 'slide-25.svg' 'Exercise 106: Chatbot Agent' 'Part 1 exercise 106: use ChatClientAgentOptions with InMemoryChatHistoryProvider and ChatOptions.Instructions for a fixed cheerful age-10 persona. RawRepresentationFactory sets CreateResponseOptions.StoredOutputEnabled=false. Reuse one AgentSession; DebugHistory inspects actual local messages with TryGetInMemoryChatHistory after each reply. Open exercises\exercise-106.' $body '25' 'EXERCISE 106'

        $body = ExerciseBody -exerciseNumber '100' -badge 'LAB' -title 'DevDays Buddy' `
            -subtitle 'An agent that knows the conference agenda.' `
            -projectPath 'labs\lab-100' `
            -stepTitles @('Embed', 'Ground', 'Spice up') `
            -stepDetails @(
                ,@('Embed agenda.json: days, times,', 'sessions, and speakers. Read it', 'with GetManifestResourceStream.')
                ,@('Put the JSON in the agent', 'instructions; reuse one session', 'for follow-up questions.')
                ,@('Use Spectre.Console: banner,', 'spinner, answer panels, and', 'an agenda table.')
            ) `
            -takeaway 'Context in the instructions grounds answers, but the whole agenda is sent every time.'
        SaveSlide 'slide-26.svg' 'Lab 100: DevDays Buddy' 'Part 1 lab 100: embed the .NET DeveloperDays Warsaw 2026 agenda as agenda.json, add it to the agent instructions as context, answer attendee questions with one AgentSession, and use Spectre.Console for the UI. Starter and solution in labs\lab-100.' $body '26' 'LAB 100'
    }

    if ($i -eq 1) {
        $body = ExerciseBody -exerciseNumber '201' -title 'Chatbot Agent with Tools' `
            -subtitle 'Use an agent that can call C# functions for current date and time.' `
            -projectPath 'exercises\exercise-201' `
            -stepTitles @('Define', 'Enable', 'Ask') `
            -stepDetails @(
                ,@('Create separate functions for', 'the current local time and date.')
                ,@('Add both to agent ChatOptions;', 'UseFunctionInvocation runs', 'the selected function.')
                ,@('Reuse one AgentSession for', 'conversation history and ask for', 'the current date or time.')
            ) `
            -takeaway 'AIAgent manages conversation state; the model chooses a tool and application code executes it.'
        SaveSlide 'slide-28.svg' 'Exercise 201: Chatbot Agent with Tools' 'Part 2 exercise 201: create an AIAgent around the Foundry chat client, use an AgentSession for history, disable server-side Responses storage, and expose current-time and current-date functions as tools executed by UseFunctionInvocation. Open exercises\exercise-201.' $body '28' 'EXERCISE 201'

        $body = ExerciseBody -exerciseNumber '202' -title 'Local Chatbot with Tools' `
            -subtitle 'Use the local Ollama model to ask C# functions for current date and time.' `
            -projectPath 'exercises\exercise-202' `
            -stepTitles @('Prepare', 'Create agent', 'Ask') `
            -stepDetails @(
                ,@('Start Ollama and download:', 'ollama pull qwen2.5:7b')
                ,@('Add the date and time tools;', 'reuse one AgentSession for', 'conversation history.')
                ,@('Ask for current values.', 'The local model can select a tool;', 'no Foundry credentials needed.')
            ) `
            -takeaway 'AIAgent manages local conversation history while function invocation executes the selected tool.'
        SaveSlide 'slide-29.svg' 'Exercise 202: Local Chatbot with Tools' 'Part 2 exercise 202: use AIAgent with an OllamaSharp client and AgentSession, exposing functions for current local time and date. No Foundry credentials or cloud inference are needed. Open exercises\exercise-202.' $body '29' 'EXERCISE 202'

        $body = ExerciseBody -exerciseNumber '203' -title 'Dependency Injection for Tools' `
            -subtitle 'Resolve a tool dependency through the agent service provider.' `
            -projectPath 'exercises\exercise-203' `
            -stepTitles @('Register', 'Connect', 'Invoke') `
            -stepDetails @(
                ,@('Register TimeProvider in a', 'ServiceCollection container.')
                ,@('Pass the ServiceProvider to', 'AsAIAgent; omit middleware.')
                ,@('Resolve the clock inside the', 'tool method and query the', 'current date or time.')
            ) `
            -takeaway 'AsAIAgent passes services to tool invocation when the agent creates that pipeline.'
        SaveSlide 'slide-30.svg' 'Exercise 203: Dependency Injection for Tools' 'Part 2 exercise 203: register TimeProvider in a dependency injection container, receive IServiceProvider in tool methods, pass the provider to AsAIAgent for function invocation, and disable server-side Responses storage to keep history in the local session. Open exercises\exercise-203.' $body '30' 'EXERCISE 203'

        $body = ExerciseBody -exerciseNumber '204' -title 'Microsoft Learn MCP Agent' `
            -subtitle 'Discover remote documentation tools and use them in a conversation.' `
            -projectPath 'exercises\exercise-204' `
            -stepTitles @('Connect', 'Discover', 'Ask') `
            -stepDetails @(
                ,@('Connect to the public Learn MCP', 'server over Streamable HTTP.')
                ,@('List tools; print their names', 'and descriptions for the user.')
                ,@('Ask a documentation question.', 'The agent can invoke MCP tools', 'and show calls in history.')
            ) `
            -takeaway 'MCP exposes remote capabilities through a standard client and callable agent tools.'
        SaveSlide 'slide-31.svg' 'Exercise 204: Microsoft Learn MCP Agent' 'Part 2 exercise 204: connect to https://learn.microsoft.com/api/mcp with the MCP C# SDK, list and describe available tools, then provide them to an AIAgent for a documentation conversation. DebugHistory displays tool calls and results. Open exercises\exercise-204.' $body '31' 'EXERCISE 204'

        $body = ExerciseBody -exerciseNumber '205' -title 'Host Date and Time MCP Tools' `
            -subtitle 'Publish local functions from ASP.NET and call them remotely.' `
            -projectPath 'exercises\exercise-205' `
            -stepTitles @('Host', 'Discover', 'Invoke') `
            -stepDetails @(
                ,@('Inject TimeProvider into the', 'ASP.NET MCP server tool class.')
                ,@('Connect the console MCP client;', 'list the server-provided tools.')
                ,@('Ask the Foundry agent for', 'the date or time; inspect calls', 'and results in session history.')
            ) `
            -takeaway 'MCP lets a console agent call DI-backed tools hosted by a separate ASP.NET process.'
        SaveSlide 'slide-32.svg' 'Exercise 205: Host Date and Time MCP Tools' 'Part 2 exercise 205: host the current date and time MCP tools in a standalone ASP.NET Core server, inject TimeProvider into the tool class, and discover and call them from a separate console AIAgent client over Streamable HTTP. Open exercises\exercise-205.' $body '32' 'EXERCISE 205'
    }
}

$body = @(
    (Text 100 245 'Any questions?' 72 'heading')
    (Text 100 315 'Continue exploring the workshop materials' 30)
    "<a href='$repoUrl'><image x='690' y='370' width='540' height='540' href='$qrCode'/></a>"
) -join "`n"
SaveSlide 'slide-35.svg' 'Any questions?' 'Questions about the Microsoft Agent Framework workshop. Scan the QR code to open the workshop repository.' $body '35' 'THANK YOU'

Write-Host "Built selected slides in $slides"
