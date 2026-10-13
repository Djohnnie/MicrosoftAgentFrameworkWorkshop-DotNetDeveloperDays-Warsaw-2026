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
  </style>
  <linearGradient id="accent" x1="0" y1="1" x2="1" y2="0">
    <stop stop-color="#bd0926"/><stop offset="1" stop-color="#ff6a3f"/>
  </linearGradient>
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

$sections = @(
    [pscustomobject]@{ Title = 'Introduction'; Subtitle = 'Introduction to GenAI'; Time = '09:00 - 09:30' }
    [pscustomobject]@{ Title = 'Part 1'; Subtitle = 'From LLM calls to agents'; Time = '09:30 - 11:00' }
    [pscustomobject]@{ Title = 'Part 2'; Subtitle = 'Giving agents capabilities: tools and MCP'; Time = '11:15 - 13:00' }
    [pscustomobject]@{ Title = 'Part 3'; Subtitle = 'Orchestrating agents and workflows'; Time = '13:45 - 15:15' }
    [pscustomobject]@{ Title = 'Part 4'; Subtitle = 'Making agents reliable and production-ready'; Time = '15:45 - 17:00' }
)
for ($i = 0; $i -lt $sections.Count; $i++) {
    $section = $sections[$i]
    $slideNumber = $i + 5
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
SaveSlide 'slide-10.svg' 'Any questions?' 'Questions about the Microsoft Agent Framework workshop. Scan the QR code to open the workshop repository.' $body '10' 'THANK YOU'

Write-Host "Built selected slides in $slides"
