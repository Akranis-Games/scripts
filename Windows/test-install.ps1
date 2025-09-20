# Test Script for GTA V Server Installer (Windows)
# This script tests the install.ps1 functionality

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host "Testing GTA V Server Installation Script for Windows..." -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""

$testResults = @()

# Test 1: Check if PowerShell script exists
Write-Host "Test 1: Checking if install.ps1 exists..." -ForegroundColor Yellow
if (Test-Path "install.ps1") {
    Write-Host "✅ install.ps1 found" -ForegroundColor Green
    $testResults += "PASS: Script file exists"
} else {
    Write-Host "❌ install.ps1 not found" -ForegroundColor Red
    $testResults += "FAIL: Script file missing"
    exit 1
}

# Test 2: Check PowerShell version
Write-Host "Test 2: Checking PowerShell version..." -ForegroundColor Yellow
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Write-Host "✅ PowerShell version $($PSVersionTable.PSVersion) is supported" -ForegroundColor Green
    $testResults += "PASS: PowerShell version compatible"
} else {
    Write-Host "❌ PowerShell version $($PSVersionTable.PSVersion) is too old" -ForegroundColor Red
    $testResults += "FAIL: PowerShell version incompatible"
}

# Test 3: Check if running as Administrator
Write-Host "Test 3: Checking Administrator privileges..." -ForegroundColor Yellow
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "✅ Running as Administrator" -ForegroundColor Green
    $testResults += "PASS: Administrator privileges"
} else {
    Write-Host "⚠️  Not running as Administrator" -ForegroundColor Yellow
    Write-Host "   Note: Installation requires Administrator privileges" -ForegroundColor Gray
    $testResults += "WARN: Not running as Administrator"
}

# Test 4: Check Windows version
Write-Host "Test 4: Checking Windows version..." -ForegroundColor Yellow
$osVersion = [System.Environment]::OSVersion.Version
if ($osVersion.Major -ge 10) {
    Write-Host "✅ Windows version $($osVersion) is supported" -ForegroundColor Green
    $testResults += "PASS: Windows version supported"
} else {
    Write-Host "❌ Windows version $($osVersion) is not supported" -ForegroundColor Red
    $testResults += "FAIL: Windows version not supported"
}

# Test 5: Check script syntax
Write-Host "Test 5: Checking PowerShell script syntax..." -ForegroundColor Yellow
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content "install.ps1" -Raw), [ref]$null)
    Write-Host "✅ Script syntax is valid" -ForegroundColor Green
    $testResults += "PASS: Script syntax valid"
} catch {
    Write-Host "❌ Script has syntax errors: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += "FAIL: Script syntax errors"
}

# Test 6: Check internet connectivity
Write-Host "Test 6: Checking internet connectivity..." -ForegroundColor Yellow
try {
    $connection = Test-NetConnection -ComputerName "google.com" -Port 80 -InformationLevel Quiet -ErrorAction Stop
    if ($connection) {
        Write-Host "✅ Internet connection available" -ForegroundColor Green
        $testResults += "PASS: Internet connectivity"
    } else {
        Write-Host "❌ No internet connection" -ForegroundColor Red
        $testResults += "FAIL: No internet connection"
    }
} catch {
    Write-Host "❌ Cannot test internet connection: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += "FAIL: Cannot test internet connection"
}

# Test 7: Check available disk space
Write-Host "Test 7: Checking available disk space..." -ForegroundColor Yellow
try {
    $systemDrive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
    $availableGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
    
    if ($availableGB -ge 10) {
        Write-Host "✅ Sufficient disk space: ${availableGB}GB available" -ForegroundColor Green
        $testResults += "PASS: Sufficient disk space"
    } else {
        Write-Host "❌ Insufficient disk space: ${availableGB}GB available (10GB required)" -ForegroundColor Red
        $testResults += "FAIL: Insufficient disk space"
    }
} catch {
    Write-Host "⚠️  Cannot check disk space: $($_.Exception.Message)" -ForegroundColor Yellow
    $testResults += "WARN: Cannot check disk space"
}

# Test 8: Check available RAM
Write-Host "Test 8: Checking available RAM..." -ForegroundColor Yellow
try {
    $computerInfo = Get-WmiObject -Class Win32_ComputerSystem
    $totalRAM = [math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)
    
    if ($totalRAM -ge 4) {
        Write-Host "✅ Sufficient RAM: ${totalRAM}GB total" -ForegroundColor Green
        $testResults += "PASS: Sufficient RAM"
    } else {
        Write-Host "⚠️  Low RAM: ${totalRAM}GB total (4GB recommended)" -ForegroundColor Yellow
        $testResults += "WARN: Low RAM"
    }
} catch {
    Write-Host "⚠️  Cannot check RAM: $($_.Exception.Message)" -ForegroundColor Yellow
    $testResults += "WARN: Cannot check RAM"
}

# Test 9: Check if ports are available
Write-Host "Test 9: Checking server ports..." -ForegroundColor Yellow
$ports = @(22005, 7788, 30120, 40120)
$portNames = @("RageMP", "ALTV", "FiveM Game", "TX Admin")

for ($i = 0; $i -lt $ports.Count; $i++) {
    try {
        $connection = Test-NetConnection -ComputerName "localhost" -Port $ports[$i] -InformationLevel Quiet -ErrorAction SilentlyContinue
        if ($connection) {
            Write-Host "⚠️  Port $($ports[$i]) ($($portNames[$i])) is in use" -ForegroundColor Yellow
        } else {
            Write-Host "✅ Port $($ports[$i]) ($($portNames[$i])) is available" -ForegroundColor Green
        }
    } catch {
        Write-Host "✅ Port $($ports[$i]) ($($portNames[$i])) is available" -ForegroundColor Green
    }
}

# Test 10: Test basic script functions
Write-Host "Test 10: Testing basic script functions..." -ForegroundColor Yellow
try {
    # Test if we can source the script without running main
    $scriptContent = Get-Content "install.ps1" -Raw
    
    # Check for required functions
    $requiredFunctions = @(
        "Show-Banner",
        "Install-RageMP",
        "Install-ALTV", 
        "Install-FiveM",
        "Show-MainMenu",
        "Show-ServerManagement"
    )
    
    $missingFunctions = @()
    foreach ($func in $requiredFunctions) {
        if ($scriptContent -notmatch "function $func") {
            $missingFunctions += $func
        }
    }
    
    if ($missingFunctions.Count -eq 0) {
        Write-Host "✅ All required functions found" -ForegroundColor Green
        $testResults += "PASS: All functions present"
    } else {
        Write-Host "❌ Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Red
        $testResults += "FAIL: Missing functions"
    }
} catch {
    Write-Host "❌ Cannot test script functions: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += "FAIL: Cannot test functions"
}

# Summary
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "Test Summary:" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

$passCount = ($testResults | Where-Object { $_ -match "^PASS:" }).Count
$failCount = ($testResults | Where-Object { $_ -match "^FAIL:" }).Count
$warnCount = ($testResults | Where-Object { $_ -match "^WARN:" }).Count

foreach ($result in $testResults) {
    if ($result -match "^PASS:") {
        Write-Host "✅ $($result.Substring(5))" -ForegroundColor Green
    } elseif ($result -match "^FAIL:") {
        Write-Host "❌ $($result.Substring(5))" -ForegroundColor Red
    } elseif ($result -match "^WARN:") {
        Write-Host "⚠️  $($result.Substring(5))" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Results: $passCount passed, $failCount failed, $warnCount warnings" -ForegroundColor White

if ($failCount -eq 0) {
    Write-Host ""
    Write-Host "🎉 All critical tests passed! The install.ps1 script should work correctly." -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  Right-click PowerShell → Run as Administrator" -ForegroundColor Gray
    Write-Host "  .\install.ps1                    # Interactive mode" -ForegroundColor Gray
    Write-Host "  .\install.ps1 -Help             # Show help" -ForegroundColor Gray
    Write-Host "  .\install.bat                   # Use batch launcher" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Note: Log files will be created at %USERPROFILE%\gta-server-install.log" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "❌ Some tests failed. Please fix the issues before running the installer." -ForegroundColor Red
    exit 1
}

if ($Verbose) {
    Write-Host ""
    Write-Host "System Details:" -ForegroundColor White
    Write-Host "  PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
    Write-Host "  OS Version: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Gray
    Write-Host "  Is Administrator: $isAdmin" -ForegroundColor Gray
    Write-Host "  Available Disk Space: ${availableGB}GB" -ForegroundColor Gray
    Write-Host "  Total RAM: ${totalRAM}GB" -ForegroundColor Gray
}