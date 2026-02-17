@echo off
REM ============================================
REM  Lint module with cppcheck
REM  Usage: lint.bat [ModuleName]
REM ============================================

call "%~dp0config.bat"
call "%~dp0detect_module.bat" %1 %2
if %ERRORLEVEL% NEQ 0 exit /b 1

echo [*] Linting: %MODULE_NAME%

REM --- Find cppcheck ---
set CPPCHECK=

REM Check if in PATH
where cppcheck >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set CPPCHECK=cppcheck
    goto :run
)

REM Check config.bat path
if defined CPPCHECK_PATH (
    if exist "%CPPCHECK_PATH%" (
        set "CPPCHECK=%CPPCHECK_PATH%"
        goto :run
    )
)

REM Check common install locations
if exist "C:\Program Files\Cppcheck\cppcheck.exe" (
    set "CPPCHECK=C:\Program Files\Cppcheck\cppcheck.exe"
    goto :run
)
if exist "C:\Program Files (x86)\Cppcheck\cppcheck.exe" (
    set "CPPCHECK=C:\Program Files (x86)\Cppcheck\cppcheck.exe"
    goto :run
)

REM Check winget/scoop typical paths
for /f "delims=" %%P in ('where /r "%LOCALAPPDATA%" cppcheck.exe 2^>nul') do (
    set "CPPCHECK=%%P"
    goto :run
)

echo [X] cppcheck not found anywhere!
echo.
echo     Searched:
echo       - PATH
echo       - C:\Program Files\Cppcheck\
echo       - C:\Program Files (x86)\Cppcheck\
echo       - %LOCALAPPDATA%
echo.
echo     Install: winget install Cppcheck.Cppcheck
echo     Then restart your terminal.
exit /b 1

:run
echo [*] Using: %CPPCHECK%
echo.

"%CPPCHECK%" ^
    --enable=warning,style,performance,portability ^
    --suppress=missingInclude ^
    --suppress=unusedFunction ^
    --suppress=unmatchedSuppression ^
    -I %EDK2_DIR%\MdePkg\Include ^
    -I %EDK2_DIR%\MdePkg\Include\X64 ^
    -I %EDK2_DIR%\MdeModulePkg\Include ^
    -I %EDK2_DIR%\OvmfPkg\Include ^
    -I %EDK2_DIR%\MdePkg\Include\Pi ^
    -D MDE_CPU_X64 ^
    -D EFIAPI=__cdecl ^
    --template="{file}:{line}: ({severity}) {message} [{id}]" ^
    "%MODULE_DIR%\*.c"

echo.
echo [OK] Lint complete for %MODULE_NAME%.