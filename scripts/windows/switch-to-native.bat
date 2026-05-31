@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch-to-native.ps1"
if errorlevel 1 pause
