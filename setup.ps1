# setup.ps1 - One-step build setup for LibraTrack (Windows / PowerShell)
# Usage:  .\setup.ps1
#
# Prerequisites (install once):
#   - CMake   : https://cmake.org/download/  (add to PATH during install)
#   - A C++17 compiler:
#       Visual Studio 2019+  OR  MinGW-w64 via MSYS2  OR  WSL/Git Bash
#   - Git     : https://git-scm.com

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host "|       LibraTrack - Setup             |" -ForegroundColor Cyan
Write-Host "+======================================+" -ForegroundColor Cyan
Write-Host ""

# -- Helper: install a package via winget -------------------------------------------
function Install-WingetPackage {
    param([string]$Name, [string]$WingetId)
    Write-Host "  Installing $Name via winget..." -ForegroundColor Yellow
    winget install --id $WingetId --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [X] Failed to install $Name automatically." -ForegroundColor Red
        Write-Host "      Please install it manually and re-run setup.ps1" -ForegroundColor Red
        exit 1
    }
    # Refresh PATH in the current session
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-Host "  [OK] $Name installed." -ForegroundColor Green
}

# -- Dependency checks (auto-install if missing) ------------------------------------
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  [!] winget not found - cannot auto-install dependencies." -ForegroundColor Yellow
    Write-Host "      Please install CMake and Git manually, then re-run setup.ps1" -ForegroundColor Yellow
    Write-Host "      CMake : https://cmake.org/download/" -ForegroundColor White
    Write-Host "      Git   : https://git-scm.com" -ForegroundColor White
    exit 1
}

foreach ($entry in @(
    @{ Tool = "cmake"; WingetId = "Kitware.CMake"    },
    @{ Tool = "git";   WingetId = "Git.Git"          }
)) {
    if (!(Get-Command $entry.Tool -ErrorAction SilentlyContinue)) {
        Write-Host "  [X] Missing: $($entry.Tool)" -ForegroundColor Red
        Install-WingetPackage -Name $entry.Tool -WingetId $entry.WingetId
    } else {
        $path = (Get-Command $entry.Tool).Source
        Write-Host "  [OK] Found: $($entry.Tool)  ($path)" -ForegroundColor Green
    }
}
Write-Host ""

# -- Check GCC version supports C++17 (requires >= 7) -------------------------------
function Test-GCCVersion {
    if (!(Get-Command g++ -ErrorAction SilentlyContinue)) { return $false }
    $verLine = g++ --version 2>&1 | Select-Object -First 1
    if ($verLine -match '(\d+)\.\d+\.\d+') { return ([int]$Matches[1] -ge 7) }
    return $false
}

# -- Check any C++17 capable compiler is present ------------------------------------
function Test-CppCompiler {
    if (Get-Command cl      -ErrorAction SilentlyContinue) { return $true }
    if (Get-Command clang++ -ErrorAction SilentlyContinue) { return $true }
    if (Test-GCCVersion)                                   { return $true }
    return $false
}

# -- Ensure a C++17 compiler is available (auto-install if not) ---------------------
if (!(Test-CppCompiler)) {
    $gppOld = (Get-Command g++ -ErrorAction SilentlyContinue) -and !(Test-GCCVersion)
    if ($gppOld) {
        Write-Host "  [!] MinGW GCC is too old for C++17 - installing updated LLVM/Clang..." -ForegroundColor Yellow
    } else {
        Write-Host "  [!] No C++17 compiler found - installing LLVM/Clang + Ninja..." -ForegroundColor Yellow
    }
    Install-WingetPackage -Name "LLVM (clang++)" -WingetId "LLVM.LLVM"
    Install-WingetPackage -Name "Ninja"           -WingetId "Ninja-build.Ninja"
    Write-Host "  [OK] C++17 compiler ready." -ForegroundColor Green
}
Write-Host ""

# -- Detect best available CMake generator ------------------------------------------
function Get-CMakeGenerator {
    # clang++ + ninja (freshly installed or pre-existing)
    if ((Get-Command clang++ -ErrorAction SilentlyContinue) -and
        (Get-Command ninja   -ErrorAction SilentlyContinue)) {
        $env:CC  = "clang"
        $env:CXX = "clang++"
        return "Ninja"
    }
    # Ninja alone with a valid GCC
    if ((Get-Command ninja -ErrorAction SilentlyContinue) -and (Test-GCCVersion)) {
        return "Ninja"
    }
    # MinGW make with a valid GCC (>= 7)
    if ((Get-Command mingw32-make -ErrorAction SilentlyContinue) -and (Test-GCCVersion)) {
        return "MinGW Makefiles"
    }
    # MSVC cl.exe (VS Developer prompt or vcvarsall already run)
    if (Get-Command cl -ErrorAction SilentlyContinue) {
        return "NMake Makefiles"
    }
    # Visual Studio installations (pick newest available)
    foreach ($vsGen in @(
        "Visual Studio 17 2022",
        "Visual Studio 16 2019",
        "Visual Studio 15 2017"
    )) {
        cmake -G $vsGen --version 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { return $vsGen }
    }
    return $null
}

$generator = Get-CMakeGenerator
if ($generator) {
    Write-Host "  [OK] Using CMake generator: $generator" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  [X] Could not find a working C++17 build toolchain." -ForegroundColor Red
    Write-Host "      Try re-running setup.ps1, or install manually:" -ForegroundColor Yellow
    Write-Host "        VS Build Tools: https://visualstudio.microsoft.com/downloads/" -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host ""

# -- CMake configure -----------------------------------------------------------------
Write-Host "[1/2] Configuring build..." -ForegroundColor White
$cmakeArgs = @("-S", ".", "-B", "build", "-DCMAKE_BUILD_TYPE=Debug")
if ($generator) { $cmakeArgs += @("-G", $generator) }
cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  [X] CMake configure failed." -ForegroundColor Red
    Write-Host "      Make sure a C++17 compiler is installed:" -ForegroundColor Yellow
    Write-Host "        VS Build Tools : https://visualstudio.microsoft.com/downloads/" -ForegroundColor White
    Write-Host "        MinGW-w64      : https://www.msys2.org/" -ForegroundColor White
    exit 1
}
Write-Host ""

# -- Build ---------------------------------------------------------------------------
Write-Host "[2/2] Building..." -ForegroundColor White
cmake --build build --config Debug
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  [X] Build failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  [OK] Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Run the test for a specific issue:" -ForegroundColor White
Write-Host "    .\check.ps1 [issue-number]" -ForegroundColor Cyan
Write-Host "  Examples:" -ForegroundColor White
Write-Host "    .\check.ps1 1    - tests your fix for Issue #01" -ForegroundColor Cyan
Write-Host "    .\check.ps1 42   - tests your fix for Issue #42" -ForegroundColor Cyan
Write-Host ""
