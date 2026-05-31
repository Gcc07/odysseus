@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch-to-docker.ps1"
if errorlevel 1 pause
