@echo off
REM ============================================
REM  Parse EDK2 build log into clean output
REM ============================================
setlocal EnableDelayedExpansion

call "%~dp0config.bat"

if not exist "%LOG_FILE%" (
    echo [X] No build.log found
    exit /b 1
)

set ERROR_COUNT=0
set WARN_COUNT=0
set MODULE_COUNT=0

REM --- Create parsed log ---
echo. > "%LOG_PARSED%"
echo ============================================ >> "%LOG_PARSED%"
echo  BUILD REPORT >> "%LOG_PARSED%"
echo  %DATE% %TIME% >> "%LOG_PARSED%"
echo ============================================ >> "%LOG_PARSED%"

echo.
echo -- Modules Built ---------------------------
echo.

for /f "tokens=*" %%L in ('findstr /C:"Building ... " "%LOG_FILE%"') do (
    set /a MODULE_COUNT+=1
    set "LINE=%%L"
    for %%F in (!LINE!) do (
        if "%%~xF"==".inf" (
            echo   [!MODULE_COUNT!] %%~nF
            echo   [!MODULE_COUNT!] %%~nF >> "%LOG_PARSED%"
        )
    )
)

echo.
echo -- Errors -----------------------------------

set FOUND_ERRORS=0
for /f "tokens=*" %%L in ('findstr /i /C:": error C" /C:": error E" /C:": error LNK" /C:": error :" "%LOG_FILE%" 2^>nul') do (
    set "LINE=%%L"

    REM Skip linker flags and tool invocations
    echo !LINE! | findstr /i /C:"link.exe" /C:"lib.exe" /C:"cl.exe" /C:"/IGNORE" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        set /a ERROR_COUNT+=1
        set FOUND_ERRORS=1
        echo.
        echo   [ERROR !ERROR_COUNT!]
        echo   !LINE!
        echo. >> "%LOG_PARSED%"
        echo [ERROR !ERROR_COUNT!] !LINE! >> "%LOG_PARSED%"
    )
)

if %FOUND_ERRORS%==0 (
    echo   None [OK]
)

echo.
echo -- Warnings ---------------------------------

set FOUND_WARNINGS=0
for /f "tokens=*" %%L in ('findstr /i /C:": warning C" /C:": warning D" /C:": warning LNK" "%LOG_FILE%" 2^>nul') do (
    set "LINE=%%L"

    echo !LINE! | findstr /i /C:"link.exe" /C:"lib.exe" /C:"cl.exe" /C:"/WX" /C:"/W4" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        set /a WARN_COUNT+=1
        set FOUND_WARNINGS=1
        echo   [WARN !WARN_COUNT!] !LINE!
        echo [WARN !WARN_COUNT!] !LINE! >> "%LOG_PARSED%"
    )
)

if %FOUND_WARNINGS%==0 (
    echo   None [OK]
)

echo.
echo -- Summary ----------------------------------
echo.

for /f "tokens=*" %%L in ('findstr /C:"Build end time:" "%LOG_FILE%"') do echo   %%L
for /f "tokens=*" %%L in ('findstr /C:"Build total time:" "%LOG_FILE%"') do echo   %%L

echo.
echo   Modules:  %MODULE_COUNT%
echo   Errors:   %ERROR_COUNT%
echo   Warnings: %WARN_COUNT%
echo.
echo ============================================

echo. >> "%LOG_PARSED%"
echo Modules: %MODULE_COUNT%  Errors: %ERROR_COUNT%  Warnings: %WARN_COUNT% >> "%LOG_PARSED%"