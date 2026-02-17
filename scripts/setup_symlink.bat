@echo off
REM ============================================
REM  RUN AS ADMINISTRATOR
REM ============================================
call "%~dp0config.bat"

if exist "%SYMLINK_PATH%" (
    echo [*] Symlink already exists: %SYMLINK_PATH%
    echo [*] Points to: %PROJECT_DIR%
    goto :eof
)

mklink /D "%SYMLINK_PATH%" "%PROJECT_DIR%"

if %ERRORLEVEL% EQU 0 (
    echo [✓] Symlink created:
    echo     %SYMLINK_PATH% → %PROJECT_DIR%
) else (
    echo [X] Failed! Right-click this script → "Run as Administrator"
)