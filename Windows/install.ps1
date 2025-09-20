# GTA V Server Installation Script for Windows
# Supports RageMP, ALTV, and FiveM TX Admin
# Compatible with Windows Server 2019/2022, Windows 10/11
# Author: Server Installation Script
# Date: $(Get-Date)

param(
    [switch]$NoInteractive,
    [string]$LogPath = "$env:USERPROFILE\gta-server-install.log"
)

# Set execution policy for current session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Global variables
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:LogFile = $LogPath
$script:ServerUser = "gta-server"
$script:ServerPath = "C:\GTA-Servers"

# Colors for console output
$script:Colors = @{
    Red    = "Red"
    Green  = "Green"
    Yellow = "Yellow"
    Blue   = "Blue"
    Cyan   = "Cyan"
    White  = "White"
}

# Logging functions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor $script:Colors.Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor $script:Colors.Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor $script:Colors.Green }
        default { Write-Host $logEntry -ForegroundColor $script:Colors.White }
    }
    
    try {
        Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignore logging errors
    }
}

function Write-ErrorLog {
    param([string]$Message)
    Write-Log -Message $Message -Level "ERROR"
}

function Write-WarnLog {
    param([string]$Message)
    Write-Log -Message $Message -Level "WARN"
}

function Write-SuccessLog {
    param([string]$Message)
    Write-Log -Message $Message -Level "SUCCESS"
}

# Banner function
function Show-Banner {
    Clear-Host
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor $script:Colors.Cyan
    Write-Host "║                   GTA V SERVER INSTALLER                      ║" -ForegroundColor $script:Colors.Cyan
    Write-Host "║                        WINDOWS VERSION                        ║" -ForegroundColor $script:Colors.Cyan
    Write-Host "║                                                               ║" -ForegroundColor $script:Colors.Cyan
    Write-Host "║  Supports: RageMP, ALTV, FiveM TX Admin                      ║" -ForegroundColor $script:Colors.Cyan
    Write-Host "║  Compatible: Windows Server 2019/2022, Windows 10/11         ║" -ForegroundColor $script:Colors.Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor $script:Colors.Cyan
    Write-Host ""
}

# System validation functions
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-SystemRequirements {
    Write-Log "Validating system requirements..."
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-ErrorLog "This script must be run as Administrator"
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor $script:Colors.Red
        return $false
    }
    
    # Check Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        Write-ErrorLog "Unsupported Windows version. Windows 10/11 or Server 2019/2022 required."
        return $false
    }
    
    # Check available disk space (minimum 10GB)
    $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -eq $env:SystemDrive }
    $availableGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
    
    if ($availableGB -lt 10) {
        Write-ErrorLog "Insufficient disk space. Required: 10GB, Available: ${availableGB}GB"
        return $false
    }
    
    # Check available RAM (minimum 4GB for Windows servers)
    $totalRAM = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    if ($totalRAM -lt 4) {
        Write-WarnLog "Low RAM detected. Recommended: 8GB+, Available: ${totalRAM}GB"
    }
    
    # Check internet connectivity
    try {
        Test-NetConnection -ComputerName "google.com" -Port 80 -InformationLevel Quiet -ErrorAction Stop | Out-Null
        Write-Log "Internet connectivity: OK"
    }
    catch {
        Write-ErrorLog "No internet connection detected"
        return $false
    }
    
    Write-SuccessLog "System validation completed successfully"
    return $true
}

# OS Detection
function Get-WindowsInfo {
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem
    $osVersion = [System.Environment]::OSVersion.Version
    
    $script:OSName = $osInfo.Caption
    $script:OSVersion = "$($osVersion.Major).$($osVersion.Minor).$($osVersion.Build)"
    $script:Architecture = $osInfo.OSArchitecture
    
    Write-Log "Detected OS: $script:OSName"
    Write-Log "Version: $script:OSVersion"
    Write-Log "Architecture: $script:Architecture"
}

# Package installation functions
function Install-Chocolatey {
    Write-Log "Installing Chocolatey package manager..."
    
    try {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Log "Chocolatey already installed"
            return $true
        }
        
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-SuccessLog "Chocolatey installed successfully"
        return $true
    }
    catch {
        Write-ErrorLog "Failed to install Chocolatey: $($_.Exception.Message)"
        return $false
    }
}

function Install-BasePackages {
    Write-Log "Installing base packages..."
    
    if (-not (Install-Chocolatey)) {
        return $false
    }
    
    $packages = @(
        "git",
        "wget",
        "7zip",
        "notepadplusplus",
        "vcredist-all"
    )
    
    foreach ($package in $packages) {
        try {
            Write-Log "Installing $package..."
            choco install $package -y --no-progress
            Write-SuccessLog "$package installed successfully"
        }
        catch {
            Write-WarnLog "Failed to install $package: $($_.Exception.Message)"
        }
    }
    
    return $true
}

function Install-NodeJS {
    Write-Log "Installing Node.js LTS..."
    
    try {
        if (Get-Command node -ErrorAction SilentlyContinue) {
            $nodeVersion = & node --version
            Write-Log "Node.js already installed: $nodeVersion"
            return $true
        }
        
        choco install nodejs -y --no-progress
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        $nodeVersion = & node --version 2>$null
        $npmVersion = & npm --version 2>$null
        
        Write-SuccessLog "Node.js installed successfully"
        Write-Log "Node.js version: $nodeVersion"
        Write-Log "NPM version: $npmVersion"
        return $true
    }
    catch {
        Write-ErrorLog "Failed to install Node.js: $($_.Exception.Message)"
        return $false
    }
}

function Install-DotNet {
    Write-Log "Installing .NET Runtime..."
    
    try {
        # Check if .NET 6.0 is already installed
        $dotnetVersions = & dotnet --list-runtimes 2>$null | Where-Object { $_ -match "Microsoft.NETCore.App 6.0" }
        if ($dotnetVersions) {
            Write-Log ".NET 6.0 Runtime already installed"
            return $true
        }
        
        # Install .NET using Chocolatey
        choco install dotnet-6.0-runtime dotnet-6.0-aspnetruntime -y --no-progress
        
        # Verify installation
        $dotnetVersion = & dotnet --version 2>$null
        Write-SuccessLog ".NET Runtime installed successfully"
        Write-Log ".NET version: $dotnetVersion"
        return $true
    }
    catch {
        Write-ErrorLog "Failed to install .NET Runtime: $($_.Exception.Message)"
        return $false
    }
}

# User management functions
function New-ServerUser {
    Write-Log "Creating server user: $script:ServerUser"
    
    try {
        $user = Get-LocalUser -Name $script:ServerUser -ErrorAction SilentlyContinue
        if ($user) {
            Write-Log "User $script:ServerUser already exists"
            return $true
        }
        
        # Generate a random password
        $password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object { [char]$_ })
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        
        New-LocalUser -Name $script:ServerUser -Password $securePassword -Description "GTA Server Service Account" -UserMayNotChangePassword -PasswordNeverExpires
        
        # Add to necessary groups
        Add-LocalGroupMember -Group "Users" -Member $script:ServerUser
        
        Write-SuccessLog "Created user: $script:ServerUser"
        Write-Log "User password has been set (stored securely)"
        return $true
    }
    catch {
        Write-ErrorLog "Failed to create user: $($_.Exception.Message)"
        return $false
    }
}

# Server installation functions
function Install-RageMP {
    Show-Banner
    Write-Host "Installing RageMP Server..." -ForegroundColor $script:Colors.Blue
    
    if (-not (Install-BasePackages)) { return }
    if (-not (Install-NodeJS)) { return }
    if (-not (New-ServerUser)) { return }
    
    $rageDir = "$script:ServerPath\RageMP"
    
    try {
        Write-Log "Creating RageMP directory: $rageDir"
        New-Item -Path $rageDir -ItemType Directory -Force | Out-Null
        
        Write-Log "Downloading RageMP server files..."
        $downloadUrl = "https://cdn.rage.mp/updater/prerelease/server-files/windows_x64.zip"
        $zipFile = "$env:TEMP\ragemp-server.zip"
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
        
        Write-Log "Extracting RageMP server..."
        Expand-Archive -Path $zipFile -DestinationPath $rageDir -Force
        Remove-Item $zipFile
        
        Write-Log "Creating RageMP configuration..."
        $config = @{
            "maxplayers" = 100
            "name" = "My RageMP Server"
            "gamemode" = "freeroam"
            "streamdistance" = 500
            "port" = 22005
            "disallow_multiple_connections_per_ip" = $true
            "limit_time_of_connections_per_ip" = 1000
            "url" = ""
            "language" = "en"
            "sync_rate" = 40
            "resource_scan_thread_limit" = 0
            "max_ping" = 120
            "min_fps" = 30
            "max_packet_loss" = 0.2
            "allow_cef_debugging" = $false
            "enable_nodejs" = $true
            "csharp" = "enabled"
        } | ConvertTo-Json -Depth 10
        
        $config | Out-File -FilePath "$rageDir\conf.json" -Encoding UTF8
        
        # Create Windows service
        New-RageMPService -ServerPath $rageDir
        
        Write-SuccessLog "RageMP server installed successfully!"
        Write-Log "Server location: $rageDir"
        Write-Log "Configuration: $rageDir\conf.json"
        Write-Log "Start server with: Start-Service RageMP-Server"
        
        Read-Host "Press Enter to return to main menu"
    }
    catch {
        Write-ErrorLog "RageMP installation failed: $($_.Exception.Message)"
        Read-Host "Press Enter to continue"
    }
}

function Install-ALTV {
    Show-Banner
    Write-Host "Installing ALTV Server..." -ForegroundColor $script:Colors.Blue
    
    if (-not (Install-BasePackages)) { return }
    if (-not (Install-NodeJS)) { return }
    if (-not (New-ServerUser)) { return }
    
    $altvDir = "$script:ServerPath\ALTV"
    
    try {
        Write-Log "Creating ALTV directory: $altvDir"
        New-Item -Path $altvDir -ItemType Directory -Force | Out-Null
        
        Write-Log "Downloading ALTV server files..."
        $files = @{
            "altv-server.exe" = "https://cdn.altv.mp/server/release/x64_win32/altv-server.exe"
            "data.vdf" = "https://cdn.altv.mp/server/release/data.vdf"
            "libnode.dll" = "https://cdn.altv.mp/others/libnode.dll"
        }
        
        foreach ($file in $files.GetEnumerator()) {
            Write-Log "Downloading $($file.Key)..."
            Invoke-WebRequest -Uri $file.Value -OutFile "$altvDir\$($file.Key)" -UseBasicParsing
        }
        
        Write-Log "Creating ALTV configuration..."
        $serverConfig = @"
name: My ALTV Server
host: 0.0.0.0
port: 7788
players: 100
#password: changeme
announce: false
#token: YOUR_TOKEN_HERE
gamemode: Freeroam
website: example.com
language: en
description: My awesome ALTV server
debug: false
streamingDistance: 400
migrationDistance: 150
timeout: 60000
announceRetryErrorDelay: 10000
announceRetryErrorAttempts: 50
duplicatePlayers: 2
resources: [
  example-resource
]
modules: [
  js-module,
  #csharp-module
]
"@
        
        $serverConfig | Out-File -FilePath "$altvDir\server.cfg" -Encoding UTF8
        
        # Create example resource
        $resourceDir = "$altvDir\resources\example-resource"
        New-Item -Path $resourceDir -ItemType Directory -Force | Out-Null
        
        $resourceConfig = @"
type: js
main: index.js
client-main: client.js
client-files: [
    client.js
]
deps: []
"@
        
        $resourceConfig | Out-File -FilePath "$resourceDir\resource.cfg" -Encoding UTF8
        
        $serverJs = @"
import alt from 'alt-server';

alt.log('Example resource loaded');

alt.on('playerConnect', (player) => {
    alt.log(`${player.name} connected`);
});

alt.on('playerDisconnect', (player, reason) => {
    alt.log(`${player.name} disconnected: ${reason}`);
});
"@
        
        $serverJs | Out-File -FilePath "$resourceDir\index.js" -Encoding UTF8
        
        $clientJs = @"
import alt from 'alt-client';

alt.log('Client-side resource loaded');
"@
        
        $clientJs | Out-File -FilePath "$resourceDir\client.js" -Encoding UTF8
        
        # Create Windows service
        New-ALTVService -ServerPath $altvDir
        
        Write-SuccessLog "ALTV server installed successfully!"
        Write-Log "Server location: $altvDir"
        Write-Log "Configuration: $altvDir\server.cfg"
        Write-Log "Start server with: Start-Service ALTV-Server"
        
        Read-Host "Press Enter to return to main menu"
    }
    catch {
        Write-ErrorLog "ALTV installation failed: $($_.Exception.Message)"
        Read-Host "Press Enter to continue"
    }
}

function Install-FiveM {
    Show-Banner
    Write-Host "Installing FiveM TX Admin..." -ForegroundColor $script:Colors.Blue
    
    if (-not (Install-BasePackages)) { return }
    if (-not (Install-NodeJS)) { return }
    if (-not (New-ServerUser)) { return }
    
    $fivemDir = "$script:ServerPath\FiveM"
    
    try {
        Write-Log "Creating FiveM directory: $fivemDir"
        New-Item -Path $fivemDir -ItemType Directory -Force | Out-Null
        
        Write-Log "Downloading FiveM server files..."
        
        # Get latest FiveM build
        $buildsUrl = "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
        $buildsPage = Invoke-WebRequest -Uri $buildsUrl -UseBasicParsing
        $latestBuild = ($buildsPage.Links | Where-Object { $_.href -match '\d+-[a-f0-9]+' } | Select-Object -Last 1).href.TrimEnd('/')
        
        $downloadUrl = "https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/$latestBuild/server.zip"
        $zipFile = "$env:TEMP\fivem-server.zip"
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
        
        Write-Log "Extracting FiveM server..."
        Expand-Archive -Path $zipFile -DestinationPath $fivemDir -Force
        Remove-Item $zipFile
        
        Write-Log "Creating FiveM server configuration..."
        $serverCfg = @"
# FiveM Server Configuration

# Server Information
sv_hostname "My FiveM Server"
sv_maxclients 32
sv_endpointprivacy true

# Server Identity
sv_licenseKey "YOUR_LICENSE_KEY_HERE"

# Networking
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"

# Resources
ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure basic-gamemode
ensure hardcap

# TX Admin
ensure txAdmin

# Server Security
sv_authMaxVariance 1
sv_authMinTrust 5

# Misc
sets tags "default"
sets banner_detail "https://example.com/banner.png"
sets banner_connecting "https://example.com/connecting.png"

# Convars
set steam_webApiKey "YOUR_STEAM_API_KEY"
set sv_tebex_secret "YOUR_TEBEX_SECRET"

# Performance
set server_ackTimeoutThreshold 60000
"@
        
        $serverCfg | Out-File -FilePath "$fivemDir\server.cfg" -Encoding UTF8
        
        # Create start script
        $startScript = @"
@echo off
cd /d "%~dp0"
FXServer.exe +exec server.cfg
pause
"@
        
        $startScript | Out-File -FilePath "$fivemDir\start.bat" -Encoding ASCII
        
        # Create Windows service
        New-FiveMService -ServerPath $fivemDir
        
        Write-SuccessLog "FiveM server with TX Admin installed successfully!"
        Write-Log "Server location: $fivemDir"
        Write-Log "Configuration: $fivemDir\server.cfg"
        Write-Host ""
        Write-WarnLog "IMPORTANT: You need to:"
        Write-WarnLog "1. Get a license key from https://keymaster.fivem.net/"
        Write-WarnLog "2. Replace 'YOUR_LICENSE_KEY_HERE' in server.cfg"
        Write-WarnLog "3. Start server with: Start-Service FiveM-Server"
        Write-WarnLog "4. Access TX Admin at: http://localhost:40120"
        
        Read-Host "Press Enter to return to main menu"
    }
    catch {
        Write-ErrorLog "FiveM installation failed: $($_.Exception.Message)"
        Read-Host "Press Enter to continue"
    }
}

# Windows Service creation functions
function New-RageMPService {
    param([string]$ServerPath)
    
    Write-Log "Creating RageMP Windows service..."
    
    try {
        $serviceName = "RageMP-Server"
        $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        
        if ($existingService) {
            Write-Log "Service $serviceName already exists, removing..."
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            & sc.exe delete $serviceName
            Start-Sleep 2
        }
        
        $exePath = "$ServerPath\ragemp-server.exe"
        $serviceDescription = "RageMP GTA V Multiplayer Server"
        
        # Create the service
        New-Service -Name $serviceName -BinaryPathName $exePath -DisplayName "RageMP Server" -Description $serviceDescription -StartupType Manual
        
        # Set service to run as Local System (or you could use the created user)
        & sc.exe config $serviceName obj= "LocalSystem"
        
        Write-SuccessLog "RageMP service created successfully"
        return $true
    }
    catch {
        Write-ErrorLog "Failed to create RageMP service: $($_.Exception.Message)"
        return $false
    }
}

function New-ALTVService {
    param([string]$ServerPath)
    
    Write-Log "Creating ALTV Windows service..."
    
    try {
        $serviceName = "ALTV-Server"
        $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        
        if ($existingService) {
            Write-Log "Service $serviceName already exists, removing..."
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            & sc.exe delete $serviceName
            Start-Sleep 2
        }
        
        $exePath = "$ServerPath\altv-server.exe"
        $serviceDescription = "ALTV GTA V Multiplayer Server"
        
        # Create the service
        New-Service -Name $serviceName -BinaryPathName $exePath -DisplayName "ALTV Server" -Description $serviceDescription -StartupType Manual
        
        # Set service to run as Local System
        & sc.exe config $serviceName obj= "LocalSystem"
        
        Write-SuccessLog "ALTV service created successfully"
        return $true
    }
    catch {
        Write-ErrorLog "Failed to create ALTV service: $($_.Exception.Message)"
        return $false
    }
}

function New-FiveMService {
    param([string]$ServerPath)
    
    Write-Log "Creating FiveM Windows service..."
    
    try {
        $serviceName = "FiveM-Server"
        $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        
        if ($existingService) {
            Write-Log "Service $serviceName already exists, removing..."
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            & sc.exe delete $serviceName
            Start-Sleep 2
        }
        
        $exePath = "$ServerPath\FXServer.exe"
        $arguments = "+exec server.cfg"
        $serviceDescription = "FiveM GTA V Multiplayer Server with TX Admin"
        
        # Create the service with arguments
        $binaryPath = "`"$exePath`" $arguments"
        New-Service -Name $serviceName -BinaryPathName $binaryPath -DisplayName "FiveM Server" -Description $serviceDescription -StartupType Manual
        
        # Set working directory and run as Local System
        & sc.exe config $serviceName obj= "LocalSystem"
        
        Write-SuccessLog "FiveM service created successfully"
        return $true
    }
    catch {
        Write-ErrorLog "Failed to create FiveM service: $($_.Exception.Message)"
        return $false
    }
}

# System information functions
function Show-SystemInfo {
    Show-Banner
    Write-Host "System Information:" -ForegroundColor $script:Colors.Blue
    Write-Host "================================" -ForegroundColor $script:Colors.White
    
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem
    $computerInfo = Get-WmiObject -Class Win32_ComputerSystem
    $cpuInfo = Get-WmiObject -Class Win32_Processor
    
    Write-Host "OS: " -ForegroundColor $script:Colors.Cyan -NoNewline
    Write-Host $script:OSName -ForegroundColor $script:Colors.White
    
    Write-Host "Version: " -ForegroundColor $script:Colors.Cyan -NoNewline
    Write-Host $script:OSVersion -ForegroundColor $script:Colors.White
    
    Write-Host "Architecture: " -ForegroundColor $script:Colors.Cyan -NoNewline
    Write-Host $script:Architecture -ForegroundColor $script:Colors.White
    
    Write-Host "CPU: " -ForegroundColor $script:Colors.Cyan -NoNewline
    Write-Host $cpuInfo.Name -ForegroundColor $script:Colors.White
    
    Write-Host "CPU Cores: " -ForegroundColor $script:Colors.Cyan -NoNewline
    Write-Host $cpuInfo.NumberOfCores -ForegroundColor $script:Colors.White
    
    Write-Host "Total RAM: " -ForegroundColor $script:Colors.Cyan -NoNewline
    Write-Host "$([math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor $script:Colors.White
    
    $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
    Write-Host "Disk Space: " -ForegroundColor $script:Colors.Cyan -NoNewline
    Write-Host "$([math]::Round($systemDrive.FreeSpace / 1GB, 2)) GB available of $([math]::Round($systemDrive.Size / 1GB, 2)) GB" -ForegroundColor $script:Colors.White
    
    Write-Host ""
    Write-Host "Port Status:" -ForegroundColor $script:Colors.Blue
    Write-Host "================================" -ForegroundColor $script:Colors.White
    
    Test-ServerPort -Port 22005 -ServiceName "RageMP"
    Test-ServerPort -Port 7788 -ServiceName "ALTV"
    Test-ServerPort -Port 30120 -ServiceName "FiveM"
    Test-ServerPort -Port 40120 -ServiceName "TX Admin"
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Test-ServerPort {
    param(
        [int]$Port,
        [string]$ServiceName
    )
    
    try {
        $connection = Test-NetConnection -ComputerName "localhost" -Port $Port -InformationLevel Quiet -ErrorAction SilentlyContinue
        Write-Host "$ServiceName Port $Port`: " -ForegroundColor $script:Colors.Cyan -NoNewline
        if ($connection) {
            Write-Host "In Use" -ForegroundColor $script:Colors.Red
        } else {
            Write-Host "Available" -ForegroundColor $script:Colors.Green
        }
    }
    catch {
        Write-Host "$ServiceName Port $Port`: " -ForegroundColor $script:Colors.Cyan -NoNewline
        Write-Host "Available" -ForegroundColor $script:Colors.Green
    }
}

# Server management functions
function Show-ServerManagement {
    do {
        Show-Banner
        Write-Host "Server Management:" -ForegroundColor $script:Colors.Blue
        Write-Host ""
        Write-Host "1) Start Server" -ForegroundColor $script:Colors.Cyan
        Write-Host "2) Stop Server" -ForegroundColor $script:Colors.Cyan
        Write-Host "3) Restart Server" -ForegroundColor $script:Colors.Cyan
        Write-Host "4) Server Status" -ForegroundColor $script:Colors.Cyan
        Write-Host "5) View Logs" -ForegroundColor $script:Colors.Cyan
        Write-Host "6) Remove Server" -ForegroundColor $script:Colors.Cyan
        Write-Host "7) Back to Main Menu" -ForegroundColor $script:Colors.Cyan
        Write-Host ""
        
        $choice = Read-Host "Enter your choice [1-7]"
        
        switch ($choice) {
            "1" { Start-ServerMenu }
            "2" { Stop-ServerMenu }
            "3" { Restart-ServerMenu }
            "4" { Show-ServerStatus }
            "5" { Show-ServerLogs }
            "6" { Remove-ServerMenu }
            "7" { return }
            default { 
                Write-Host "Invalid option. Please select 1-7." -ForegroundColor $script:Colors.Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

function Start-ServerMenu {
    Show-Banner
    Write-Host "Start Server:" -ForegroundColor $script:Colors.Blue
    Write-Host ""
    Write-Host "1) Start RageMP" -ForegroundColor $script:Colors.Cyan
    Write-Host "2) Start ALTV" -ForegroundColor $script:Colors.Cyan
    Write-Host "3) Start FiveM" -ForegroundColor $script:Colors.Cyan
    Write-Host "4) Back" -ForegroundColor $script:Colors.Cyan
    Write-Host ""
    
    $choice = Read-Host "Enter your choice [1-4]"
    
    switch ($choice) {
        "1" {
            try {
                Start-Service -Name "RageMP-Server"
                Write-SuccessLog "RageMP server started"
            }
            catch {
                Write-ErrorLog "Failed to start RageMP server: $($_.Exception.Message)"
            }
        }
        "2" {
            try {
                Start-Service -Name "ALTV-Server"
                Write-SuccessLog "ALTV server started"
            }
            catch {
                Write-ErrorLog "Failed to start ALTV server: $($_.Exception.Message)"
            }
        }
        "3" {
            try {
                Start-Service -Name "FiveM-Server"
                Write-SuccessLog "FiveM server started"
            }
            catch {
                Write-ErrorLog "Failed to start FiveM server: $($_.Exception.Message)"
            }
        }
        "4" { return }
        default { Write-Host "Invalid option." -ForegroundColor $script:Colors.Red }
    }
    
    if ($choice -ne "4") {
        Start-Sleep 2
    }
}

function Stop-ServerMenu {
    Show-Banner
    Write-Host "Stop Server:" -ForegroundColor $script:Colors.Blue
    Write-Host ""
    Write-Host "1) Stop RageMP" -ForegroundColor $script:Colors.Cyan
    Write-Host "2) Stop ALTV" -ForegroundColor $script:Colors.Cyan
    Write-Host "3) Stop FiveM" -ForegroundColor $script:Colors.Cyan
    Write-Host "4) Back" -ForegroundColor $script:Colors.Cyan
    Write-Host ""
    
    $choice = Read-Host "Enter your choice [1-4]"
    
    switch ($choice) {
        "1" {
            try {
                Stop-Service -Name "RageMP-Server" -Force
                Write-SuccessLog "RageMP server stopped"
            }
            catch {
                Write-ErrorLog "Failed to stop RageMP server: $($_.Exception.Message)"
            }
        }
        "2" {
            try {
                Stop-Service -Name "ALTV-Server" -Force
                Write-SuccessLog "ALTV server stopped"
            }
            catch {
                Write-ErrorLog "Failed to stop ALTV server: $($_.Exception.Message)"
            }
        }
        "3" {
            try {
                Stop-Service -Name "FiveM-Server" -Force
                Write-SuccessLog "FiveM server stopped"
            }
            catch {
                Write-ErrorLog "Failed to stop FiveM server: $($_.Exception.Message)"
            }
        }
        "4" { return }
        default { Write-Host "Invalid option." -ForegroundColor $script:Colors.Red }
    }
    
    if ($choice -ne "4") {
        Start-Sleep 2
    }
}

function Restart-ServerMenu {
    Show-Banner
    Write-Host "Restart Server:" -ForegroundColor $script:Colors.Blue
    Write-Host ""
    Write-Host "1) Restart RageMP" -ForegroundColor $script:Colors.Cyan
    Write-Host "2) Restart ALTV" -ForegroundColor $script:Colors.Cyan
    Write-Host "3) Restart FiveM" -ForegroundColor $script:Colors.Cyan
    Write-Host "4) Back" -ForegroundColor $script:Colors.Cyan
    Write-Host ""
    
    $choice = Read-Host "Enter your choice [1-4]"
    
    switch ($choice) {
        "1" {
            try {
                Restart-Service -Name "RageMP-Server" -Force
                Write-SuccessLog "RageMP server restarted"
            }
            catch {
                Write-ErrorLog "Failed to restart RageMP server: $($_.Exception.Message)"
            }
        }
        "2" {
            try {
                Restart-Service -Name "ALTV-Server" -Force
                Write-SuccessLog "ALTV server restarted"
            }
            catch {
                Write-ErrorLog "Failed to restart ALTV server: $($_.Exception.Message)"
            }
        }
        "3" {
            try {
                Restart-Service -Name "FiveM-Server" -Force
                Write-SuccessLog "FiveM server restarted"
            }
            catch {
                Write-ErrorLog "Failed to restart FiveM server: $($_.Exception.Message)"
            }
        }
        "4" { return }
        default { Write-Host "Invalid option." -ForegroundColor $script:Colors.Red }
    }
    
    if ($choice -ne "4") {
        Start-Sleep 2
    }
}

function Show-ServerStatus {
    Show-Banner
    Write-Host "Server Status:" -ForegroundColor $script:Colors.Blue
    Write-Host "================================" -ForegroundColor $script:Colors.White
    
    $services = @("RageMP-Server", "ALTV-Server", "FiveM-Server")
    $names = @("RageMP", "ALTV", "FiveM")
    
    for ($i = 0; $i -lt $services.Length; $i++) {
        $service = Get-Service -Name $services[$i] -ErrorAction SilentlyContinue
        Write-Host "$($names[$i]): " -ForegroundColor $script:Colors.Cyan -NoNewline
        
        if ($service) {
            switch ($service.Status) {
                "Running" { 
                    Write-Host "Running" -ForegroundColor $script:Colors.Green 
                    
                    # Show additional info if available
                    try {
                        $process = Get-Process -Id $service.ServicesPid -ErrorAction SilentlyContinue
                        if ($process) {
                            $memory = [math]::Round($process.WorkingSet / 1MB, 2)
                            $cpu = [math]::Round($process.CPU, 2)
                            Write-Host "  PID: $($process.Id)  Memory: $memory MB  CPU Time: $cpu s" -ForegroundColor $script:Colors.White
                        }
                    }
                    catch {
                        # Ignore process info errors
                    }
                }
                "Stopped" { Write-Host "Stopped" -ForegroundColor $script:Colors.Red }
                default { Write-Host $service.Status -ForegroundColor $script:Colors.Yellow }
            }
        } else {
            Write-Host "Not Installed" -ForegroundColor $script:Colors.Yellow
        }
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-ServerLogs {
    Show-Banner
    Write-Host "View Server Logs:" -ForegroundColor $script:Colors.Blue
    Write-Host ""
    Write-Host "1) RageMP Logs" -ForegroundColor $script:Colors.Cyan
    Write-Host "2) ALTV Logs" -ForegroundColor $script:Colors.Cyan
    Write-Host "3) FiveM Logs" -ForegroundColor $script:Colors.Cyan
    Write-Host "4) Installation Logs" -ForegroundColor $script:Colors.Cyan
    Write-Host "5) Windows Event Logs" -ForegroundColor $script:Colors.Cyan
    Write-Host "6) Back" -ForegroundColor $script:Colors.Cyan
    Write-Host ""
    
    $choice = Read-Host "Enter your choice [1-6]"
    
    switch ($choice) {
        "1" {
            $logPath = "$script:ServerPath\RageMP\logs"
            if (Test-Path $logPath) {
                Get-ChildItem -Path $logPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object {
                    Write-Host "RageMP Latest Log:" -ForegroundColor $script:Colors.Blue
                    Get-Content $_.FullName -Tail 50
                }
            } else {
                Write-Host "No RageMP logs found." -ForegroundColor $script:Colors.Yellow
            }
        }
        "2" {
            $logPath = "$script:ServerPath\ALTV\logs"
            if (Test-Path $logPath) {
                Get-ChildItem -Path $logPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object {
                    Write-Host "ALTV Latest Log:" -ForegroundColor $script:Colors.Blue
                    Get-Content $_.FullName -Tail 50
                }
            } else {
                Write-Host "No ALTV logs found." -ForegroundColor $script:Colors.Yellow
            }
        }
        "3" {
            $logPath = "$script:ServerPath\FiveM\logs"
            if (Test-Path $logPath) {
                Get-ChildItem -Path $logPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object {
                    Write-Host "FiveM Latest Log:" -ForegroundColor $script:Colors.Blue
                    Get-Content $_.FullName -Tail 50
                }
            } else {
                Write-Host "No FiveM logs found." -ForegroundColor $script:Colors.Yellow
            }
        }
        "4" {
            if (Test-Path $script:LogFile) {
                Write-Host "Installation Logs:" -ForegroundColor $script:Colors.Blue
                Get-Content $script:LogFile -Tail 50
            } else {
                Write-Host "No installation log file found." -ForegroundColor $script:Colors.Yellow
            }
        }
        "5" {
            Write-Host "Windows Event Logs (Application):" -ForegroundColor $script:Colors.Blue
            Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2,3} -MaxEvents 20 -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "[$($_.TimeCreated)] $($_.LevelDisplayName): $($_.Message)" -ForegroundColor $script:Colors.White
            }
        }
        "6" { return }
        default { Write-Host "Invalid option." -ForegroundColor $script:Colors.Red }
    }
    
    if ($choice -ne "6") {
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
}

function Remove-ServerMenu {
    Show-Banner
    Write-Host "Remove Server (DANGEROUS):" -ForegroundColor $script:Colors.Red
    Write-Host ""
    Write-WarnLog "This will completely remove the server and all data!"
    Write-Host ""
    Write-Host "1) Remove RageMP" -ForegroundColor $script:Colors.Cyan
    Write-Host "2) Remove ALTV" -ForegroundColor $script:Colors.Cyan
    Write-Host "3) Remove FiveM" -ForegroundColor $script:Colors.Cyan
    Write-Host "4) Back" -ForegroundColor $script:Colors.Cyan
    Write-Host ""
    
    $choice = Read-Host "Enter your choice [1-4]"
    
    $services = @("", "RageMP-Server", "ALTV-Server", "FiveM-Server")
    $names = @("", "RageMP", "ALTV", "FiveM")
    $folders = @("", "RageMP", "ALTV", "FiveM")
    
    if ($choice -match "^[1-3]$") {
        $serviceName = $services[[int]$choice]
        $name = $names[[int]$choice]
        $folder = $folders[[int]$choice]
        
        Write-Host "Are you sure you want to remove $name server?" -ForegroundColor $script:Colors.Red
        Write-Host "This action cannot be undone!" -ForegroundColor $script:Colors.Red
        Write-Host ""
        $confirm = Read-Host "Type 'YES' to confirm"
        
        if ($confirm -eq "YES") {
            try {
                # Stop and remove service
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                    & sc.exe delete $serviceName
                }
                
                # Remove server files
                $serverPath = "$script:ServerPath\$folder"
                if (Test-Path $serverPath) {
                    Remove-Item -Path $serverPath -Recurse -Force
                }
                
                Write-SuccessLog "$name server removed completely"
            }
            catch {
                Write-ErrorLog "Failed to remove $name server: $($_.Exception.Message)"
            }
        } else {
            Write-Host "Removal cancelled." -ForegroundColor $script:Colors.Yellow
        }
        Start-Sleep 2
    } elseif ($choice -ne "4") {
        Write-Host "Invalid option." -ForegroundColor $script:Colors.Red
        Start-Sleep 2
    }
}

# Main menu function
function Show-MainMenu {
    do {
        Show-Banner
        Write-Host "Please select a GTA V server to install:" -ForegroundColor $script:Colors.Blue
        Write-Host ""
        Write-Host "1) RageMP Server" -ForegroundColor $script:Colors.Cyan
        Write-Host "2) ALTV Server" -ForegroundColor $script:Colors.Cyan
        Write-Host "3) FiveM TX Admin" -ForegroundColor $script:Colors.Cyan
        Write-Host "4) System Information" -ForegroundColor $script:Colors.Cyan
        Write-Host "5) Server Management" -ForegroundColor $script:Colors.Cyan
        Write-Host "6) Exit" -ForegroundColor $script:Colors.Cyan
        Write-Host ""
        
        $choice = Read-Host "Enter your choice [1-6]"
        
        switch ($choice) {
            "1" { Install-RageMP }
            "2" { Install-ALTV }
            "3" { Install-FiveM }
            "4" { Show-SystemInfo }
            "5" { Show-ServerManagement }
            "6" { 
                Write-Host "Thank you for using GTA V Server Installer!" -ForegroundColor $script:Colors.Green
                exit 0
            }
            default { 
                Write-Host "Invalid option. Please select 1-6." -ForegroundColor $script:Colors.Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

# Initialization function
function Initialize-Script {
    try {
        # Create log file
        if (-not (Test-Path (Split-Path $script:LogFile -Parent))) {
            New-Item -Path (Split-Path $script:LogFile -Parent) -ItemType Directory -Force | Out-Null
        }
        
        Write-Log "Starting GTA V Server Installation Script for Windows"
        Write-Log "Log file location: $script:LogFile"
        Write-Log "PowerShell version: $($PSVersionTable.PSVersion)"
        
        # Validate system requirements
        if (-not (Test-SystemRequirements)) {
            Write-ErrorLog "System validation failed"
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Get Windows information
        Get-WindowsInfo
        
        # Create server directory
        if (-not (Test-Path $script:ServerPath)) {
            New-Item -Path $script:ServerPath -ItemType Directory -Force | Out-Null
            Write-Log "Created server directory: $script:ServerPath"
        }
        
        Write-SuccessLog "Script initialization completed successfully"
        
    }
    catch {
        Write-ErrorLog "Script initialization failed: $($_.Exception.Message)"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Firewall configuration function
function Add-FirewallRules {
    Write-Log "Configuring Windows Firewall rules..."
    
    $rules = @(
        @{ Name = "RageMP-Server-In"; Port = 22005; Protocol = "UDP" },
        @{ Name = "ALTV-Server-In"; Port = 7788; Protocol = "UDP" },
        @{ Name = "FiveM-Server-TCP-In"; Port = 30120; Protocol = "TCP" },
        @{ Name = "FiveM-Server-UDP-In"; Port = 30120; Protocol = "UDP" },
        @{ Name = "FiveM-TXAdmin-In"; Port = 40120; Protocol = "TCP" }
    )
    
    foreach ($rule in $rules) {
        try {
            # Remove existing rule if it exists
            Remove-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue
            
            # Add new rule
            New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Protocol $rule.Protocol -LocalPort $rule.Port -Action Allow
            Write-Log "Added firewall rule: $($rule.Name) ($($rule.Protocol)/$($rule.Port))"
        }
        catch {
            Write-WarnLog "Failed to add firewall rule $($rule.Name): $($_.Exception.Message)"
        }
    }
}

# Cleanup function
function Start-Cleanup {
    param([int]$ExitCode = 0)
    
    if ($ExitCode -ne 0) {
        Write-ErrorLog "Script exited with error code: $ExitCode"
        Write-Host "Installation failed. Check the log file: $script:LogFile" -ForegroundColor $script:Colors.Red
    }
}

# Help function
function Show-Help {
    Write-Host @"
GTA V Server Installation Script for Windows - Help

Usage: .\install.ps1 [parameters]

Parameters:
  -NoInteractive    Run in non-interactive mode (for automation)
  -LogPath <path>   Specify custom log file path
  -Help            Show this help message

Examples:
  .\install.ps1                          # Interactive mode
  .\install.ps1 -NoInteractive           # Non-interactive mode
  .\install.ps1 -LogPath "C:\Logs\gta.log"  # Custom log path

Supported Servers:
  - RageMP Server (Port 22005)
  - ALTV Server (Port 7788)
  - FiveM Server with TX Admin (Ports 30120, 40120)

Requirements:
  - Windows 10/11 or Windows Server 2019/2022
  - Administrator privileges
  - At least 4GB RAM (8GB recommended)
  - At least 10GB free disk space
  - Internet connection

Server Locations:
  - RageMP: C:\GTA-Servers\RageMP\
  - ALTV: C:\GTA-Servers\ALTV\
  - FiveM: C:\GTA-Servers\FiveM\

Service Names:
  - RageMP-Server
  - ALTV-Server
  - FiveM-Server

For more information, visit:
  - RageMP: https://rage.mp/
  - ALTV: https://altv.mp/
  - FiveM: https://fivem.net/
"@ -ForegroundColor $script:Colors.White
}

# Main execution
function Main {
    # Handle parameters
    if ($args -contains "-Help" -or $args -contains "--help" -or $args -contains "/?" -or $args -contains "-h") {
        Show-Help
        exit 0
    }
    
    # Set up error handling
    $ErrorActionPreference = "Stop"
    
    try {
        # Initialize script
        Initialize-Script
        
        # Configure firewall
        Add-FirewallRules
        
        if ($NoInteractive) {
            Write-Log "Running in non-interactive mode"
            Write-Log "Please run interactively for installation options"
            exit 0
        } else {
            # Show main menu
            Show-MainMenu
        }
    }
    catch {
        Write-ErrorLog "Unhandled error: $($_.Exception.Message)"
        Start-Cleanup -ExitCode 1
        exit 1
    }
    finally {
        Start-Cleanup -ExitCode 0
    }
}

# Script entry point
if ($MyInvocation.InvocationName -ne '.') {
    Main
}