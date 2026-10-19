# Exports every chapter cart to a web-player .js under docs/ for GitHub Pages.
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File build_web.ps1
#
# docs/index.html is the PICO-8 shell + chapter picker (hand-kept, one file); it loads
# ?cart=<chapter>.js (default ch01.js). We export only the .js, with a *bare* filename
# and the working directory set to docs/, so the script src stays relative.

$ErrorActionPreference = "Stop"
$exe  = "C:\Program Files (x86)\PICO-8\pico8.exe"
$root = $PSScriptRoot
$docs = Join-Path $root "docs"
New-Item -ItemType Directory -Force -Path $docs | Out-Null

$chapters = Get-ChildItem (Join-Path $root "chapters") -Directory | Sort-Object Name
Push-Location $docs
try {
    foreach ($ch in $chapters) {
        $cart = Join-Path $ch.FullName "$($ch.Name).p8"
        if (-not (Test-Path $cart)) { continue }
        Write-Host "exporting $($ch.Name) ..."
        & $exe -export "$($ch.Name).js" "..\chapters\$($ch.Name)\$($ch.Name).p8"
    }
} finally {
    Pop-Location
}
Write-Host "done: $docs"
