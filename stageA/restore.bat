@echo off
REM ============================================================
REM Oracle Database Restore Script
REM Restores from a Data Pump backup file
REM Run this on another machine to verify the backup works
REM ============================================================

REM Configuration - update these values for the target machine
set ORACLE_USER=your_username
set ORACLE_PASS=your_password
set ORACLE_SID=your_sid
set BACKUP_DIR=DATA_PUMP_DIR

REM Prompt for backup file name
set /p BACKUP_FILE="Enter backup filename (e.g., backup_2026-03-17.dmp): "

echo ============================================================
echo Oracle Database Restore
echo Backup File: %BACKUP_FILE%
echo ============================================================

REM Run Data Pump Import
impdp %ORACLE_USER%/%ORACLE_PASS%@%ORACLE_SID% ^
  directory=%BACKUP_DIR% ^
  dumpfile=%BACKUP_FILE% ^
  logfile=restore_%BACKUP_FILE%.log ^
  schemas=%ORACLE_USER% ^
  table_exists_action=replace

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Restore completed successfully!
) else (
    echo.
    echo ERROR: Restore failed! Check the log file for details.
)

pause
