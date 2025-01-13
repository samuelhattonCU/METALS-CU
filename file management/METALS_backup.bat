@echo off

REM Define source and destination directories
set "SOURCE_DIR=C:\METALS"
set "DEST1=D:\METALS"
set "DEST2=E:\METALS"

REM Get current date and time for log file name
for /f "tokens=1-5 delims=/: " %%d in ("%date% %time%") do (
    set "LOG_DATE=%%d-%%e-%%f_%%g-%%h"
)

REM Define log file with date and time
set "LOG_FILE=C:\path\to\logs\backup_%LOG_DATE%.log"

REM Write start time to log file
echo Backup started at %date% %time% > "%LOG_FILE%"

REM Function to perform sync (called via CALL)
:sync_directory
echo Syncing %~1 to %~2... >> "%LOG_FILE%"
xcopy "%~1" "%~2" /E /I /Y /D >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo Error: Failed to copy %~1 to %~2 >> "%LOG_FILE%"
)
goto :eof

REM Function to count files and directories
:count_files
setlocal enabledelayedexpansion
set "COUNT=0"
for /r "%~1" %%f in (*) do (
    set /a COUNT+=1
)
endlocal & set "%~2=%COUNT%"
goto :eof

REM Main backup process
echo Counting files in source directory... >> "%LOG_FILE%"
call :count_files "%SOURCE_DIR%" SOURCE_COUNT
echo Total files to copy: %SOURCE_COUNT% >> "%LOG_FILE%"

set "CURRENT_COUNT=0"

REM Sync to DEST1
for /r "%SOURCE_DIR%" %%f in (*) do (
    set /a CURRENT_COUNT+=1
    call :sync_directory "%%f" "%DEST1%\%%~pf"
    <nul set /p =Progress: %CURRENT_COUNT% / %SOURCE_COUNT%`r
)

REM Sync to DEST2
set "CURRENT_COUNT=0"
for /r "%SOURCE_DIR%" %%f in (*) do (
    set /a CURRENT_COUNT+=1
    call :sync_directory "%%f" "%DEST2%\%%~pf"
    <nul set /p =Progress: %CURRENT_COUNT% / %SOURCE_COUNT%`r
)

echo. >> "%LOG_FILE%"
echo Backup completed at %date% %time%! >> "%LOG_FILE%"
pause