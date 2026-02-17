@echo off
REM ============================================
REM  MASTER CONFIG
REM ============================================

set EDK2_DIR=D:\Tools-Extras\Efi_Build\edk2
set PROJECT_DIR=D:\Tools-Extras\Efi_Build\FirmwareProjects
set PKG_NAME=BoltPkg
set DSC_FILE=OvmfPkg/OvmfPkgX64.dsc
set ARCH=X64
set TOOLCHAIN=VS2022
set TARGET=RELEASE
set CPPCHECK_PATH=C:\Program Files\Cppcheck\cppcheck.exe

REM --- NASM (fix the warning) ---
set NASM_PREFIX=C:\Program Files\NASM\

REM --- Derived paths ---
set BUILD_OUTPUT=%EDK2_DIR%\Build\OvmfX64\%TARGET%_%TOOLCHAIN%
set OVMF_FD=%BUILD_OUTPUT%\FV\OVMF.fd
set SYMLINK_PATH=%EDK2_DIR%\%PKG_NAME%
set LOCAL_BUILD=%PROJECT_DIR%\build
set LOG_FILE=%PROJECT_DIR%\build.log
set LOG_PARSED=%PROJECT_DIR%\build_parsed.log

REM --- Ensure BaseTools binaries are in PATH ---
set PATH=%EDK2_DIR%\BaseTools\Bin\Win32;%EDK2_DIR%\BaseTools\BinWrappers\WindowsLike;%PATH%