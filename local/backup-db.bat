@echo off
setlocal EnableExtensions

REM Backs up the SQLite database used by Riyada (not SQL Server/PostgreSQL).
set "API_DIR=%~dp0..\SportsApp\Api"
set "DB_FILE=%API_DIR%\sports.db"
set "BACKUP_DIR=%~dp0backups"
set "RETENTION_DAYS=14"

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

if not exist "%DB_FILE%" (
  echo Database not found: %DB_FILE%
  echo Start the API once so sports.db is created, then run this again.
  exit /b 1
)

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%i"
set "DEST=%BACKUP_DIR%\sports_%STAMP%.db"

echo Backing up to %DEST%
copy /Y "%DB_FILE%" "%DEST%" >nul
if errorlevel 1 (
  echo Backup failed.
  exit /b 1
)

REM Optional: copy to OneDrive if folder exists
set "ONEDRIVE=%USERPROFILE%\OneDrive\RiyadaBackups"
if exist "%USERPROFILE%\OneDrive" (
  if not exist "%ONEDRIVE%" mkdir "%ONEDRIVE%"
  copy /Y "%DEST%" "%ONEDRIVE%\sports_%STAMP%.db" >nul
  echo Also copied to %ONEDRIVE%
)

REM Delete backups older than RETENTION_DAYS
powershell -NoProfile -Command ^
  "Get-ChildItem '%BACKUP_DIR%\sports_*.db' | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-%RETENTION_DAYS%) } | Remove-Item -Force"

echo Backup complete.
exit /b 0
