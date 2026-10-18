@echo off
rem Launch Void Reckoning - Chapter 1 in PICO-8 (double-click this file).
setlocal
set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "CART=%ROOT%\chapters\ch01\ch01.p8"
set "PICO8=C:\Program Files (x86)\PICO-8\pico8.exe"

if not exist "%PICO8%" (
  echo PICO-8 not found at "%PICO8%"
  echo Edit this file and fix the PICO8 path.
  pause
  exit /b 1
)

if not exist "%CART%" (
  echo Cart not found at "%CART%"
  pause
  exit /b 1
)

start "" "%PICO8%" -root_path "%ROOT%" "%CART%"
