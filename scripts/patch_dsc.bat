@echo off
REM ============================================
REM  Auto-add ALL modules from project dir to DSC
REM ============================================
setlocal EnableDelayedExpansion

call "%~dp0config.bat"

set DSC_FULL=%EDK2_DIR%\%DSC_FILE:/=\%
set MARKER=# === %PKG_NAME% CUSTOM MODULES ===

REM --- Check if already patched ---
findstr /C:"%MARKER%" "%DSC_FULL%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    REM Remove old entries to refresh
    powershell -Command ^
        "(Get-Content '%DSC_FULL%') | Where-Object { $_ -notmatch '%PKG_NAME%' -and $_ -notmatch '=== %PKG_NAME%' } | Set-Content '%DSC_FULL%'"
)

REM --- Append all modules ---
echo.>> "%DSC_FULL%"
echo   %MARKER%>> "%DSC_FULL%"

for /D %%D in (%PROJECT_DIR%\*) do (
    if exist "%%D\%%~nxD.inf" (
        echo   %PKG_NAME%/%%~nxD/%%~nxD.inf>> "%DSC_FULL%"
        echo   [+] Added: %%~nxD
    )
)

echo [✓] DSC patched with all modules