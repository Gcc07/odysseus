@echo off
setlocal

rem Launch Odysseus from the repo root (this script lives in scripts\windows).
cd /d "%~dp0..\.."

if not exist "venv\Scripts\python.exe" (
  echo Odysseus venv not found. Run setup first:
  echo   python -m venv venv
  echo   venv\Scripts\Activate.ps1
  echo   pip install -r requirements.txt
  echo   python setup.py
  pause
  exit /b 1
)

set "PORT=7000"
set "HOST=127.0.0.1"

rem Open the UI once the server is likely up.
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://%HOST%:%PORT%/"

call "venv\Scripts\activate.bat"
uvicorn app:app --host 0.0.0.0 --port %PORT%

if errorlevel 1 pause
