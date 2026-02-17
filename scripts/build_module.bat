@echo off
REM ============================================
REM  Build single module
REM ============================================

call "%~dp0config.bat"
call "%~dp0detect_module.bat" %1 %2
if %ERRORLEVEL% NEQ 0 exit /b 1

REM --- Clean local build for this module ---
if exist "%LOCAL_BUILD%\%MODULE_NAME%" (
    rmdir /s /q "%LOCAL_BUILD%\%MODULE_NAME%"
)

echo.
echo ============================================
echo  Building: %MODULE_NAME%
echo  INF:      %MODULE_INF%
echo  Target:   %TARGET%
echo ============================================
echo.
echo [*] Building... please wait...
echo.

REM --- Write a temp build script that does the redirect ---
set TEMP_BUILD=%PROJECT_DIR%\_temp_build.bat
(
    echo @echo off
    echo cd /d %EDK2_DIR%
    echo call edksetup.bat
    echo build -p %DSC_FILE% -m %MODULE_INF% -a %ARCH% -t %TOOLCHAIN% -b %TARGET% -n 0
) > "%TEMP_BUILD%"

REM --- Run it with output captured ---
cmd /c "%TEMP_BUILD%" > "%LOG_FILE%" 2>&1
set BUILD_RESULT=%ERRORLEVEL%

REM --- Cleanup temp ---
del /f /q "%TEMP_BUILD%" >nul 2>&1

REM --- Show parsed output ---
call "%~dp0parse_log.bat"

if %BUILD_RESULT% NEQ 0 (
    echo.
    echo [X] BUILD FAILED for %MODULE_NAME%!
    echo [*] Full log: %LOG_FILE%
    exit /b 1
)

echo.
echo [OK] %MODULE_NAME% built successfully!
echo.

REM --- Copy output to local build folder ---
call "%~dp0copy_build.bat" %MODULE_NAME%
exit /b 0