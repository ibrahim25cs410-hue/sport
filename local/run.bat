@echo off
setlocal EnableExtensions
title Riyada API - Local Server

REM ── Configuration ──────────────────────────────────────────────────────────
set "API_PORT=61082"
set "API_DIR=%~dp0..\SportsApp\Api"
set "ENV_FILE=%~dp0riyada.local.env"
set "LOG_DIR=%~dp0logs"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Load optional environment overrides (FCM path, JWT, etc.)
if exist "%ENV_FILE%" (
  echo Loading %ENV_FILE%
  for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
    if not "%%~A"=="" set "%%~A=%%~B"
  )
)

set "ASPNETCORE_ENVIRONMENT=Development"
set "ASPNETCORE_URLS=http://0.0.0.0:%API_PORT%"

echo.
echo  Riyada API - local team server
echo  Listening on: http://0.0.0.0:%API_PORT%
echo  Swagger:      http://localhost:%API_PORT%/swagger
echo  Health:       http://localhost:%API_PORT%/api/health
echo.
echo  Teammates on same Wi-Fi: http://YOUR_LAN_IP:%API_PORT%/api
echo  Find IP: ipconfig  ^(IPv4 Address^)
echo.
echo  Press Ctrl+C to stop. Auto-restarts on crash.
echo.

cd /d "%API_DIR%"
if errorlevel 1 (
  echo ERROR: API folder not found: %API_DIR%
  pause
  exit /b 1
)

:restart
echo [%date% %time%] Starting Riyada API...
dotnet run --project "%API_DIR%\Riyada.Api.csproj" --no-launch-profile >> "%LOG_DIR%\api.log" 2>&1
echo.
echo [%date% %time%] API stopped. Restarting in 5 seconds...
timeout /t 5 /nobreak >nul
goto restart
