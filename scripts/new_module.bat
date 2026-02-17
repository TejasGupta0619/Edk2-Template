@echo off
REM ============================================
REM  Detect module from argument, current dir,
REM  or let user pick from available modules
REM ============================================

call "%~dp0config.bat"

REM --- Priority 1: Passed as argument ---
if not "%MODULE_NAME%"=="" goto :found
if not "%1"=="" (
    set MODULE_NAME=%~1
    goto :found
)

REM --- Priority 2: Detect from current open file's folder ---
REM (VSCode passes this via ${relativeFileDirname})
if not "%2"=="" (
    for %%I in ("%2") do set MODULE_NAME=%%~nI
    goto :found
)

REM --- Priority 3: Show picker ---
echo.
echo ============================================
echo  Available Modules:
echo ============================================
set /a COUNT=0
for /D %%D in (%PROJECT_DIR%\*) do (
    if exist "%%D\*.inf" (
        set /a COUNT+=1
        echo   [!COUNT!] %%~nxD
        set "MOD_!COUNT!=%%~nxD"
    )
)

if %COUNT%==0 (
    echo   No modules found! Run: scripts\new_module.bat
    exit /b 1
)

echo.
set /p CHOICE="Select module [1-%COUNT%]: "
call set MODULE_NAME=%%MOD_%CHOICE%%%

:found
set MODULE_INF=%PKG_NAME%/%MODULE_NAME%/%MODULE_NAME%.inf
set MODULE_DIR=%PROJECT_DIR%\%MODULE_NAME%

if not exist "%MODULE_DIR%" (
    echo [X] Module directory not found: %MODULE_DIR%
    exit /b 1
)

if not exist "%MODULE_DIR%\%MODULE_NAME%.inf" (
    echo [X] INF file not found: %MODULE_DIR%\%MODULE_NAME%.inf
    exit /b 1
)

echo [*] Module: %MODULE_NAME%
echo [*] INF:    %MODULE_INF%