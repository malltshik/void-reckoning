# Exports every chapter cart to a web-player .js under docs/ for GitHub Pages.
#   powershell -ExecutionPolicy Bypass -File build_web.ps1
#
# The real work is `python common/tools/p8check.py export <ch>`: it copies the sources into
# tmp/web/ with every comment stripped (the web export needs the *compressed* code under
# 15,360 bytes and comments cost bytes; tokens are unchanged) and runs PICO-8's -export
# from docs/ with a bare filename. docs/index.html is the PICO-8 shell + chapter picker
# (hand-kept, one file); it loads ?cart=<chapter>.js (default ch01.js).
#
# PICO-8 is found via $env:PICO8, else the default install path. Python via $env:PYTHON,
# else the `py -3` launcher. Stops on the first failure instead of shipping a stale .js.

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$tool = Join-Path $root "common\tools\p8check.py"
if ($env:PYTHON) { $pyExe = $env:PYTHON; $pyArgs = @() }
elseif (Get-Command py -ErrorAction SilentlyContinue) { $pyExe = "py"; $pyArgs = @("-3") }
else { throw "Python 3 not found (set `$env:PYTHON to a real python.exe; the 'python' alias is the Store stub)" }

$chapters = Get-ChildItem (Join-Path $root "chapters") -Directory | Sort-Object Name
foreach ($ch in $chapters) {
    if (-not (Test-Path (Join-Path $ch.FullName "$($ch.Name).p8"))) { continue }   # lore-only chapters
    & $pyExe @pyArgs $tool export $ch.Name
    if ($LASTEXITCODE -ne 0) { throw "export of $($ch.Name) failed" }
}
Write-Host "done: $(Join-Path $root 'docs')"
