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

function ExerciseBody([string]$exerciseNumber, [string]$title, [string]$subtitle, [string]$projectPath, [string[]]$stepTitles, [string[][]]$stepDetails, [string]$takeaway) {
    if ($stepTitles.Count -ne 3 -or $stepDetails.Count -ne 3) {
        throw 'Exercise slides require exactly three steps.'
    }
    $exerciseUrl = "$repoUrl/tree/main/$($projectPath.Replace('\', '/'))"
    @(
        '<rect x="100" y="185" width="1720" height="280" rx="24" fill="#202020" stroke="#383838" stroke-width="2"/>'
        '<path d="M124 185 H1796" stroke="url(#accent)" stroke-width="6"/>'
        '<path d="M1355 220 L1310 430 M1410 275 L1455 320 L1410 365 M1270 275 L1225 320 L1270 365" fill="none" stroke="#444444" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>'
        (Text 145 248 'HANDS-ON / YOUR TURN' 20 'label')
        (Text 145 335 $title 64 'heading')
        (Text 145 401 $subtitle 27)
        '<rect x="1520" y="235" width="250" height="170" rx="18" fill="url(#accent)"/>'
        '<text x="1645" y="282" text-anchor="middle" font-size="18" font-weight="700" style="fill:#ffffff;letter-spacing:3px">EXERCISE</text>'
        "<text x='1645' y='365' text-anchor='middle' font-size='76' class='heading'>$([Security.SecurityElement]::Escape($exerciseNumber))</text>"
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
    '<circle cx="750" cy="380" r="7" fill="#ff6a3f"/>'
    (Lines 780 390 @('Focus on .NET application development,', 'Azure cloud, and generative AI') 34 44)
    '<circle cx="750" cy="500" r="7" fill="#ff6a3f"/>'
    (Lines 780 510 @('18 years of professional experience', 'as a software enthusiast') 34 44)
    '<circle cx="750" cy="620" r="7" fill="#ff6a3f"/>'
    (Lines 780 630 @('Microsoft MVP in Developer Technologies', 'and Azure since 2020') 34 44)
    '<circle cx="750" cy="780" r="7" fill="#ff6a3f"/>'
    (Text 780 790 'Public speaker and trainer' 34)
) -join "`n"
SaveSlide 'slide-02.svg' 'Johnny Hooyberghs' 'Speaker introduction with photo, professional background, and interests.' $body '02' 'ABOUT THE SPEAKER'

$body = @(
    (Text 100 245 'Explore the workshop materials.' 68 'heading')
    (Text 100 315 'Scan to open the Microsoft Agent Framework workshop repository' 30)
    "<a href='$repoUrl'><image x='690' y='340' width='540' height='540' href='$qrCode'/></a>"
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
        ,@('Set OPENAI_ENDPOINT, OPENAI_KEY,', 'and OPENAI_MODEL for Microsoft Foundry.')
        ,@('Start the Token Visualizer console app.', 'Send a message; inspect the token stream.')
        ,@('Try sentences, C# code, and identifiers.', 'Compare local counts with API usage.')
    ) `
    -takeaway 'Tokens shape context size and cost. Wording and formatting matter.'
SaveSlide 'slide-12.svg' 'Exercise 001: Tokenization demo' 'Hands-on exercise 001: configure Microsoft Foundry, run the Token Visualizer, and explore token streams and usage. Open exercises\exercise-001.' $body '12' 'EXERCISE 001: TOKENIZATION DEMO'

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

$sections = @(
    [pscustomobject]@{ Title = 'Introduction'; Subtitle = 'Introduction to GenAI'; Time = '09:00 - 09:30' }
    [pscustomobject]@{ Title = 'Part 1'; Subtitle = 'From LLM calls to agents'; Time = '09:30 - 11:00' }
    [pscustomobject]@{ Title = 'Part 2'; Subtitle = 'Giving agents capabilities: tools and MCP'; Time = '11:15 - 13:00' }
    [pscustomobject]@{ Title = 'Part 3'; Subtitle = 'Orchestrating agents and workflows'; Time = '13:45 - 15:15' }
    [pscustomobject]@{ Title = 'Part 4'; Subtitle = 'Making agents reliable and production-ready'; Time = '15:45 - 17:00' }
)
for ($i = 0; $i -lt $sections.Count; $i++) {
    $section = $sections[$i]
    $slideNumber = $i + 17
    $displayTitle = $section.Title.ToUpperInvariant()
    $body = @(
        (Text 100 435 $displayTitle 76 'heading')
        '<rect x="100" y="485" width="180" height="8" fill="url(#accent)"/>'
        (Text 100 570 $section.Subtitle 50)
        (Text 100 660 $section.Time 28 'agenda-time')
    ) -join "`n"
    SaveSlide ("slide-{0:D2}.svg" -f $slideNumber) "$($section.Title): $($section.Subtitle)" "Section divider for $($section.Title), $($section.Subtitle), scheduled $($section.Time)." $body ("{0:D2}" -f $slideNumber) 'WORKSHOP SESSION'
}

$body = @(
    (Text 100 245 'Any questions?' 72 'heading')
    (Text 100 315 'Continue exploring the workshop materials' 30)
    "<a href='$repoUrl'><image x='690' y='340' width='540' height='540' href='$qrCode'/></a>"
) -join "`n"
SaveSlide 'slide-21.svg' 'Any questions?' 'Questions about the Microsoft Agent Framework workshop. Scan the QR code to open the workshop repository.' $body '21' 'THANK YOU'

Write-Host "Built selected slides in $slides"
