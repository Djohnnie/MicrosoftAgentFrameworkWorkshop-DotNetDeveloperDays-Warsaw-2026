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

function ConceptSlide([int]$number, [string]$title, [string]$subtitle, [string[]]$labels, [string[][]]$details, [string]$takeaway, [string]$sourceUrl, [string]$sourceLabel) {
    $body = @(
        (Text 100 235 $title 48 'heading')
        (Text 100 295 $subtitle 27)
        for ($i = 0; $i -lt 3; $i++) {
            $x = 100 + $i * 590
            (Card $x 355 540 390)
            (Text ($x + 30) 415 $labels[$i] 23 'accent')
            (Lines ($x + 30) 480 $details[$i] 25 40)
        }
        (Text 100 810 $takeaway 27 'heading')
        "<a href='$sourceUrl'>$(Text 100 855 $sourceLabel 19 'muted')</a>"
    ) -join "`n"
    SaveSlide ("slide-{0:D2}.svg" -f $number) $title "$subtitle $takeaway" $body ("{0:D2}" -f $number)
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
    if ([int]$number -eq 1) {
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
            "<text x='1820' y='1032' text-anchor='end' font-size='24' fill='#ffffff'>$([int]$number)</text>"
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
SaveSlide 'slide-01.svg' 'Hands-on building GenAI enabled .NET applications using the Microsoft Agent Framework' 'Workshop opening slide for hands-on building GenAI-enabled .NET applications using the Microsoft Agent Framework at .NET DeveloperDays Warsaw 2026.' $body '1' 'MICROSOFT AGENT FRAMEWORK'

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
SaveSlide 'slide-02.svg' 'Johnny Hooyberghs' 'Speaker introduction with photo, professional background, and interests.' $body '2' 'ABOUT THE SPEAKER'

$body = @(
    (Text 100 245 'Explore the workshop materials.' 68 'heading')
    (Text 100 315 'Scan to open the Microsoft Agent Framework workshop repository' 30)
    "<a href='$repoUrl'><image x='690' y='370' width='540' height='540' href='$qrCode'/></a>"
) -join "`n"
SaveSlide 'slide-03.svg' 'Explore the workshop materials' 'QR code linking to the Microsoft Agent Framework workshop repository.' $body '3' 'FOLLOW ALONG'

$agenda = @(
    [pscustomobject]@{ Time = '09:00 - 09:30'; Topic = 'Introduction to GenAI' }
    [pscustomobject]@{ Time = '09:30 - 11:00'; Topic = 'Part 1: From LLM calls to agents' }
    [pscustomobject]@{ Time = '11:00 - 11:15'; Topic = 'Break' }
    [pscustomobject]@{ Time = '11:15 - 13:00'; Topic = 'Part 2: Giving agents capabilities: tools and MCP' }
    [pscustomobject]@{ Time = '13:00 - 13:45'; Topic = 'Lunch' }
    [pscustomobject]@{ Time = '13:45 - 15:15'; Topic = 'Part 3: Orchestrating agents and workflows' }
    [pscustomobject]@{ Time = '15:15 - 15:30'; Topic = 'Break' }
    [pscustomobject]@{ Time = '15:30 - 17:00'; Topic = 'Part 4: Making agents reliable and production-ready' }
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
SaveSlide 'slide-04.svg' 'Full-day workshop agenda' 'Agenda and timings for the full-day Microsoft Agent Framework workshop.' $body '4' 'WORKSHOP AGENDA'

$body = @(
    (Text 100 435 'INTRODUCTION' 76 'heading')
    '<rect x="100" y="485" width="180" height="8" fill="url(#accent)"/>'
    (Text 100 570 'Introduction to GenAI' 50)
    (Text 100 660 '09:00 - 09:30' 28 'agenda-time')
) -join "`n"
SaveSlide 'slide-05.svg' 'Introduction: Introduction to GenAI' 'Section divider for Introduction, Introduction to GenAI, scheduled 09:00 - 09:30.' $body '5' 'Hands-on building GenAI enabled .NET applications using the Microsoft Agent Framework'

$body = @(
    (Text 100 235 'From hand-written rules to systems that create' 48 'heading')
    (Text 100 282 'Each shift made AI more capable by learning richer patterns from data.' 27)
    (Card 100 365 390 340)
    (Text 130 425 '01 / RULES' 20 'accent')
    (Text 130 495 'Rules-based' 35 'heading')
    (Lines 130 555 @('People define the logic.', 'Predictable, but brittle.') 25 40)
    '<path d="M498 535 H522 M514 527 L522 535 L514 543" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 535 365 390 340)
    (Text 565 425 '02 / DATA' 20 'accent')
    (Text 565 495 'Machine learning' 33 'heading')
    (Lines 565 555 @('Models learn patterns', 'from examples.') 25 40)
    '<path d="M933 535 H957 M949 527 L957 535 L949 543" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 970 365 390 340)
    (Text 1000 425 '03 / SCALE' 20 'accent')
    (Text 1000 495 'Deep learning' 35 'heading')
    (Lines 1000 555 @('Neural networks learn', 'richer representations.') 25 40)
    '<path d="M1368 535 H1392 M1384 527 L1392 535 L1384 543" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 1405 365 390 340)
    (Text 1435 425 '04 / GENERATION' 20 'accent')
    (Text 1435 495 'Generative AI' 35 'heading')
    (Lines 1435 555 @('Models create new text,', 'images, audio, and code.') 25 40)
    (Text 100 795 'A progression of techniques—not a replacement of every earlier kind of AI.' 25 'muted')
) -join "`n"
SaveSlide 'slide-06.svg' 'The evolution of AI' 'A concise progression from rules-based systems through machine learning and deep learning to generative AI.' $body '6' 'THE EVOLUTION OF AI'

$body = @(
    (Text 100 235 'Four approaches, different strengths' 48 'heading')
    (Text 100 290 'The key difference is where the system''s behavior comes from.' 27)
    (Card 100 350 390 410)
    (Text 130 410 '01 / PEOPLE WRITE RULES' 18 'accent')
    (Text 130 475 'Rules-based' 32 'heading')
    (Lines 130 535 @('People define explicit', 'if/then logic.', 'Best for stable rules;', 'brittle when cases grow.') 23 40)
    '<path d="M498 555 H522 M514 547 L522 555 L514 563" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 535 350 390 410)
    (Text 565 410 '02 / LEARN FROM DATA' 18 'accent')
    (Text 565 475 'Machine learning' 29 'heading')
    (Lines 565 535 @('Learns patterns from data', 'using statistical algorithms', 'to predict or group new cases,', 'like spam or demand.') 21 40)
    '<path d="M933 555 H957 M949 547 L957 555 L949 563" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 970 350 390 410)
    (Text 1000 410 '03 / NEURAL NETWORKS' 18 'accent')
    (Text 1000 475 'Deep learning' 32 'heading')
    (Lines 1000 535 @('Uses many network layers', 'to learn useful features.', 'Powerful for images,', 'speech, and complex data.') 23 40)
    '<path d="M1368 555 H1392 M1384 547 L1392 555 L1384 563" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 1405 350 390 410)
    (Text 1435 410 '04 / CREATE CONTENT' 18 'accent')
    (Text 1435 475 'Generative AI' 32 'heading')
    (Lines 1435 535 @('Learns patterns in data', 'to create text, images,', 'audio, or code. Outputs', 'vary; verify key facts.') 23 40)
    (Text 100 835 'Not four separate boxes: deep learning is a kind of machine learning, and generative AI often uses it.' 24 'muted')
) -join "`n"
SaveSlide 'slide-07.svg' 'Four approaches, different strengths' 'A closer look at rules-based systems, machine learning, deep learning, and generative AI, including how they relate.' $body '7' 'FOUR APPROACHES TO AI'

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
SaveSlide 'slide-08.svg' 'Types of machine learning' 'Supervised, unsupervised, and reinforcement learning compared by objective and feedback.' $body '8' 'TYPES OF MACHINE LEARNING'

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
SaveSlide 'slide-09.svg' 'The reinforcement loop' 'An agent acts in an environment, receives feedback, and uses rewards to improve future choices.' $body '9' 'THE REINFORCEMENT LOOP'

$body = @(
    (Text 100 235 'Train an image model with AI feedback' 48 'heading')
    (Text 100 285 'Training prompt: "Generate an image of a dog in a yellow raincoat."' 25)
    (Card 720 310 480 145)
    (Text 760 370 'GENERATOR MODEL' 22 'accent')
    (Text 760 420 'Generates a dog image' 28 'heading')
    (Card 1260 485 450 145)
    (Text 1300 545 'CANDIDATE IMAGE' 22 'accent')
    (Text 1300 600 'Does it match the prompt?' 25 'heading')
    (Card 720 665 480 145)
    (Text 760 725 'VALIDATOR AGENT' 22 'accent')
    (Text 760 780 'Scores dog + coat accuracy' 25 'heading')
    (Card 210 485 450 145)
    (Text 250 545 'REWARD + TRAINING' 22 'accent')
    (Text 250 600 'Update generator weights' 25 'heading')
    '<path d="M1180 390 Q1315 405 1390 480" class="diagram-arrow"/>'
    '<path d="M1485 640 Q1370 730 1215 738" class="diagram-arrow"/>'
    '<path d="M710 740 Q590 720 545 640" class="diagram-arrow"/>'
    '<path d="M430 480 Q520 375 700 380" class="diagram-arrow"/>'
    (Lines 100 842 @(
        'Repeat across many images: automated scoring scales feedback, not guaranteed improvement.'
        'Training updates weights; a validator reviewing an image alone does not train the model.'
    ) 22 34 'muted')
) -join "`n"
SaveSlide 'slide-10.svg' 'Generative AI: create an image of a dog' 'A reinforcement learning training example: generate a dog in a yellow raincoat, use a separate validator agent to score prompt alignment, and use rewards to update generator weights across many images.' $body '10' 'GENERATIVE AI / IMAGE EXAMPLE'

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
    '<path d="M1620 728 V752 H960 V777 M952 769 L960 777 L968 769" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 685 785 550 90)
    (Text 725 842 'LLMs are one kind of generative AI model.' 26 'heading')
) -join "`n"
SaveSlide 'slide-11.svg' 'AI is not one thing' 'AI includes many distinct capabilities; large language models are one type of generative AI model.' $body '11' 'AI IS NOT ONE THING'

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
SaveSlide 'slide-12.svg' 'What is a model?' 'A model is a trained system that applies learned patterns to map new inputs to predictions or generated outputs.' $body '12' 'WHAT IS A MODEL?'

$body = @(
    (Text 100 235 'An LLM repeatedly predicts what token comes next' 46 'heading')
    (Text 100 300 'It processes a sequence of token representations and generates one continuation at a time.' 26)
    (Card 100 390 300 240)
    (Text 130 445 '01 / INPUT' 19 'accent')
    (Lines 130 505 @('Your prompt', 'arrives as text.') 25 43)
    '<path d="M410 510 H434 M426 502 L434 510 L426 518" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 445 390 300 240)
    (Text 475 445 '02 / TOKENS' 19 'accent')
    (Lines 475 505 @('Text is split', 'into token IDs.') 25 43)
    '<path d="M755 510 H779 M771 502 L779 510 L771 518" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 790 390 300 240)
    (Text 820 445 '03 / EMBEDDINGS' 19 'accent')
    (Lines 820 505 @('IDs become', 'vectors the model', 'can process.') 25 43)
    '<path d="M1100 510 H1124 M1116 502 L1124 510 L1116 518" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 1135 390 300 240)
    (Text 1165 445 '04 / PREDICT' 19 'accent')
    (Lines 1165 505 @('The model scores', 'possible next', 'tokens.') 25 43)
    '<path d="M1445 510 H1469 M1461 502 L1469 510 L1461 518" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 1480 390 300 240)
    (Text 1510 445 '05 / SAMPLE' 19 'accent')
    (Lines 1510 505 @('One token is', 'selected and', 'appended.') 25 43)
    '<path d="M1630 640 V715 H250 V640 M242 648 L250 640 L258 648" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Text 100 785 'Repeat this loop until the model reaches a stopping condition.' 26 'heading')
    (Text 100 835 'Token counts—not words or lines—shape context limits and usage.' 23 'muted')
) -join "`n"
SaveSlide 'slide-13.svg' 'How LLMs work' 'Large language models tokenize input and generate output by repeatedly predicting and selecting the next token.' $body '13' 'HOW LLMS WORK'

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
SaveSlide 'slide-14.svg' 'Exercise 001: Tokenization demo' 'Hands-on exercise 001: configure Microsoft Foundry, run the Token Visualizer, and explore token streams and usage. Open exercises\exercise-001.' $body '14' 'EXERCISE 001'

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
SaveSlide 'slide-18.svg' 'Why LLMs hallucinate' 'LLMs optimize for plausible continuations rather than verified facts; missing context and misleading confidence increase risk.' $body '18' 'WHY LLMS HALLUCINATE'

$body = @(
    (Text 100 235 'Give the model relevant knowledge at answer time' 47 'heading')
    (Text 100 300 'Retrieval-Augmented Generation (RAG) connects a language model to trusted information.' 26)
    (Card 100 405 460 240)
    (Text 135 465 '01 / ASK' 20 'accent')
    (Lines 135 525 @('User question', 'and intent') 28 46)
    '<path d="M570 525 H695 M687 517 L695 525 L687 533" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 705 405 460 240)
    (Text 740 465 '02 / RETRIEVE' 20 'accent')
    (Lines 740 525 @('Search relevant', 'documents / chunks') 28 46)
    '<path d="M1175 525 H1300 M1292 517 L1300 525 L1292 533" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 1310 405 510 240)
    (Text 1345 465 '03 / GENERATE' 20 'accent')
    (Lines 1345 525 @('Use retrieved context', 'to draft an answer') 28 46)
    '<path d="M1590 655 V700 H950 V732 M942 724 L950 732 L958 724" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 625 740 650 105)
    (Text 665 805 'Answer with evidence in the model context.' 27 'heading')
    (Text 100 885 'RAG adds context; quality depends on retrieval, source trust, and generation.' 22 'muted')
) -join "`n"
SaveSlide 'slide-19.svg' 'RAG: giving an LLM the right knowledge' 'Retrieval-augmented generation retrieves relevant external information and adds it to the model context before answering.' $body '19' 'RAG: GIVING AN LLM THE RIGHT KNOWLEDGE'

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
SaveSlide 'slide-20.svg' 'Beyond chatbots' 'An agent extends conversational AI with goal-directed decisions, tools, actions, and feedback from results.' $body '20' 'BEYOND CHATBOTS'

$body = @(
    (Text 100 235 'Coordinate focused agents around a shared outcome' 46 'heading')
    (Card 690 315 540 140)
    (Text 730 375 'ORCHESTRATOR' 21 'accent')
    (Text 730 425 'Routes work and manages handoffs' 27 'heading')
    '<path d="M960 465 V505 M355 505 H1565" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    '<path d="M355 505 V540 M347 532 L355 540 L363 532" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    '<path d="M960 505 V540 M952 532 L960 540 L968 532" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    '<path d="M1565 505 V540 M1557 532 L1565 540 L1573 532" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    (Card 100 550 510 205)
    (Text 135 610 'PLANNER' 20 'accent')
    (Lines 135 665 @('Breaks a goal into', 'clear tasks.') 25 42)
    (Card 705 550 510 205)
    (Text 740 610 'RESEARCHER' 20 'accent')
    (Lines 740 665 @('Finds relevant facts', 'and context.') 25 42)
    (Card 1310 550 510 205)
    (Text 1345 610 'BUILDER / REVIEWER' 20 'accent')
    (Lines 1345 665 @('Creates a result and', 'checks it against needs.') 25 42)
    '<path d="M355 765 V800 H1565 V765 M960 765 V850 M952 842 L960 850 L968 842" fill="none" stroke="#ff6a3f" stroke-width="3"/>'
    '<g role="img" aria-label="Shared goal target">
        <circle cx="960" cy="895" r="34" fill="#202020" stroke="#ff6a3f" stroke-width="3"/>
        <circle cx="960" cy="895" r="21" fill="none" stroke="#ff6a3f" stroke-width="3"/>
        <circle cx="960" cy="895" r="7" fill="#ff6a3f"/>
        <path d="M998 857 L960 895 M960 883 V895 H972" fill="none" stroke="#ff6a3f" stroke-width="3"/>
    </g>'
    (Text 1015 904 'SHARED GOAL' 22 'accent')
    (Text 100 960 'Specialize, coordinate, and keep people in control of consequential actions.' 23 'muted')
) -join "`n"
SaveSlide 'slide-21.svg' 'Agent orchestration' 'Orchestration coordinates specialized agents, routes tasks, and manages handoffs toward a shared goal.' $body '21' 'AGENT ORCHESTRATION'

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
SaveSlide 'slide-22.svg' 'What is Microsoft Agent Framework?' 'Microsoft Agent Framework brings together agents, harness agents, workflows, and integrations to build production-grade AI applications.' $body '22' 'WHAT IS MICROSOFT AGENT FRAMEWORK?'

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
SaveSlide 'slide-23.svg' 'Agents or workflows?' 'Use an agent for open-ended tasks that need autonomous planning; use a workflow for defined steps that need explicit execution control.' $body '23' 'AGENTS OR WORKFLOWS?'

ConceptSlide 15 'Input, cached input, and output tokens' `
    'The API reports usage; a local tokenizer only estimates part of the request.' `
    @('INPUT / WHAT YOU SEND', 'CACHED / REUSED INPUT', 'OUTPUT / WHAT IT GENERATES') `
    @(
        ,@('Instructions and the user question', 'Earlier messages and tool results', 'Tool definitions and JSON schemas', 'All consume the context budget.')
        ,@('A subset of input, not extra tokens', 'An identical prefix may be reused.', 'Still sent; still uses context space.', 'Keep stable content first.', 'A cache hit is not guaranteed.')
        ,@('Visible text and tool-call arguments', 'Reasoning tokens can also be billed', 'as output, even when not visible.', 'One agent run may call the model', 'several times: sum every call.')
    ) `
    'Caching is neither conversation memory nor a stored answer.' `
    'https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/prompt-caching' `
    'Source: Microsoft Learn / prompt caching; adapted from AI4Dev two-day slide 207'

$body = @(
    (Text 100 235 'Model pricing: measure the whole agent run' 48 'heading')
    (Text 100 295 'Azure Foundry Global / EUR per 1M tokens / supplied 18 October 2026' 26)
    (Card 100 330 1720 400)
    (Text 135 380 'MODEL' 20 'accent')
    (Text 760 380 'INPUT' 20 'accent')
    (Text 1000 380 'CACHED INPUT' 20 'accent')
    (Text 1260 380 'CACHE WRITE' 20 'accent')
    (Text 1550 380 'OUTPUT' 20 'accent')
    $pricingRows = @(
        ,@('GPT-6 Astra (short context) Global', '€8.800', '€0.880', '€11.000', '€44.000')
        ,@('GPT-6 Sol (short context) Global', '€1.760', '€0.176', '€2.200', '€8.800')
        ,@('GPT-6 Luna (short context) Global', '€0.088', '€0.009', '€0.110', '€0.440')
        ,@('GPT-4.1-2025-04-14 Global', '€1.760', '€0.440', 'Not supplied', '€7.040')
        ,@('MAI-Thinking-1 Global', '€1.760', '€0.176', 'Not supplied', '€7.040')
    )
    for ($i = 0; $i -lt $pricingRows.Count; $i++) {
        $y = 445 + $i * 60
        (Text 135 $y $pricingRows[$i][0] 25 'heading')
        (Text 760 $y $pricingRows[$i][1] 27)
        (Text 1000 $y $pricingRows[$i][2] 27)
        (Text 1260 $y $pricingRows[$i][3] 25)
        (Text 1550 $y $pricingRows[$i][4] 27)
    }
    (Lines 100 790 @(
        'Cost = uncached input + cache reads + output; add charged cache writes.'
        'Example: 20k input, 16k cached, 1k output on GPT-4.1: about €0.021, not €0.042.'
    ) 23 36)
    (Text 100 870 'Not supplied = no separate cache-write price provided; do not assume writes are free.' 19 'muted')
    (Text 100 905 'Foundry Global / EUR figures supplied for this workshop on 18 October 2026.' 19 'muted')
    "<a href='https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/'>$(Text 100 940 'Check Azure Foundry pricing: region, context tier, currency, and tool fees can change the bill.' 19 'muted')</a>"
) -join "`n"
SaveSlide 'slide-16.svg' 'Model pricing: measure the whole agent run' 'Five Azure Foundry Global models with EUR prices per million tokens supplied on 18 October 2026. Unspecified cache-write prices are marked Not supplied. Includes a GPT-4.1 cost example.' $body '16' 'TOKENS AND COST'

ConceptSlide 17 'Reasoning tokens: hidden work, real cost' `
    'Reasoning models can generate internal tokens as they work toward an answer.' `
    @('INTERNAL MONOLOGUE?', 'HIDDEN DOES NOT MEAN FREE', 'MEASURE THE WHOLE OUTPUT') `
    @(
        ,@('A useful metaphor, not a mind.', 'Internal tokens help the model', 'plan and compare approaches.', 'Raw reasoning is usually hidden.', 'A displayed reasoning summary', 'is not the raw internal trace.')
        ,@('Reasoning tokens are generated', 'and billed at the output rate.', 'They also use context space.', 'A short answer can still require', 'many hidden reasoning tokens.', 'More reasoning can add latency.')
        ,@('Example: 2,000 reasoning tokens', '+ 500 visible answer tokens', '= 2,500 output tokens billed.', 'Reasoning is already included:', 'do not add it to output twice.', 'Check API usage, not text length.')
    ) `
    'Tune reasoning effort and output limits where supported; measure quality, latency, and cost.' `
    'https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/reasoning' `
    'Source: Microsoft Learn / reasoning models; OpenAI / reasoning guide'

$sections = @(
    [pscustomobject]@{ Title = 'Part 1'; Subtitle = 'From LLM calls to agents'; Time = '09:30 - 11:00' }
    [pscustomobject]@{ Title = 'Part 2'; Subtitle = 'Giving agents capabilities: tools and MCP'; Time = '11:15 - 13:00' }
    [pscustomobject]@{ Title = 'Part 3'; Subtitle = 'Orchestrating agents and workflows'; Time = '13:45 - 15:15' }
    [pscustomobject]@{ Title = 'Part 4'; Subtitle = 'Making agents reliable and production-ready'; Time = '15:30 - 17:00' }
)
for ($i = 0; $i -lt $sections.Count; $i++) {
    $section = $sections[$i]
    $slideNumber = @(24, 46, 65, 71)[$i]
    $displayTitle = $section.Title.ToUpperInvariant()
    $body = @(
        (Text 100 435 $displayTitle 76 'heading')
        '<rect x="100" y="485" width="180" height="8" fill="url(#accent)"/>'
        (Text 100 570 $section.Subtitle 50)
        (Text 100 660 $section.Time 28 'agenda-time')
    ) -join "`n"
    SaveSlide ("slide-{0:D2}.svg" -f $slideNumber) "$($section.Title): $($section.Subtitle)" "Section divider for $($section.Title), $($section.Subtitle), scheduled $($section.Time)." $body ("{0:D2}" -f $slideNumber) 'Hands-on building GenAI enabled .NET applications using the Microsoft Agent Framework'

    if ($i -eq 0) {
        ConceptSlide 25 'The .NET stack: client, abstraction, agent' `
            'Exercises 101-106 build the foundation that Microsoft Agent Framework uses.' `
            @('PROVIDER SDK', 'MICROSOFT.EXTENSIONS.AI', 'MICROSOFT.AGENTS.AI') `
            @(
                ,@('ResponsesClient talks to Foundry.', 'OllamaApiClient talks to Ollama.', 'Endpoint, credentials, deployment:', 'these remain provider concerns.')
                ,@('IChatClient is the shared contract.', 'ChatMessage describes each turn.', 'GetResponseAsync returns a reply.', '101-106 use this directly.')
                ,@('AIAgent wraps the chat client.', 'Instructions define its role.', 'AgentSession carries turn state.', '107 introduces the agent layer.', 'Tools arrive in Part 2.')
            ) `
            'A common interface reduces glue code; it does not make providers identical.' `
            'https://learn.microsoft.com/en-us/dotnet/ai/ichatclient' 'Source: Microsoft Learn / IChatClient'

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
        SaveSlide 'slide-26.svg' 'Exercise 101: Simple Chatbot' 'Part 1 exercise 101: chat with a Foundry model through independent requests that do not retain conversation history. Open exercises\exercise-101.' $body '26' 'EXERCISE 101'

        ConceptSlide 27 'Conversation history is input, not learning' `
            'A follow-up works only when the application supplies the earlier context.' `
            @('101 / ONE REQUEST', '102 / EXPLICIT HISTORY', 'CONTEXT HAS A BUDGET') `
            @(
                ,@('User: My name is Ada.', 'Assistant: Hello, Ada!', 'User: What is my name?', 'Only that last question is sent.', 'The model cannot recall Ada.')
                ,@('Keep List<ChatMessage> outside', 'the loop; append the new input.', 'Send the list, then retain all', 'response.Messages, not just text.', 'Earlier turns are input again.')
                ,@('More turns mean more tokens.', 'History does not train the model.', 'In-memory state ends on restart.', 'Later: trim or summarize history;', 'do not remove needed evidence.')
            ) `
            'Ask the same follow-up in 101 and 102; explain the difference from the request.' `
            'https://learn.microsoft.com/en-us/dotnet/ai/ichatclient' 'Source: Microsoft Learn / IChatClient; workshop exercises 101-102'

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
        SaveSlide 'slide-28.svg' 'Exercise 102: Chatbot with History' 'Part 1 exercise 102: retain user messages and assistant replies and send the full conversation with every request. Open exercises\exercise-102.' $body '28' 'EXERCISE 102'

        ConceptSlide 29 'Token usage: measure each model response' `
            'Microsoft Agent Framework shares a usage contract with Microsoft.Extensions.AI.' `
            @('THE SHARED USAGE API', 'HOW IT WORKS', 'WHY MEASURE?') `
            @(
                ,@('ChatResponse.Usage today;', 'AgentResponse.Usage later.', 'Both expose UsageDetails:', 'InputTokenCount', 'OutputTokenCount', 'TotalTokenCount', 'Counts are nullable.')
                ,@('GetResponseAsync or RunAsync', 'returns a response with Usage.', 'Provider counts pass through', 'the adapter into UsageDetails.', 'History is input again each turn.', 'Missing counts are not zero.', 'Not a local tokenizer estimate.')
                ,@('Estimate spend with model rates.', 'Spot expensive, growing history.', 'Compare prompts and models.', 'Agent runs may use many calls.', 'Reasoning can add output tokens.', 'Cache details vary by provider.', 'Log usage to track your budget.')
            ) `
            'Tokens are not euros: apply model rates; separate per-request counts from session totals.' `
            'https://learn.microsoft.com/dotnet/api/microsoft.agents.ai.agentresponse.usage' `
            'Source: Microsoft Learn / AgentResponse.Usage; Microsoft.Extensions.AI.UsageDetails'

        $body = ExerciseBody -exerciseNumber '103' -title 'Chatbot with Token Usage' `
            -subtitle 'Measure input and output tokens using the API response.' `
            -projectPath 'exercises\exercise-103' `
            -stepTitles @('Keep', 'Read', 'Compare') `
            -stepDetails @(
                ,@('Start from exercise 102;', 'keep the history loop.')
                ,@('After each reply, print', 'response.Usage.InputTokenCount', 'and OutputTokenCount.')
                ,@('Compare follow-up requests.', 'Missing counts: not reported.', 'No local token estimates.')
            ) `
            -takeaway 'API usage measures each request: history counts as input; hidden reasoning can count as output.'
        SaveSlide 'slide-30.svg' 'Exercise 103: Chatbot with Token Usage' 'Part 1 exercise 103: copy exercise 102 and print API-reported input and output token counts from response.Usage after each reply. Preserve history and report missing counts explicitly. Open exercises\exercise-103.' $body '30' 'EXERCISE 103'

        ConceptSlide 31 'System prompts: give your chatbot a role' `
            'A system message sets behavior and task context; the user message carries the question.' `
            @('ROLE AND CONTEXT', 'PUT IT IN THE REQUEST', 'GUIDANCE, NOT A GUARANTEE') `
            @(
                ,@('You are a cheerful 10-year-old.', 'Explain with simple examples.', 'Set tone, audience, and scope.', 'Add relevant task context.', 'Define an answer format.', 'Say what to do when unsure.')
                ,@('new ChatMessage(', '    ChatRole.System, instructions)', 'Place it before user messages.', 'Keep it in the history you send.', 'Change it to switch persona.', 'Exercise 104 replaces it per turn.')
                ,@('A persona does not train a model.', 'Tone is not factual accuracy.', 'Do not put secrets in prompts.', 'Keep untrusted data separate.', 'Validate important results.', 'Agents later use Instructions.')
            ) `
            'Same model, different instructions: steer behavior without changing its knowledge or weights.' `
            'https://learn.microsoft.com/dotnet/ai/ichatclient#request-a-chat-response' `
            'Source: Microsoft Learn / IChatClient; workshop exercise 104'

        $body = ExerciseBody -exerciseNumber '104' -title 'Chatbot Personas' `
            -subtitle 'Change the age persona with each question.' `
            -projectPath 'exercises\exercise-104' `
            -stepTitles @('Define', 'Include', 'Compare') `
            -stepDetails @(
                ,@('Start at age 10; put the age', 'in a system prompt template.')
                ,@('Replace the system message;', 'keep the conversation history.')
                ,@('Lower the age by 2 per reply:', '10, 8, 6, 4, 2, 0. Stay at 0.', 'Compare vocabulary and tone.')
            ) `
            -takeaway 'A system prompt guides style and behavior; it does not change the model or ensure facts.'
        SaveSlide 'slide-32.svg' 'Exercise 104: Chatbot Personas' 'Part 1 exercise 104: update the system persona from age 10 down to 0 in steps of 2, staying at 0 and retaining conversation history. Open exercises\exercise-104.' $body '32' 'EXERCISE 104'

        ConceptSlide 33 'Instructions, knowledge, and state are different' `
            'Exercise 104 changes behavior; Lab 100 supplies facts; a session carries earlier turns.' `
            @('INSTRUCTIONS / BEHAVIOR', 'CONTEXT / KNOWLEDGE', 'SESSION / CONVERSATION') `
            @(
                ,@('Role, tone, scope, answer format', '104 replaces the age instruction.', '107 keeps the age fixed at 10.', 'A persona is not fine-tuning', 'and does not guarantee truth.')
                ,@('Facts the answer should use', 'Lab 100 supplies agenda JSON.', 'State the source and time zone.', 'Say when evidence is missing.', 'Treat source text as data,', 'not permission to change rules.')
                ,@('Earlier user and assistant turns', 'Lets "When is his talk?" refer', 'to the speaker just discussed.', 'Not an authoritative fact store.', 'Do not mix attendees in one', 'shared conversation session.')
            ) `
            'Better instructions guide behavior; trustworthy evidence supports factual answers.' `
            'https://learn.microsoft.com/en-us/agent-framework/agents/conversations/session' 'Source: Microsoft Learn / AgentSession; exercises 104 and 107, Lab 100'

        ConceptSlide 34 'Structured output: shape is not correctness' `
            'Exercise 105 turns a model reply into a typed C# result, not a verified employee.' `
            @('DESCRIBE THE SHAPE', 'CONSTRAIN GENERATION', 'VALIDATE THE VALUES') `
            @(
                ,@('Employee record defines fields.', 'DateOnly for the birth date', 'decimal for annual EUR salary', 'Clear field descriptions help', 'the model interpret the schema.')
                ,@('GetResponseAsync<Employee>', 'enables JSON-schema output.', 'Read response.Result.', 'Use a supporting deployment.', 'Handle refusal or failure;', 'do not assume every call succeeds.')
                ,@('Is the birth date plausible?', 'Is the salary non-negative?', 'Are required strings meaningful?', 'A valid shape can hold bad facts.', 'Keep business-rule checks', 'in deterministic application code.')
            ) `
            'Use schemas for machine-readable contracts; use code and evidence for correctness.' `
            'https://learn.microsoft.com/en-us/dotnet/ai/quickstarts/structured-output' 'Source: Microsoft Learn / structured output'

        $body = ExerciseBody -exerciseNumber '105' -title 'Structured Output' `
            -subtitle 'Generate a typed employee instead of free-form text.' `
            -projectPath 'exercises\exercise-105' `
            -stepTitles @('Define', 'Generate', 'Inspect') `
            -stepDetails @(
                ,@('Create an Employee record:', 'name, first name, birth date,', 'salary, and function title.')
                ,@('Use GetResponseAsync<Employee>', 'with JSON-schema output;', 'choose a supporting deployment.')
                ,@('Read the typed result; compare', 'employees from different prompts.')
            ) `
            -takeaway 'The C# type defines the output shape; application code still validates the values.'
        SaveSlide 'slide-35.svg' 'Exercise 105: Structured Output' 'Part 1 exercise 105: use a generic structured-output call to generate an Employee with name, first name, birth date, salary, and function title. Open exercises\exercise-105.' $body '35' 'EXERCISE 105'

        ConceptSlide 36 'One agent abstraction, different backends' `
            'Agent Framework coordinates the agent; a provider client connects it to the model.' `
            @('THE ABSTRACTION', 'CLOUD OR LOCAL', 'OLLAMA HOSTS THE MODEL') `
            @(
                ,@('AIAgent: instructions and session', 'RunAsync stays the entry point.', 'ChatClientAgent uses IChatClient', 'from Microsoft.Extensions.AI.', 'Keep agent code; swap the client.', '106 uses IChatClient directly;', '107 adds the agent wrapper.')
                ,@('Foundry: ResponsesClient', 'adapted with AsIChatClient.', 'Ollama: OllamaApiClient', 'already implements IChatClient.', 'AsAIAgent wraps either client.', 'Endpoint and model are settings.', 'Features still depend on backend.')
                ,@('Install Ollama; download a model:', 'ollama pull qwen2.5:7b', 'Start the app or ollama serve.', 'API: http://localhost:11434', 'Inference uses local CPU/GPU.', 'Works offline after download.', 'Needs RAM and disk; GPU helps.')
            ) `
            'Ollama hosts the model; Agent Framework coordinates the agent. Same interface, different infrastructure.' `
            'https://learn.microsoft.com/en-us/agent-framework/integrations/by-component/model-providers/ollama' `
            'Sources: Microsoft Learn / Ollama provider; docs.ollama.com / CLI reference'

        $body = ExerciseBody -exerciseNumber '106' -title 'Local Ollama Chatbot' `
            -subtitle 'Keep the chat loop; run the model on your machine.' `
            -projectPath 'exercises\exercise-106' `
            -stepTitles @('Prepare', 'Connect', 'Compare') `
            -stepDetails @(
                ,@('Start Ollama and download:', 'ollama pull qwen2.5:7b')
                ,@('Use OllamaApiClient as IChatClient', 'at http://localhost:11434.')
                ,@('Keep the history from 102.', 'Compare local and cloud replies;', 'no Foundry credentials needed.')
            ) `
            -takeaway 'IChatClient lets you change providers while keeping the same conversation code.'
        SaveSlide 'slide-37.svg' 'Exercise 106: Local Ollama Chatbot' 'Part 1 exercise 106: use a local qwen2.5:7b model through Ollama and keep the IChatClient conversation history from exercise 102. Open exercises\exercise-106.' $body '37' 'EXERCISE 106'

        ConceptSlide 38 'Provider portability does not mean feature parity' `
            'Exercise 106 changes the backend; Part 2 will also compare tool calling.' `
            @('KEEP THE CONTRACT', 'CHECK CAPABILITIES', 'CHOOSE WITH MEASUREMENTS') `
            @(
                ,@('IChatClient keeps the loop familiar.', 'ChatMessage history still works.', 'Foundry: hosted model inference', 'Ollama: inference on this machine', 'An agent can wrap either client.')
                ,@('Tool calling depends on the model.', 'JSON-schema support can differ.', 'Context limits and tokenizers differ.', 'Adapter support matters too.', 'A successful chat reply is not', 'proof that every feature works.')
                ,@('Compare answer quality and speed.', 'Check memory and hardware needs.', 'Local inference has hardware cost.', 'Review data flow and retention.', 'Local history plus cloud inference', 'still sends content to Foundry.')
            ) `
            'Keep application code portable, then test the capabilities your scenario needs.' `
            'https://learn.microsoft.com/en-us/agent-framework/agents/tools/' 'Source: Microsoft Learn / tool provider support matrix'

        ConceptSlide 39 'AIAgent is configuration; AgentSession is state' `
            'Exercise 107 moves the history responsibility into Microsoft Agent Framework.' `
            @('CONFIGURE THE AGENT', 'REUSE ONE SESSION', 'KNOW WHERE HISTORY LIVES') `
            @(
                ,@('ChatClientAgentOptions sets', 'instructions and history provider.', 'AsAIAgent wraps IChatClient.', 'RunAsync invokes the agent.', 'No tools or workflows yet.')
                ,@('CreateSessionAsync before the loop.', 'Pass the same session every turn.', 'A new session starts a new chat.', 'The history provider stores', 'messages in the session StateBag.')
                ,@('InMemoryChatHistoryProvider', 'keeps history in this process.', 'StoredOutputEnabled = false', 'disables Responses storage here.', 'DebugHistory reads actual state;', 'inference still sends it to Foundry.')
            ) `
            'Session state is not durable memory; persistence needs an explicit design.' `
            'https://learn.microsoft.com/en-us/agent-framework/agents/conversations/session' 'Source: Microsoft Learn / AgentSession'

        $body = ExerciseBody -exerciseNumber '107' -title 'Chatbot Agent' `
            -subtitle 'Give an agent instructions and a conversation session.' `
            -projectPath 'exercises\exercise-107' `
            -stepTitles @('Create', 'Instruct', 'Inspect') `
            -stepDetails @(
                ,@('AsAIAgent with', 'ChatClientAgentOptions and', 'InMemoryChatHistoryProvider.')
                ,@('ChatOptions: cheerful age 10;', 'RawRepresentationFactory sets', 'StoredOutputEnabled = false.')
                ,@('Reuse one session in RunAsync.', 'DebugHistory reads local messages', 'with TryGetInMemoryChatHistory.')
            ) `
            -takeaway 'The agent keeps history in a local session; each model call still sends it to Foundry.'
        SaveSlide 'slide-40.svg' 'Exercise 107: Chatbot Agent' 'Part 1 exercise 107: use ChatClientAgentOptions with InMemoryChatHistoryProvider and ChatOptions.Instructions for a fixed cheerful age-10 persona. RawRepresentationFactory sets CreateResponseOptions.StoredOutputEnabled=false. Reuse one AgentSession; DebugHistory inspects actual local messages with TryGetInMemoryChatHistory after each reply. Open exercises\exercise-107.' $body '40' 'EXERCISE 107'

        ConceptSlide 41 'Multimodal models: beyond text-only chat' `
            'Multimodal models work with more than one type of content, not just text.' `
            @('MORE THAN TEXT', 'SAME AGENT, RICHER INPUT', 'CHOOSE A CAPABLE MODEL') `
            @(
                ,@('Modalities = types of content:', 'text, images, audio, and video.', 'A model can accept or generate', 'more than one content type.', 'Example: image + question', 'becomes a text explanation.')
                ,@('Build a user ChatMessage with', 'TextContent for the question', 'plus UriContent or DataContent', 'for the image, with MIME type.', 'Call agent.RunAsync(message).', 'The adapter passes media through.', 'No tool is needed for image input.')
                ,@('Model + API + adapter must', 'support the requested modality.', 'Image input is not image output.', 'Check file types, sizes, and cost.', 'Cloud inference uploads media.', 'Treat embedded text as data.', '109 uses AudioClient directly.')
            ) `
            'Agent Framework carries multimodal messages; the model determines what it can understand or generate.' `
            'https://learn.microsoft.com/en-us/agent-framework/agents/multimodal?pivots=programming-language-csharp' `
            'Source: Microsoft Learn / Using images with an agent; workshop exercises 108-109'

        $body = ExerciseBody -exerciseNumber '108' -title 'Multimodal Images' `
            -subtitle 'Ask an image-capable agent to read and translate a picture.' `
            -projectPath 'exercises\exercise-108' `
            -stepTitles @('Configure', 'Attach', 'Compare') `
            -stepDetails @(
                ,@('Use a Foundry deployment', 'that supports image input', 'through the Responses API.')
                ,@('Combine TextContent with', 'UriContent or DataContent', 'in one user ChatMessage.')
                ,@('Translate the URL and local JPEG', 'in separate fresh sessions;', 'check both against the image.')
            ) `
            -takeaway 'Image bytes are model input, not a tool; local files still go to Foundry for inference.'
        SaveSlide 'slide-42.svg' 'Exercise 108: Multimodal Images' 'Part 1 exercise 108: translate text in an image using a Foundry-backed AIAgent. Combine TextContent with UriContent for a public image URL or DataContent for local JPEG bytes. Use independent sessions, local history, and disabled Responses storage. Open exercises\exercise-108.' $body '42' 'EXERCISE 108'

        $body = ExerciseBody -exerciseNumber '109' -title 'Multimodal Audio' `
            -subtitle 'Turn spoken audio into a transcript and an English translation.' `
            -projectPath 'exercises\exercise-109' `
            -stepTitles @('Configure', 'Transcribe', 'Translate') `
            -stepDetails @(
                ,@('Use a Whisper deployment;', 'the chat deployment from 108', 'does not provide this capability.')
                ,@('Open the bundled French WAV;', 'TranscribeAudioAsync returns', 'text in the original language.')
                ,@('Reopen the same recording;', 'TranslateAudioAsync returns', 'English text, not speech.')
            ) `
            -takeaway 'Direct audio SDK calls, not an agent session; the local recording is uploaded to Foundry.'
        SaveSlide 'slide-43.svg' 'Exercise 109: Multimodal Audio' 'Part 1 exercise 109: use the OpenAI AudioClient with a Foundry Whisper deployment to transcribe the bundled original French WAV and translate the same audio into English. Reopen the stream for each independent request. No AIAgent, tools, Responses API, or speech generation. Open exercises\exercise-109.' $body '43' 'EXERCISE 109'

        ConceptSlide 44 'Lab 100: ground answers with an agenda snapshot' `
            'Start with the simplest design: known conference data inside the instructions.' `
            @('PROVIDE THE EVIDENCE', 'SET THE ANSWER CONTRACT', 'UNDERSTAND THE TRADEOFF') `
            @(
                ,@('Embed agenda.json in the assembly.', 'Read the raw JSON once at startup.', 'Include it in agent instructions.', 'This is direct context grounding,', 'not a retrieval pipeline or RAG.')
                ,@('Use only the supplied agenda.', 'Include day, time, room, speakers.', 'All times are local Warsaw time.', 'Ask when the request is vague.', 'Say when the agenda lacks', 'the answer; do not invent it.')
                ,@('The whole JSON is input each turn.', 'A stable prefix may get cached;', 'it still occupies context space.', 'The data is a snapshot, not live.', 'Compare answers with the table.', 'Part 2 fetches focused results.')
            ) `
            'Inspect /debug, ask a follow-up, and try a question the agenda cannot answer.' `
            "$repoUrl/tree/main/labs/lab-100" 'Source: Lab 100 / DevDays Buddy'

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
        SaveSlide 'slide-45.svg' 'Lab 100: DevDays Buddy' 'Part 1 lab 100: embed the .NET DeveloperDays Warsaw 2026 agenda as agenda.json, add it to the agent instructions as context, answer attendee questions with one AgentSession, and use Spectre.Console for the UI. Starter and solution in labs\lab-100.' $body '45' 'LAB 100'
    }

    if ($i -eq 1) {
        ConceptSlide 47 'The tool-call loop: the model proposes, code executes' `
            'One RunAsync can contain several model calls and tool invocations.' `
            @('1 / SELECT A TOOL', '2 / EXECUTE THE FUNCTION', '3 / ANSWER FROM THE RESULT') `
            @(
                ,@('Send instructions, messages,', 'and tool names + schemas.', 'The model returns a call name,', 'arguments, and a call ID.', 'It may answer without a tool.')
                ,@('The invocation layer dispatches', 'to the registered C# function.', 'Your code reads the actual clock.', 'Return a result for that call ID.', 'The model does not run arbitrary', 'C# merely by naming a function.')
                ,@('Send the tool result to the model.', 'It can answer or request more tools.', 'History includes calls and results.', 'DebugHistory makes them visible.', 'Inspect the evidence, not just', 'the final sentence.')
            ) `
            'Tools add current facts or actions; they do not make every final answer correct.' `
            'https://learn.microsoft.com/en-us/agent-framework/agents/tools/function-tools' 'Source: Microsoft Learn / function tools'

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
        SaveSlide 'slide-48.svg' 'Exercise 201: Chatbot Agent with Tools' 'Part 2 exercise 201: create an AIAgent around the Foundry chat client, use an AgentSession for history, disable server-side Responses storage, and expose current-time and current-date functions as tools executed by UseFunctionInvocation. Open exercises\exercise-201.' $body '48' 'EXERCISE 201'

        ConceptSlide 49 'Follow a tool call in the debugger' `
            'Explore exercise 201: stop inside the C# tools, then inspect the real session history.' `
            @('SET BREAKPOINTS', 'FOLLOW THE INVOCATION', 'READ THE SESSION HISTORY') `
            @(
                ,@('Open DateTimeTools.cs.', 'Break in GetCurrentTime()', 'and GetCurrentDate().', 'Run exercise 201 in the debugger.', 'Ask for current date and time.', 'Inspect localNow and the result.')
                ,@('Break at agent.RunAsync too.', 'The model requests a named tool.', 'UseFunctionInvocation runs C#.', 'Continue from the tool method:', 'its result goes back to the model.', 'Then inspect the final reply.', 'Tool choice and order may vary.')
                ,@('Open DebugHistory in Program.cs.', 'TryGetInMemoryChatHistory', 'reads the actual session.', 'Find FunctionCallContent:', 'Name and CallId identify the call.', 'Find FunctionResultContent:', 'match CallId; inspect Result.')
            ) `
            'Trace request -> tool call -> tool result -> answer; a tool is used only when the model requests it.' `
            "$repoUrl/tree/main/exercises/exercise-201" `
            'Source: Exercise 201 / DateTimeTools.cs and Program.cs, including DebugHistory'

        ConceptSlide 50 'Local models can call tools too' `
            'With a tool-capable model, Ollama can request the same C# functions as a cloud model.' `
            @('SOME MODELS SUPPORT TOOLS', 'THE SAME .NET TOOL LOOP', 'TRY IT IN EXERCISE 202') `
            @(
                ,@('Tool calling is a model feature.', 'Select a tool-capable model.', 'Ollama accepts tool schemas.', 'The model requests a function', 'by name with structured arguments.', 'Not every model supports this.', 'Check the exact model/version.')
                ,@('OllamaApiClient is IChatClient.', 'Set ChatOptions.Tools as in 201.', 'UseFunctionInvocation runs C#.', 'Pass the result back to the model.', 'AIAgent keeps the session.', 'The model does not execute code.')
                ,@('ollama pull qwen2.5:7b', 'Connect to localhost:11434.', 'Reuse the date and time tools.', 'Ask for current values.', 'Inspect breakpoints and history.', 'No Foundry credentials needed.', 'Other tools may still use networks.')
            ) `
            'Local inference can use the same tools; support and reliability depend on the model, runtime, and adapter.' `
            'https://docs.ollama.com/capabilities/tool-calling' `
            'Sources: Ollama / tool calling; workshop exercise 202'

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
        SaveSlide 'slide-51.svg' 'Exercise 202: Local Chatbot with Tools' 'Part 2 exercise 202: use AIAgent with an OllamaSharp client and AgentSession, exposing functions for current local time and date. No Foundry credentials or cloud inference are needed. Open exercises\exercise-202.' $body '51' 'EXERCISE 202'

        ConceptSlide 52 'Tool contracts are part of the prompt' `
            'Good names, descriptions, parameters, and results help the model choose correctly.' `
            @('FOCUSED CAPABILITY', 'CLEAR INPUT CONTRACT', 'USEFUL RESULT CONTRACT') `
            @(
                ,@('get_current_time is specific.', 'Description states local time', 'and includes the UTC offset.', 'Keep date and time separate.', 'AIFunctionFactory exposes', 'metadata from C# methods.')
                ,@('Use typed, described parameters.', 'State yyyy-MM-dd for dates.', 'State what time zone applies.', 'Do not expose IServiceProvider', 'or secrets as model arguments.', 'Validate arguments in code.')
                ,@('Return only needed information.', 'Include units, dates, and source.', 'Report no match explicitly.', 'For ambiguity, return candidates', 'and request clarification.', 'Never hide a failed lookup', 'behind a plausible default.')
            ) `
            'Lab 200 needs six focused tools, not a single "return the entire agenda" tool.' `
            'https://learn.microsoft.com/en-us/agent-framework/agents/tools/function-tools' 'Source: Microsoft Learn / function tools; Lab 200 tool contract'

        ConceptSlide 53 'Dependency injection belongs to the invocation layer' `
            'Exercise 203 separates model-supplied arguments from application-supplied services.' `
            @('REGISTER THE DEPENDENCY', 'SUPPLY INVOCATION CONTEXT', 'KEEP IT TESTABLE') `
            @(
                ,@('Register TimeProvider.System', 'in a ServiceCollection.', 'Tools resolve TimeProvider', 'rather than reading the clock', 'through a hard-coded dependency.')
                ,@('Pass services to AsAIAgent.', 'IServiceProvider is injected', 'during function invocation;', 'it is not in the model schema.', 'In 203, omit client-side', 'UseFunctionInvocation so the', 'agent creates the DI-aware layer.')
                ,@('Replace the registered clock', 'with a fixed TimeProvider.', 'The same tool method then', 'returns a predictable date/time.', 'Later, ASP.NET DI supplies', 'services to MCP tool classes.')
            ) `
            'The model chooses a capability; the application controls its dependencies.' `
            "$repoUrl/tree/main/exercises/exercise-203" 'Source: Exercise 203 / DI-aware function invocation'

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
        SaveSlide 'slide-54.svg' 'Exercise 203: Dependency Injection for Tools' 'Part 2 exercise 203: register TimeProvider in a dependency injection container, receive IServiceProvider in tool methods, pass the provider to AsAIAgent for function invocation, and disable server-side Responses storage to keep history in the local session. Open exercises\exercise-203.' $body '54' 'EXERCISE 203'

        ConceptSlide 55 'MCP connects capabilities across a process boundary' `
            'Model Context Protocol standardizes discovery and invocation, not model intelligence.' `
            @('AGENT APPLICATION / HOST', 'MCP CLIENT / CONNECTION', 'MCP SERVER / CAPABILITIES') `
            @(
                ,@('AIAgent uses the selected tools.', 'IChatClient calls Foundry.', 'The model requests a tool call.', 'The application invokes it.', 'These exercises use client-side', 'MCP, not provider-hosted MCP.')
                ,@('Connect over Streamable HTTP.', 'ListToolsAsync discovers', 'names, descriptions, schemas.', 'Pass those tools to the agent.', 'Keep the connection alive', 'for the conversation.')
                ,@('The server executes the lookup.', 'Learn MCP: remote documentation', '205: separate ASP.NET process', 'Lab 200: embedded agenda data', 'Results return via the client', 'and become model context.')
            ) `
            'The model sees tool contracts and results, not the server implementation.' `
            'https://learn.microsoft.com/en-us/agent-framework/agents/tools/local-mcp-tools' 'Source: Microsoft Learn / client-side MCP tools'

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
        SaveSlide 'slide-56.svg' 'Exercise 204: Microsoft Learn MCP Agent' 'Part 2 exercise 204: connect to https://learn.microsoft.com/api/mcp with the MCP C# SDK, list and describe available tools, then provide them to an AIAgent for a documentation conversation. DebugHistory displays tool calls and results. Open exercises\exercise-204.' $body '56' 'EXERCISE 204'

        ConceptSlide 57 'MCP is a transport contract, not a trust boundary' `
            'Exercise 205 hosts read-only tools; real deployments need explicit access controls.' `
            @('HOST THE CAPABILITY', 'DECIDE WHAT TO EXPOSE', 'TREAT RESULTS AS DATA') `
            @(
                ,@('ASP.NET registers tool classes.', 'Attributes describe the tools.', 'DI supplies TimeProvider.', 'Map the endpoint at /mcp.', 'The returned time belongs to', 'the server, not the attendee.')
                ,@('Only register intended tools.', 'Validate inputs on the server.', 'Authenticate protected endpoints;', 'authorize access to each resource.', 'Use least-privilege credentials.', 'Confirm consequential actions.')
                ,@('Remote content can be wrong', 'or contain malicious instructions.', 'Do not treat a tool result as', 'permission to override rules.', 'Do not send keys in tool results.', 'Expose timeouts and failures.')
            ) `
            'Public Learn MCP and localhost demos are not a template for an unauthenticated service.' `
            'https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices' 'Source: MCP / security best practices'

        ConceptSlide 58 'ASP.NET Core MCP: HTTP and SSE' `
            'Use the MCP SDK for tools over HTTP; SSE can stream server messages to clients.' `
            @('BUILD THE ASP.NET HOST', 'EXPOSE ATTRIBUTED TOOLS', 'CONNECT AN MCP CLIENT') `
            @(
                ,@('ModelContextProtocol.AspNetCore', 'builder.Services.AddMcpServer()', '  .WithHttpTransport()', '  .WithTools<DateTimeTools>();', 'var app = builder.Build();', 'app.MapMcp("/mcp");', 'app.Run();')
                ,@('Add [McpServerToolType].', 'Mark methods [McpServerTool].', 'Use [Description] for metadata.', 'DI supplies TimeProvider.', 'SDK handles JSON-RPC and SSE.', 'Streamable HTTP uses /mcp.', 'Not a raw SSE event endpoint.')
                ,@('URL: localhost:5285/mcp', 'Create HttpClientTransport.', 'Set StreamableHttp mode.', 'McpClient.CreateAsync initializes.', 'ListToolsAsync discovers tools.', 'Invoke tools; receive results.', 'Keep the server running.')
            ) `
            'SSE streams server messages; Streamable HTTP is the current MCP transport, replacing legacy HTTP+SSE.' `
            'https://modelcontextprotocol.io/specification/2025-11-25/basic/transports' `
            'Sources: MCP / Streamable HTTP specification; exercise 205 / ASP.NET Core MCP SDK'

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
        SaveSlide 'slide-59.svg' 'Exercise 205: Host Date and Time MCP Tools' 'Part 2 exercise 205: host the current date and time MCP tools in a standalone ASP.NET Core server, inject TimeProvider into the tool class, and discover and call them from a separate console AIAgent client over Streamable HTTP. Open exercises\exercise-205.' $body '59' 'EXERCISE 205'

        $body = ExerciseBody -exerciseNumber '206' -title 'Approve Before Executing' `
            -subtitle 'Keep the date and time tools; add a human approval gate.' `
            -projectPath 'exercises\exercise-206' `
            -stepTitles @('Wrap', 'Inspect', 'Decide') `
            -stepDetails @(
                ,@('Wrap both clock functions in', 'ApprovalRequiredAIFunction.')
                ,@('Read ToolApprovalRequestContent;', 'show the tool name and', 'its exact JSON arguments.')
                ,@('Create an approval or denial;', 'resume the same agent session.', 'Only approved calls execute.')
            ) `
            -takeaway 'The model proposes a call; framework code waits for an explicit human decision.'
        SaveSlide 'slide-60.svg' 'Exercise 206: Chatbot Agent with Tool Approval' 'Part 2 exercise 206: wrap the unchanged get_current_time and get_current_date tools from exercise 201 in ApprovalRequiredAIFunction. Inspect ToolApprovalRequestContent, show the function name, call ID, and empty arguments, and resume the same AgentSession with correlated approval or denial responses. Denied calls do not execute; no new tool scenario, MCP, or workflows.' $body '60' 'EXERCISE 206'

        ConceptSlide 61 'Lab 100 to Lab 200: fetch facts on demand' `
            'Keep the assistant experience; move agenda data and deterministic lookups to the server.' `
            @('LAB 100 / FULL CONTEXT', 'LAB 200 / FOCUSED LOOKUPS', 'COMPARE THE REAL TRADEOFF') `
            @(
                ,@('The client embeds agenda.json.', 'Instructions contain all slots.', 'Every request includes the agenda.', 'Simple setup, no tool round trip.', 'The model interprets the raw data.')
                ,@('Only the server embeds the JSON.', 'The client discovers six tools.', 'Short instructions direct lookups.', 'Results contain relevant facts.', 'Deterministic matching returns', 'ambiguity candidates to clarify.')
                ,@('Less agenda data per lookup,', 'but tools add schemas, network', 'latency, and extra model calls.', 'Results also accumulate in history.', 'Compare total tokens and accuracy,', 'not just the first prompt size.')
            ) `
            'Use /debug to trace a speaker lookup and a follow-up; verify the date, room, and time.' `
            "$repoUrl/tree/main/labs/lab-200" 'Source: Labs 100 and 200 / DevDays Buddy'

        $body = ExerciseBody -exerciseNumber '200' -badge 'LAB' -title 'DevDays Buddy MCP Tools' `
            -subtitle 'Replace one large prompt context with focused agenda lookups.' `
            -projectPath 'labs\lab-200' `
            -stepTitles @('Keep', 'Expose', 'Ask') `
            -stepDetails @(
                ,@('Embed agenda.json in the MCP', 'server; do not send the full', 'file to the model.')
                ,@('Build tools for conference,', 'speaker, and session lookups.')
                ,@('Connect a console AIAgent;', 'let it call tools for answers.')
            ) `
            -takeaway 'The server keeps the full agenda; the agent receives only requested tool results.'
        SaveSlide 'slide-62.svg' 'Lab 200: DevDays Buddy MCP Tools' 'Part 2 lab 200: embed the conference agenda in an ASP.NET MCP server, expose focused conference, speaker, and session lookup tools, and use them from a separate console AIAgent without putting the full agenda in its context.' $body '62' 'LAB 200'

        $body = ExerciseBody -exerciseNumber '200' -badge 'LAB' -title 'Build the Agenda MCP Server' `
            -subtitle 'Expose six focused conference, speaker, and session tools.' `
            -projectPath 'labs\lab-200' `
            -stepTitles @('Conference', 'Speakers', 'Sessions') `
            -stepDetails @(
                ,@('Return conference info and dates.')
                ,@('List speakers; look up a', 'profile by first, last, or full name.')
                ,@('List sessions by date; find', 'details by title or date and time.')
            ) `
            -takeaway 'Clear tool contracts and ambiguity messages help the model ask better follow-ups.'
        SaveSlide 'slide-63.svg' 'Lab 200: Build the Agenda MCP Server' 'Lab 200 MCP server tools: conference information and dates; the speaker list and speaker details by name; sessions for a date and session details by title or by date and starting time. Deterministic matching reports ambiguous results for clarification.' $body '63' 'LAB 200'

        $body = ExerciseBody -exerciseNumber '200' -badge 'LAB' -title 'Connect the DevDays Buddy Agent' `
            -subtitle 'Discover MCP tools and fetch only the agenda data the question needs.' `
            -projectPath 'labs\lab-200' `
            -stepTitles @('Connect', 'Discover', 'Ground') `
            -stepDetails @(
                ,@('Run the MCP server separately', 'from the console client.')
                ,@('List tools over Streamable HTTP;', 'add them to the agent.')
                ,@('Answer from selected tool results;', 'never embed the full agenda.')
            ) `
            -takeaway 'MCP separates agenda data and lookup logic from the conversational client.'
        SaveSlide 'slide-64.svg' 'Lab 200: Connect the DevDays Buddy Agent' 'Lab 200 console client: discover and invoke the separate ASP.NET MCP server tools over Streamable HTTP, while the Foundry-backed AIAgent retains conversation history without receiving the entire embedded agenda.' $body '64' 'LAB 200'
    }
}

$body = ExerciseBody -exerciseNumber '301' -title 'Terrible Startup Pitch' `
    -subtitle 'Manually pass one agent''s pitch to another agent for review.' `
    -projectPath 'exercises\exercise-301' `
    -stepTitles @('Create', 'Pitch', 'Review') `
    -stepDetails @(
        ,@('Create a wildly optimistic Founder', 'and a skeptical Investor agent.')
        ,@('Give the Founder a silly theme;', 'await its complete pitch.')
        ,@('Pass the exact pitch text', 'to the Investor in a fresh session;', 'print its FUND or PASS verdict.')
    ) `
    -takeaway 'Two awaited agent calls are enough for a simple handoff; no workflow is required.'
SaveSlide 'slide-66.svg' 'Exercise 301: Terrible Startup Pitch - Manual Orchestration' 'Part 3 exercise 301: create Founder and Investor agents with separate fresh sessions. Ordinary C# calls the Founder with a theme and forwards its exact response text to the Investor. No workflows, tools or revision loop.' $body '66' 'EXERCISE 301'

$body = ExerciseBody -exerciseNumber '302' -title 'Pitch with a Workflow' `
    -subtitle 'Keep the agents; let workflow edges deliver the pitch.' `
    -projectPath 'exercises\exercise-302' `
    -stepTitles @('Wrap', 'Connect', 'Observe') `
    -stepDetails @(
        ,@('Wrap each agent in a typed', 'string-to-string executor.')
        ,@('Add a Founder-to-Investor edge;', 'register the Investor as output.')
        ,@('Run the graph; print the pitch', 'from completion events and', 'the review from workflow output.')
    ) `
    -takeaway 'Same prompts and two model calls; the graph now owns the handoff and exposes events.'
SaveSlide 'slide-67.svg' 'Exercise 302: Terrible Startup Pitch - Workflow' 'Part 3 exercise 302: keep exercise 301 agents and prompts, wrap each in an Executor<string, string>, connect them with WorkflowBuilder.AddEdge, and observe completion and final output events using InProcessExecution.RunStreamingAsync.' $body '67' 'EXERCISE 302'

$body = ExerciseBody -exerciseNumber '303' -title 'Pause for Human Input' `
    -subtitle 'Let a human accept or replace the pitch before the Investor runs.' `
    -projectPath 'exercises\exercise-303' `
    -stepTitles @('Pause', 'Ask', 'Resume') `
    -stepDetails @(
        ,@('Insert a typed RequestPort', 'between Founder and Investor.')
        ,@('Handle RequestInfoEvent;', 'show the pitch and collect', 'human input in the console.')
        ,@('Create a matching response;', 'SendResponseAsync resumes', 'the same workflow run.')
    ) `
    -takeaway 'The graph waits for external input. This in-process pause is not durable checkpointing.'
SaveSlide 'slide-68.svg' 'Exercise 303: Terrible Startup Pitch - Human Input Pauses' 'Part 3 exercise 303: insert RequestPort<string, string> between Founder and Investor. Handle RequestInfoEvent in the console, accept or replace the pitch, and submit a correlated response with SendResponseAsync to resume the same run. Quit or EOF stops before the Investor. No tools or durable persistence.' $body '68' 'EXERCISE 303'

$body = ExerciseBody -exerciseNumber '304' -title 'Three Investors, One Pitch' `
    -subtitle 'Fan out to three wildly different personas; collect independent reviews.' `
    -projectPath 'exercises\exercise-304' `
    -stepTitles @('Pitch', 'Fan out', 'Collect') `
    -stepDetails @(
        ,@('Keep the Founder;', 'generate one ridiculous pitch.')
        ,@('Send that exact pitch to a', 'hype chaser, a bootstrapper,', 'and a doomsday prepper.')
        ,@('Run branches concurrently;', 'wait at a fan-in barrier;', 'print three labelled reviews.')
    ) `
    -takeaway 'Independent reviews can overlap in time; concurrency does not reduce model calls or tokens.'
SaveSlide 'slide-69.svg' 'Exercise 304: Terrible Startup Pitch - Concurrent Investors' 'Part 3 exercise 304: the Founder fans its exact pitch out to HypeInvestor, BootstrapInvestor, and DoomsdayInvestor. InProcessExecution.Concurrent runs the branches; a fan-in barrier and C# collector produce three labelled reviews without another model call. Four agents, fresh isolated sessions, no tools or debate loop.' $body '69' 'EXERCISE 304'

$body = ExerciseBody -exerciseNumber '300' -badge 'LAB' -title 'Plan My Conference Day' `
    -subtitle 'Coordinate three specialist agents with typed workflow handoffs.' `
    -projectPath 'labs\lab-300' `
    -stepTitles @('Pick', 'Schedule', 'Review') `
    -stepDetails @(
        ,@('Fetch one day through MCP;', 'pick relevant session IDs', 'and explain the matches.')
        ,@('Build an itinerary from candidates;', 'check dates, times and overlaps', 'with ordinary C# rules.')
        ,@('Approve or route feedback back;', 'allow at most two revisions;', 'print each workflow handoff.')
    ) `
    -takeaway 'Agents judge relevance; C# validates constraints; workflow edges control the bounded loop.'
SaveSlide 'slide-70.svg' 'Lab 300: Plan My Conference Day' 'Part 3 lab 300: build on Lab 200 with a Session Picker, Schedule Builder and Plan Reviewer in Microsoft Agent Framework Workflows. Pass structured session IDs, validate canonical agenda times in C#, and route rejected plans through at most two revisions.' $body '70' 'LAB 300'

$body = ExerciseBody -exerciseNumber '401' -title 'A Name Is Not Authentication' `
    -subtitle 'Whose secret snack stash can a chatbot open?' `
    -projectPath 'exercises\exercise-401' `
    -stepTitles @('Claim', 'Impersonate', 'Inspect') `
    -stepDetails @(
        ,@('Ask as Alice for the snack', 'hidden in her keyboard drawer.')
        ,@('Now claim to be Bob and ask', 'for his secret snack stash.')
        ,@('The tool trusts userName.', 'No credentials are checked;', 'a chat claim is not identity.')
    ) `
    -takeaway 'Intentionally unsafe: the model can choose a name, but cannot authenticate that person.'
SaveSlide 'slide-72.svg' 'Exercise 401: A Name Is Not Authentication' 'Part 4 exercise 401: the Secret Snack Stash tool accepts a model-supplied userName without authentication. Claim Alice or Bob to open their fictional stash. Intentionally vulnerable.' $body '72' 'EXERCISE 401'

$body = ExerciseBody -exerciseNumber '402' -title 'Sign In, Then Trust an ID?' `
    -subtitle 'Console authentication is only half of the boundary.' `
    -projectPath 'exercises\exercise-402' `
    -stepTitles @('Authenticate', 'Pass the ID', 'Challenge') `
    -stepDetails @(
        ,@('Use /auth in the console.', 'Check public demo credentials;', 'keep passwords out of chat.')
        ,@('Set userId in the system prompt', 'after sign-in. The model puts', 'that ID in the tool argument.')
        ,@('Try another userId.', 'The tool checks no ownership;', 'a prompt rule is not security.')
    ) `
    -takeaway 'Still intentionally unsafe: a model-controlled userId is not proof of the authenticated owner.'
SaveSlide 'slide-73.svg' 'Exercise 402: Authenticated but Model-Controlled Identity' 'Part 4 exercise 402: successful console /auth creates an agent with the signed-in userId in its system instructions. Questions are sent unchanged. The snack tool still accepts a model-controlled identity argument and cannot enforce ownership.' $body '73' 'EXERCISE 402'

$body = ExerciseBody -exerciseNumber '403' -title 'Trusted Identity Through DI' `
    -subtitle 'Keep the authenticated owner in application code, not tool arguments.' `
    -projectPath 'exercises\exercise-403' `
    -stepTitles @('Keep context', 'Inject', 'Verify') `
    -stepDetails @(
        ,@('Console /auth populates a', 'scoped UserContext. Reset', 'conversation on auth changes.')
        ,@('Pass services to AsAIAgent.', 'Static tool resolves UserContext;', 'no model-facing arguments.')
        ,@('Claim to be another person.', 'The tool still reads the owner', 'from trusted DI context.')
    ) `
    -takeaway 'The model requests the operation; a user-scoped tool enforces identity and ownership.'
SaveSlide 'slide-74.svg' 'Exercise 403: Trusted User Context Through DI' 'Part 4 exercise 403: console demo authentication sets a scoped UserContext. AsAIAgent supplies the scoped service provider to the static snack tool, which resolves that context. No identity parameter is exposed to the model. Signed-out and unknown owners are denied.' $body '74' 'EXERCISE 403'

$body = ExerciseBody -exerciseNumber '404' -title 'Authenticate Across MCP' `
    -subtitle 'Carry a protected bearer token, not a user name, over the process boundary.' `
    -projectPath 'exercises\exercise-404' `
    -stepTitles @('Sign in', 'Validate', 'Isolate') `
    -stepDetails @(
        ,@('Console /auth calls the server.', 'Keep its five-minute bearer token', 'in MCP HTTP headers, not prompts.')
        ,@('Protect /mcp with authorization.', 'Build the request user context', 'from validated identity claims.')
        ,@('Inject context into the tool.', 'Stateless MCP isolates requests;', 'each user opens only their stash.')
    ) `
    -takeaway 'Demo login, real token validation: production needs HTTPS, an identity provider, and MCP OAuth.'
SaveSlide 'slide-75.svg' 'Exercise 404: Authenticated MCP Tools' 'Part 4 exercise 404: an ASP.NET Core MCP server issues protected opaque bearer tokens after demo sign-in. Stateless authenticated MCP requests use a DI user context derived from validated claims, not model arguments. Loopback workshop login, not production OAuth.' $body '75' 'EXERCISE 404'

$body = ExerciseBody -exerciseNumber '405' -title 'Call a Foundry Agent' `
    -subtitle 'Chat with a versioned Prompt Agent: its definition lives in Foundry.' `
    -projectPath 'exercises\exercise-405' `
    -stepTitles @('Authenticate', 'Connect', 'Converse') `
    -stepDetails @(
        ,@('Use ClientSecretCredential:', 'tenant ID, client ID, client secret.', 'Grant the app project access.')
        ,@('Create AIProjectClient.', 'AsAIAgent: use name and version.', 'CreateConversationSessionAsync.')
        ,@('Ask about capabilities first.', 'Print the conversation ID;', 'reuse the session until quit.')
    ) `
    -takeaway 'Foundry owns the versioned agent and conversation. Managed identity removes the client secret.'
SaveSlide 'slide-76.svg' 'Exercise 405: Call a Microsoft Foundry Agent' 'Part 4 exercise 405: authenticate with ClientSecretCredential and connect to a named/versioned Foundry Prompt Agent through AIProjectClient.AsAIAgent. CreateConversationSessionAsync creates server-side history for the capabilities prompt and interactive chat. The README also explains managed identity.' $body '76' 'EXERCISE 405'

$body = ExerciseBody -exerciseNumber '406' -title 'RAG with Vectors in Memory' `
    -subtitle 'Retrieve relevant handbook chunks before generating an answer.' `
    -projectPath 'exercises\exercise-406' `
    -stepTitles @('Index', 'Retrieve', 'Ground') `
    -stepDetails @(
        ,@('Split the bundled text into chunks;', 'embed with Foundry;', 'store vectors and text in RAM.')
        ,@('Embed the question with the', 'same model; use cosine search', 'to show the top three chunks.')
        ,@('Send only retrieved excerpts;', 'cite their source IDs;', 'admit missing evidence.')
    ) `
    -takeaway 'No database server is needed. In-memory search is local; embeddings and answers still use Foundry.'
SaveSlide 'slide-77.svg' 'Exercise 406: Real RAG with an In-Memory Vector Store' 'Part 4 exercise 406: chunk the fictional Lab Hub handbook, generate real 1536-dimensional embeddings, store records in CommunityToolkit.VectorData.InMemory, and perform cosine vector search for each question. A fresh AIAgent session answers using only the top three excerpts with chunk citations. Requires a separate embedding deployment; no external database, MCP server, or hosted agent.' $body '77' 'EXERCISE 406'

$body = ExerciseBody -exerciseNumber '407' -title 'Save and Restore a Session' `
    -subtitle 'Persist local conversation state without hosting an agent in Foundry.' `
    -projectPath 'exercises\exercise-407' `
    -stepTitles @('Save', 'Reset', 'Restore') `
    -stepDetails @(
        ,@('Chat, then use /save;', 'SerializeSessionAsync writes', 'the session state to local JSON.')
        ,@('Use /new or restart the app;', 'inspect the empty history;', 'the snapshot stays on disk.')
        ,@('Use /load to deserialize;', 'ask about an earlier fact;', 'inspect the restored messages.')
    ) `
    -takeaway 'Persist session state, not the agent definition. Protect snapshots; restored history still goes to Foundry.'
SaveSlide 'slide-78.svg' 'Exercise 407: Save and Restore a Local Agent Session' 'Part 4 exercise 407: explicitly serialize local AgentSession state using SerializeSessionAsync and restore it with DeserializeSessionAsync. Console /save, /load, /new, and /history show replacement and process-restart persistence. Local plaintext JSON is not a hosted conversation, agent definition, or workflow checkpoint.' $body '78' 'EXERCISE 407'

$body = ExerciseBody -exerciseNumber '408' -title 'Summarize Growing History' `
    -subtitle 'Keep recent messages; replace older conversation content with a summary.' `
    -projectPath 'exercises\exercise-408' `
    -stepTitles @('Configure', 'Compact', 'Inspect') `
    -stepDetails @(
        ,@('Use the built-in experimental', 'SummarizationCompactionStrategy', 'as the history provider reducer.')
        ,@('After more than three user turns,', 'summarize older message groups;', 'preserve the newest two groups.')
        ,@('Print the actual stored history;', 'check facts after compaction;', 'compare with saving a full session.')
    ) `
    -takeaway 'Compaction is lossy, not archival storage. Local history shrinks; summarization adds a Foundry call.'
SaveSlide 'slide-79.svg' 'Exercise 408: Compact Local History with Summaries' 'Part 4 exercise 408: opt into experimental built-in compaction, adapt SummarizationCompactionStrategy with AsChatReducer, and run it after messages are added to InMemoryChatHistoryProvider. More than three stored user turns triggers summarization, protecting the newest two non-system groups. Print the actual reduced history; disable Responses storage for answer and summary calls. No persistence or tools.' $body '79' 'EXERCISE 408'

$body = ExerciseBody -exerciseNumber '400' -badge 'LAB' -title 'A Foundry-Powered Planner' `
    -subtitle 'Keep Lab 300 workflows; host the Session Picker and its agenda in Foundry.' `
    -projectPath 'labs\lab-400' `
    -stepTitles @('Configure', 'Connect', 'Validate') `
    -stepDetails @(
        ,@('Attach agenda.json with File Search;', 'save a Prompt Agent version;', 'return session IDs and reasons.')
        ,@('Use the Foundry agent as picker;', 'keep scheduler and reviewer local;', 'start fresh sessions per plan.')
        ,@('Check IDs and times against JSON;', 'retain the two-revision limit;', 'show only approved itineraries.')
    ) `
    -takeaway 'Foundry owns retrieval and the picker; local workflow edges and C# still enforce the plan.'
SaveSlide 'slide-80.svg' 'Lab 400: A Foundry-Powered Planner' 'Part 4 lab 400: build on Lab 300 with a named/versioned Foundry Prompt Agent using File Search over agenda.json as Session Picker. Keep Schedule Builder and Plan Reviewer as in-process agents, validate against the identical local snapshot, and preserve the bounded review workflow. No MCP server is required.' $body '80' 'LAB 400'

$body = @(
    (Text 100 245 'Any questions?' 72 'heading')
    (Text 100 315 'Continue exploring the workshop materials' 30)
    "<a href='$repoUrl'><image x='690' y='370' width='540' height='540' href='$qrCode'/></a>"
) -join "`n"
SaveSlide 'slide-81.svg' 'Any questions?' 'Questions about the Microsoft Agent Framework workshop. Scan the QR code to open the workshop repository.' $body '81' 'THANK YOU'

Write-Host "Built selected slides in $slides"
