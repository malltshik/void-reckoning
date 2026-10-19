# Exports every chapter cart to a browser web player under docs/ for GitHub Pages.
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File build_web.ps1
#
# The html must be exported with a *bare* filename and the working directory set to
# docs/, otherwise PICO-8 writes an absolute path to the .js into the page.

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
        & $exe -export "$($ch.Name).html" "..\chapters\$($ch.Name)\$($ch.Name).p8"
    }
} finally {
    Pop-Location
}
Write-Host "done: $docs"
