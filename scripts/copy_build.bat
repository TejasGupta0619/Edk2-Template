@echo off
REM ============================================
REM  Copy build artifacts to local build folder
REM  Usage: copy_build.bat [ModuleName]
REM ============================================

call "%~dp0config.bat"

set SPECIFIC_MODULE=%1

REM --- Recalculate BUILD_OUTPUT in case TARGET changed ---
set BUILD_OUTPUT=%EDK2_DIR%\Build\OvmfX64\%TARGET%_%TOOLCHAIN%

REM --- Create local build dir ---
if not exist "%LOCAL_BUILD%" mkdir "%LOCAL_BUILD%"

echo.
echo -- Copying Build Artifacts (%TARGET%) ---------
echo.

if "%SPECIFIC_MODULE%"=="" goto :copy_all

REM ============================================
REM  Copy SPECIFIC module
REM ============================================

REM Your actual path from build log:
REM D:\Tools-Extras\Efi_Build\edk2\Build\OvmfX64\RELEASE_VS2022\X64\BoltPkg\HelloSmm\HelloSmm\OUTPUT\HelloSmm.efi
REM D:\Tools-Extras\Efi_Build\edk2\Build\OvmfX64\RELEASE_VS2022\X64\BoltPkg\HelloSmm\HelloSmm\DEBUG\HelloSmm.dll

set SRC=%BUILD_OUTPUT%\X64\%PKG_NAME%\%SPECIFIC_MODULE%\%SPECIFIC_MODULE%
set DST=%LOCAL_BUILD%\%SPECIFIC_MODULE%

echo [*] Source OUTPUT: %SRC%\OUTPUT
echo [*] Source DEBUG:  %SRC%\DEBUG
echo [*] Dest:          %DST%
echo.

REM --- Check source exists ---
if not exist "%SRC%\OUTPUT" (
    echo [X] Build output not found!
    echo [X] Expected: %SRC%\OUTPUT
    echo.
    echo [*] Searching for .efi in build tree...
    dir /s /b "%BUILD_OUTPUT%\X64\*%SPECIFIC_MODULE%.efi" 2>nul
    exit /b 1
)

if not exist "%DST%" mkdir "%DST%"

REM --- .efi ---
if exist "%SRC%\OUTPUT\%SPECIFIC_MODULE%.efi" (
    copy /y "%SRC%\OUTPUT\%SPECIFIC_MODULE%.efi" "%DST%\" >nul
    echo   [OK] %SPECIFIC_MODULE%.efi
)

REM --- .lib ---
if exist "%SRC%\OUTPUT\%SPECIFIC_MODULE%.lib" (
    copy /y "%SRC%\OUTPUT\%SPECIFIC_MODULE%.lib" "%DST%\" >nul
    echo   [OK] %SPECIFIC_MODULE%.lib
)

REM --- .map from OUTPUT ---
if exist "%SRC%\OUTPUT\%SPECIFIC_MODULE%.map" (
    copy /y "%SRC%\OUTPUT\%SPECIFIC_MODULE%.map" "%DST%\" >nul
    echo   [OK] %SPECIFIC_MODULE%.map
)

REM --- .dll.map from OUTPUT (copied there by EDK2 build) ---
if exist "%SRC%\OUTPUT\%SPECIFIC_MODULE%.dll.map" (
    copy /y "%SRC%\OUTPUT\%SPECIFIC_MODULE%.dll.map" "%DST%\" >nul
    echo   [OK] %SPECIFIC_MODULE%.dll.map
)

REM --- .dll from DEBUG subfolder ---
if exist "%SRC%\DEBUG\%SPECIFIC_MODULE%.dll" (
    copy /y "%SRC%\DEBUG\%SPECIFIC_MODULE%.dll" "%DST%\" >nul
    echo   [OK] %SPECIFIC_MODULE%.dll
)

REM --- .dll.map from DEBUG subfolder ---
if exist "%SRC%\DEBUG\%SPECIFIC_MODULE%.dll.map" (
    copy /y "%SRC%\DEBUG\%SPECIFIC_MODULE%.dll.map" "%DST%\" >nul
    echo   [OK] %SPECIFIC_MODULE%.dll.map [from DEBUG]
)

REM --- .map from DEBUG subfolder ---
if exist "%SRC%\DEBUG\%SPECIFIC_MODULE%.map" (
    copy /y "%SRC%\DEBUG\%SPECIFIC_MODULE%.map" "%DST%\%SPECIFIC_MODULE%.debug.map" >nul
    echo   [OK] %SPECIFIC_MODULE%.debug.map
)

REM --- .pdb (exists only in DEBUG target builds) ---
if exist "%SRC%\DEBUG\%SPECIFIC_MODULE%.pdb" (
    copy /y "%SRC%\DEBUG\%SPECIFIC_MODULE%.pdb" "%DST%\" >nul
    echo   [OK] %SPECIFIC_MODULE%.pdb
)

REM --- AutoGen.h ---
if exist "%SRC%\DEBUG\AutoGen.h" (
    copy /y "%SRC%\DEBUG\AutoGen.h" "%DST%\" >nul
    echo   [OK] AutoGen.h
)

REM --- AutoGen.c ---
if exist "%SRC%\DEBUG\AutoGen.c" (
    copy /y "%SRC%\DEBUG\AutoGen.c" "%DST%\" >nul
    echo   [OK] AutoGen.c
)

goto :summary

:copy_all
REM ============================================
REM  Copy ALL modules from package
REM ============================================
set PKG_BUILD=%BUILD_OUTPUT%\X64\%PKG_NAME%

if not exist "%PKG_BUILD%" (
    echo [X] Package build not found: %PKG_BUILD%
    exit /b 1
)

setlocal EnableDelayedExpansion
for /D %%D in (%PKG_BUILD%\*) do (
    set MOD=%%~nxD
    set MOD_SRC=%%D\!MOD!
    set MOD_DST=%LOCAL_BUILD%\!MOD!

    if not exist "!MOD_DST!" mkdir "!MOD_DST!"

    if exist "!MOD_SRC!\OUTPUT\!MOD!.efi" (
        copy /y "!MOD_SRC!\OUTPUT\!MOD!.efi" "!MOD_DST!\" >nul
        echo   [OK] !MOD!.efi
    )
    if exist "!MOD_SRC!\OUTPUT\!MOD!.map" (
        copy /y "!MOD_SRC!\OUTPUT\!MOD!.map" "!MOD_DST!\" >nul
    )
    if exist "!MOD_SRC!\DEBUG\!MOD!.dll" (
        copy /y "!MOD_SRC!\DEBUG\!MOD!.dll" "!MOD_DST!\" >nul
    )
    if exist "!MOD_SRC!\DEBUG\AutoGen.h" (
        copy /y "!MOD_SRC!\DEBUG\AutoGen.h" "!MOD_DST!\" >nul
    )
)
endlocal

REM --- Copy OVMF ---
echo.
echo -- Copying OVMF Firmware ----------------------

set OVMF_DST=%LOCAL_BUILD%\OVMF
if not exist "%OVMF_DST%" mkdir "%OVMF_DST%"

if exist "%BUILD_OUTPUT%\FV\OVMF.fd" (
    copy /y "%BUILD_OUTPUT%\FV\OVMF.fd" "%OVMF_DST%\" >nul
    echo   [OK] OVMF.fd
)
if exist "%BUILD_OUTPUT%\FV\OVMF_CODE.fd" (
    copy /y "%BUILD_OUTPUT%\FV\OVMF_CODE.fd" "%OVMF_DST%\" >nul
    echo   [OK] OVMF_CODE.fd
)
if exist "%BUILD_OUTPUT%\FV\OVMF_VARS.fd" (
    copy /y "%BUILD_OUTPUT%\FV\OVMF_VARS.fd" "%OVMF_DST%\" >nul
    echo   [OK] OVMF_VARS.fd
)

:summary
echo.
echo -- Local Build Contents -----------------------
echo.
dir /s /b "%LOCAL_BUILD%" 2>nul
echo.
echo ============================================