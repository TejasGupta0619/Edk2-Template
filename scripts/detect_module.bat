@echo off
REM ============================================
REM  Detect module — sets MODULE_NAME, MODULE_INF, MODULE_DIR
REM  Usage: call detect_module.bat [name] [reldir]
REM ============================================

REM --- Read config without setlocal ---
set EDK2_DIR=D:\Tools-Extras\Efi_Build\edk2
set PROJECT_DIR=D:\Tools-Extras\Efi_Build\FirmwareProjects
set PKG_NAME=BoltPkg

REM --- Priority 1: Passed as argument ---
if "%1"=="" goto :picker

set "RAW=%~1"

REM Strip trailing slashes
if "%RAW:~-1%"=="\" set "RAW=%RAW:~0,-1%"
if "%RAW:~-1%"=="/" set "RAW=%RAW:~0,-1%"

REM Get just the folder name
for %%I in ("%RAW%") do set "MODULE_NAME=%%~nxI"

REM Skip non-module folders
if /i "%MODULE_NAME%"==".vscode" goto :picker
if /i "%MODULE_NAME%"=="scripts" goto :picker
if /i "%MODULE_NAME%"=="build" goto :picker
if /i "%MODULE_NAME%"=="FirmwareProjects" goto :picker
if /i "%MODULE_NAME%"=="" goto :picker

goto :validate

:picker
echo.
echo ============================================
echo  Available Modules
echo ============================================
echo.

setlocal EnableDelayedExpansion
set /a COUNT=0
for /D %%D in (%PROJECT_DIR%\*) do (
    if exist "%%D\*.inf" (
        set /a COUNT+=1
        echo   [!COUNT!] %%~nxD
        set "MOD_!COUNT!=%%~nxD"
    )
)

if %COUNT%==0 (
    echo   No modules found!
    endlocal
    exit /b 1
)

echo.
set /p CHOICE="Select module [1-%COUNT%]: "
call set "PICKED=%%MOD_%CHOICE%%%"
endlocal & set "MODULE_NAME=%PICKED%"

:validate
set "MODULE_INF=%PKG_NAME%/%MODULE_NAME%/%MODULE_NAME%.inf"
set "MODULE_DIR=%PROJECT_DIR%\%MODULE_NAME%"

echo [*] Module:     %MODULE_NAME%
echo [*] Module Dir: %MODULE_DIR%
echo [*] Module INF: %MODULE_INF%

if not exist "%MODULE_DIR%" (
    echo [X] Module directory not found: %MODULE_DIR%
    exit /b 1
)

if not exist "%MODULE_DIR%\%MODULE_NAME%.inf" (
    echo [X] INF not found: %MODULE_DIR%\%MODULE_NAME%.inf
    exit /b 1
)

exit /b 0