param(
    [string]$SoftwareName = "",
    [string]$Version = "V1.0",
    [string]$SourceRoot = "lib",
    [string]$OutputDir = "copyright_materials"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SoftwareName)) {
    $SoftwareName = [string]::Concat(
        "StudyMemory",
        [char]0x8003,
        [char]0x7814,
        [char]0x590D,
        [char]0x4E60,
        [char]0x52A9,
        [char]0x624B,
        [char]0x8F6F,
        [char]0x4EF6
    )
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$resolvedSourceRoot = Join-Path $projectRoot $SourceRoot
$resolvedOutputDir = Join-Path $projectRoot $OutputDir

if (-not (Test-Path $resolvedSourceRoot)) {
    throw "Source root not found: $resolvedSourceRoot"
}

New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null

$sourceFiles = Get-ChildItem -Path $resolvedSourceRoot -Recurse -File -Filter *.dart |
    Sort-Object FullName

if ($sourceFiles.Count -eq 0) {
    throw "No Dart source files found under $resolvedSourceRoot"
}

$submissionPath = Join-Path $resolvedOutputDir "source_submission.txt"
$manifestPath = Join-Path $resolvedOutputDir "source_manifest.md"

$builder = New-Object System.Text.StringBuilder
$summary = @()
$totalNonEmptyLines = 0

for ($index = 0; $index -lt $sourceFiles.Count; $index++) {
    $file = $sourceFiles[$index]
    $normalizedProjectRoot = $projectRoot.TrimEnd("\")
    if ($file.FullName.StartsWith($normalizedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativePath = $file.FullName.Substring($normalizedProjectRoot.Length).TrimStart("\").Replace("\", "/")
    } else {
        $relativePath = $file.Name
    }
    $lines = Get-Content -Path $file.FullName -Encoding UTF8

    while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[-1])) {
        $lines = $lines[0..($lines.Count - 2)]
    }

    $nonEmptyLines = ($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    $totalNonEmptyLines += $nonEmptyLines

    $summary += [PSCustomObject]@{
        File = $relativePath
        TotalLines = $lines.Count
        NonEmptyLines = $nonEmptyLines
    }

    [void]$builder.AppendLine("// ============================================================================")
    [void]$builder.AppendLine("// Software: $SoftwareName")
    [void]$builder.AppendLine("// Version: $Version")
    [void]$builder.AppendLine("// File: $relativePath")
    [void]$builder.AppendLine("// ============================================================================")

    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        [void]$builder.AppendLine($lines[$lineIndex])
    }

    if ($index -lt ($sourceFiles.Count - 1)) {
        [void]$builder.AppendLine()
    }
}

$submissionContent = $builder.ToString().TrimEnd("`r", "`n")
[System.IO.File]::WriteAllText(
    $submissionPath,
    $submissionContent,
    [System.Text.UTF8Encoding]::new($false)
)

$estimatedPages = [Math]::Ceiling($totalNonEmptyLines / 50.0)
$manifestLines = New-Object System.Collections.Generic.List[string]

$manifestLines.Add("# Source Submission Notes")
$manifestLines.Add("")
$manifestLines.Add("- Software name: $SoftwareName")
$manifestLines.Add("- Version: $Version")
$manifestLines.Add("- Scope: all Dart source files under $SourceRoot")
$manifestLines.Add("- File count: $($sourceFiles.Count)")
$manifestLines.Add("- Non-empty line count: $totalNonEmptyLines")
$manifestLines.Add("- Estimated pages at 50 lines/page: $estimatedPages")
$manifestLines.Add("")
$manifestLines.Add("## Conclusion")
$manifestLines.Add("")
if ($estimatedPages -lt 60) {
    $manifestLines.Add("Estimated length is under 60 pages at 50 lines per page, so the full exported source should be submitted.")
} else {
    $manifestLines.Add("Estimated length reaches at least 60 pages at 50 lines per page, so you can paginate by the first 30 and last 30 continuous pages rule.")
}
$manifestLines.Add("")
$manifestLines.Add("## File List")
$manifestLines.Add("")
$manifestLines.Add("| File | Total lines | Non-empty lines |")
$manifestLines.Add("| --- | ---: | ---: |")

foreach ($item in $summary) {
    $manifestLines.Add("| $($item.File) | $($item.TotalLines) | $($item.NonEmptyLines) |")
}

$manifestLines.Add("")
$manifestLines.Add("## Print Tips")
$manifestLines.Add("")
$manifestLines.Add("1. Import `source_submission.txt` into Word or WPS.")
$manifestLines.Add("2. Set the page header to `"$SoftwareName $Version`".")
$manifestLines.Add("3. Use a monospace font, such as 10.5 pt or 12 pt.")
$manifestLines.Add("4. Enable line numbers and keep at least 50 effective code lines per page except the final page.")
$manifestLines.Add("5. Add continuous page numbers in the footer.")
$manifestLines.Add("6. Recheck for unrelated names, sensitive data, or third-party code before submission.")

[System.IO.File]::WriteAllLines(
    $manifestPath,
    $manifestLines,
    [System.Text.UTF8Encoding]::new($false)
)
