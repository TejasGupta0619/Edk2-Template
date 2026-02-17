@echo off
call "%~dp0config.bat"
cd /d %EDK2_DIR%
call edksetup.bat
build -p %DSC_FILE% -a %ARCH% -t %TOOLCHAIN% -b %TARGET% clean
echo [✓] Cleaned.