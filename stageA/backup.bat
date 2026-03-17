@echo off
REM ============================================================
REM Oracle Database Backup Script
REM Creates a Data Pump export with today's date in the filename
REM ============================================================

REM Set date format for filename (YYYY-MM-DD)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set BACKUP_DATE=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%

REM Configuration - update these values
set ORACLE_USER=your_username
set ORACLE_PASS=your_password
set ORACLE_SID=your_sid
set BACKUP_DIR=DATA_PUMP_DIR
set BACKUP_FILE=backup_%BACKUP_DATE%.dmp
set LOG_FILE=backup_%BACKUP_DATE%.log

echo ============================================================
echo Oracle Database Backup
echo Date: %BACKUP_DATE%
echo Backup File: %BACKUP_FILE%
echo ============================================================

REM Run Data Pump Export
expdp %ORACLE_USER%/%ORACLE_PASS%@%ORACLE_SID% ^
  directory=%BACKUP_DIR% ^
  dumpfile=%BACKUP_FILE% ^
  logfile=%LOG_FILE% ^
  schemas=%ORACLE_USER%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Backup completed successfully!
    echo File: %BACKUP_FILE%
) else (
    echo.
    echo ERROR: Backup failed! Check %LOG_FILE% for details.
)

pause
