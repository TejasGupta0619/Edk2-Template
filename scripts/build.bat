@echo off
REM ============================================
REM  Full OVMF Build
REM  Usage: build.bat [release|debug|clean]
REM ============================================

call "%~dp0config.bat"

if /i "%1"=="release" set TARGET=RELEASE
if /i "%1"=="debug" set TARGET=DEBUG
if /i "%1"=="clean" (
    set TEMP_BUILD=%PROJECT_DIR%\_temp_build.bat
    (
        echo @echo off
        echo cd /d %EDK2_DIR%
        echo call edksetup.bat
        echo build -p %DSC_FILE% -a %ARCH% -t %TOOLCHAIN% -b %TARGET% clean
    ) > "%TEMP_BUILD%"
    cmd /c "%TEMP_BUILD%" >nul 2>&1
    del /f /q "%TEMP_BUILD%" >nul 2>&1
    echo [OK] Cleaned EDK2 build.
    exit /b 0
)

REM --- Verify symlink ---
if not exist "%SYMLINK_PATH%" (
    echo [X] Symlink not found!
    echo     Run as Admin: scripts\setup_symlink.bat
    exit /b 1
)

REM --- Clean local build folder ---
if exist "%LOCAL_BUILD%" (
    echo [*] Cleaning local build folder...
    rmdir /s /q "%LOCAL_BUILD%"
)

REM --- Patch DSC ---
call "%~dp0patch_dsc.bat"

echo.
echo ============================================
echo  EDK2 OVMF Build
echo  Target:    %TARGET%
echo  Arch:      %ARCH%
echo  Toolchain: %TOOLCHAIN%
echo ============================================
echo.
echo [*] Building... please wait...
echo.

REM --- Write temp build script ---
set TEMP_BUILD=%PROJECT_DIR%\_temp_build.bat
(
    echo @echo off
    echo cd /d %EDK2_DIR%
    echo call edksetup.bat
    echo build -p %DSC_FILE% -a %ARCH% -t %TOOLCHAIN% -b %TARGET% -n 0
) > "%TEMP_BUILD%"

REM --- Run with redirect ---
cmd /c "%TEMP_BUILD%" > "%LOG_FILE%" 2>&1
set BUILD_RESULT=%ERRORLEVEL%

del /f /q "%TEMP_BUILD%" >nul 2>&1

REM --- Parse log ---
call "%~dp0parse_log.bat"

if %BUILD_RESULT% NEQ 0 (
    echo.
    echo ============================================
    echo  [X] BUILD FAILED
    echo ============================================
    echo [*] Full log: %LOG_FILE%
    exit /b 1
)

echo.
echo ============================================
echo  [OK] BUILD SUCCESSFUL
echo ============================================
echo.

REM --- Copy build output ---
call "%~dp0copy_build.bat"

echo [OK] Done! Output in: %LOCAL_BUILD%
exit /b 0