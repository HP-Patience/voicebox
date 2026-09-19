@echo off
setlocal
cd /d "%~dp0"
if /i "%~1"=="--backend" goto backend
if /i "%~1"=="--web" goto web

if not exist "backend\venv\Scripts\python.exe" (
    echo ERROR: Missing backend virtual environment. See LOCAL_DEVELOPMENT.md.
    goto fail
)
if not exist ".env" (
    echo ERROR: Missing .env. See LOCAL_DEVELOPMENT.md.
    goto fail
)
where bun >nul 2>&1
if errorlevel 1 (
    echo ERROR: Bun is not on PATH.
    goto fail
)
if not exist "web\node_modules\vite\bin\vite.js" (
    echo ERROR: Missing frontend dependencies. See LOCAL_DEVELOPMENT.md.
    goto fail
)
if /i "%~1"=="--check" (
    echo PASS: Startup prerequisites found.
    exit /b 0
)
powershell -NoProfile -Command "$busy = Get-NetTCPConnection -State Listen -ErrorAction Stop | Where-Object { $_.LocalPort -in 5173,17493 }; if ($busy) { Write-Host 'ERROR: Port 5173 or 17493 is already in use. Close the existing service first.'; exit 1 }"
if errorlevel 1 goto fail

start "Voicebox Backend" "%ComSpec%" /d /c call "%~f0" --backend
start "Voicebox Web" "%ComSpec%" /d /c call "%~f0" --web
echo Waiting for Voicebox. Keep Clash running for model downloads.
powershell -NoProfile -Command "for ($i=0; $i -lt 60; $i++) { try { $h = Invoke-RestMethod 'http://127.0.0.1:17493/health' -TimeoutSec 2; $w = Invoke-WebRequest 'http://127.0.0.1:5173' -UseBasicParsing -TimeoutSec 2; if ($h.status -eq 'healthy' -and $w.StatusCode -eq 200) { exit 0 } } catch {}; Start-Sleep -Seconds 1 }; exit 1"
if errorlevel 1 (
    echo ERROR: Startup timed out. Check the backend and web windows for errors.
    goto fail
)
start "" "http://127.0.0.1:5173"
exit /b 0

:backend
"backend\venv\Scripts\python.exe" -m uvicorn backend.main:app --host 127.0.0.1 --port 17493 --env-file .env
if errorlevel 1 goto fail
exit /b 0

:web
call bun run dev:web -- --host 127.0.0.1 --port 5173 --strictPort
if errorlevel 1 goto fail
exit /b 0

:fail
if /i not "%~1"=="--check" pause
exit /b 1
