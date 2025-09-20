@echo off
:: GTA V Server Installer - Windows Batch Launcher
:: This batch file provides an easy way to run the PowerShell installer

title GTA V Server Installer for Windows

echo.
echo ===============================================
echo    GTA V SERVER INSTALLER FOR WINDOWS
echo ===============================================
echo.
echo This installer supports:
echo - RageMP Server
echo - ALTV Server  
echo - FiveM TX Admin Server
echo.
echo Requirements:
echo - Windows 10/11 or Server 2019/2022
echo - Administrator privileges
echo - Internet connection
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running as Administrator
) else (
    echo [ERROR] This installer must be run as Administrator!
    echo.
    echo Please:
    echo 1. Right-click on this batch file
    echo 2. Select "Run as administrator"
    echo 3. Try again
    echo.
    pause
    exit /b 1
)

echo.
echo Checking PowerShell version...

:: Check PowerShell version
powershell -Command "if ($PSVersionTable.PSVersion.Major -ge 5) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] PowerShell 5.0+ detected
) else (
    echo [ERROR] PowerShell 5.0 or newer is required!
    echo Please update Windows or install PowerShell Core
    pause
    exit /b 1
)

echo.
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force" >nul 2>&1

if not exist "install.ps1" (
    echo [ERROR] install.ps1 not found in current directory!
    echo.
    echo Please ensure both files are in the same folder:
    echo - install.bat (this file)
    echo - install.ps1 (PowerShell script)
    echo.
    pause
    exit /b 1
)

echo [OK] PowerShell script found
echo.
echo ===============================================
echo Starting GTA V Server Installer...
echo ===============================================
echo.

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "install.ps1"

echo.
echo ===============================================
echo Installation completed!
echo ===============================================
echo.

if %errorLevel% == 0 (
    echo The installer finished successfully.
) else (
    echo The installer encountered an error.
    echo Check the log file for details: %USERPROFILE%\gta-server-install.log
)

echo.
echo Useful commands for server management:
echo.
echo Start servers:
echo   Start-Service "RageMP-Server"
echo   Start-Service "ALTV-Server"  
echo   Start-Service "FiveM-Server"
echo.
echo Stop servers:
echo   Stop-Service "RageMP-Server"
echo   Stop-Service "ALTV-Server"
echo   Stop-Service "FiveM-Server"
echo.
echo Check server status:
echo   Get-Service "*Server*"
echo.
echo Run these commands in PowerShell as Administrator
echo.
pause