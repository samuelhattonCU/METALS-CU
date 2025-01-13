@echo off

REM Define source and destination directories
set "SOURCE_DIR=F:\DATA\METALS"
set "DEST1=H:\DATA\METALS"
set "DEST2=G:\DATA\METALS"

if not exist "%SOURCE_DIR%" echo Source dir doesn't exist
if not exist "%DEST1%" echo Dest 1 dir doesn't exist
if not exist "%DEST2%" echo Dest 2 dir doesn't exist


REM Get current date and time for log file name
for /f "tokens=1-7 delims=/: " %%d in ("%date% %time%") do (
    set "LOG_DATE=%%d-%%e-%%f_%%g-%%h-%%i-%%j"
)

REM Define log file with date and time
set "LOG_FILE=C:\METALS Utilities\METALS LOG\backup logs\backup_%LOG_DATE%.log"

REM Write start time to log and screen
echo.
echo Backup started at %date% %time%
echo Backup started at %date% %time% > "%LOG_FILE%"
echo.

REM Main backup process
echo Copying %SOURCE_DIR% to first destination (%DEST1%)...
echo Copying %SOURCE_DIR% to first destination (%DEST1%)... >> "%LOG_FILE%"
call :syncDirectory "%SOURCE_DIR%" "%DEST1%"
echo Initial backup completed at %date% %time%
echo Initial backup completed at %date% %time% >> "%LOG_FILE%"
echo.

echo Copying %DEST1% to second destination (%DEST2%)...
echo Copying %DEST1% to second destination (%DEST2%)... >> "%LOG_FILE%"
call :syncDirectory "%DEST1%" "%DEST2%"
echo Secondary backup completed at %date% %time%
echo Secondary backup completed at %date% %time% >> "%LOG_FILE%"
echo.

echo.
echo Backup completed at %date% %time%!
echo Backup completed at %date% %time%! >> "%LOG_FILE%"
echo.
pause

goto :eof

REM Function to perform sync (called via CALL)

:syncDirectory
echo Syncing "%~1" to "%~2"...
echo Syncing "%~1" to "%~2"... >> "%LOG_FILE%"
xcopy "%~1" "%~2" /E /I /Y /D >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo Error: Failed to copy "%~1" to "%~2"
    echo Error: Failed to copy "%~1" to "%~2" >> "%LOG_FILE%"
)
goto :eof