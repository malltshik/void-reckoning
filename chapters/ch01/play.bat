@echo off
rem Launch Chapter 1 in PICO-8 (double-click this file).
rem -root_path is the repo root so #include paths (common/..., chapters/...) resolve.
setlocal
set "HERE=%~dp0"
for %%I in ("%HERE%..\..") do set "ROOT=%%~fI"
set "CART=%HERE%ch01.p8"
set "PICO8=C:\Program Files (x86)\PICO-8\pico8.exe"

if not exist "%PICO8%" (
  echo PICO-8 not found at "%PICO8%"
  pause
  exit /b 1
)

if not exist "%CART%" (
  echo Cart not found at "%CART%"
  pause
  exit /b 1
)

start "" "%PICO8%" -root_path "%ROOT%" "%CART%"
