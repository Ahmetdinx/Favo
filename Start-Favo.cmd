@echo off
setlocal
cd /d "%~dp0"
title Favo - Baslatici
echo Favo ve Kitap baslatiliyor. Bu pencereyi acik birakin.
echo Hazir oldugunda tarayici otomatik acilacak.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Favo.ps1"
if errorlevel 1 (
  echo.
  echo Baslatma tamamlanamadi. Yukaridaki hata mesajini paylasin.
  echo Ayrintili kayitlar: %~dp0artifacts\run
  pause
)
endlocal