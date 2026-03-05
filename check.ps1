# check.ps1 — Build and run the public test for a specific issue (Windows / PowerShell)
# Usage:  .\check.ps1 <issue-number>
# Example: .\check.ps1 5    or    .\check.ps1 42

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$IssueNumber
)

$ErrorActionPreference = "Stop"

# ── Argument validation ───────────────────────────────────────────────────────
if ($IssueNumber -notmatch '^\d+$') {
    Write-Host "Error: issue number must be a positive integer (got: '$IssueNumber')" -ForegroundColor Red
    exit 1
}

$num = [int]$IssueNumber
if ($num -lt 1 -or $num -gt 60) {
    Write-Host "Error: issue number must be between 1 and 60 (got: $num)" -ForegroundColor Red
    exit 1
}

$nn = $num.ToString("D2")
$testFilter = "Issue${nn}_Public"

Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   LibraTrack — Issue #$nn checker     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Check build dir exists ────────────────────────────────────────────────────
if (!(Test-Path "build")) {
    Write-Host "Build directory not found. Running setup first..." -ForegroundColor Yellow
    Write-Host ""
    & .\setup.ps1
}

# ── Rebuild to pick up student's latest changes ───────────────────────────────
Write-Host "Building..." -ForegroundColor White
$buildOutput = cmake --build build --config Debug 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  ✗ Build failed — fix the compile errors below:" -ForegroundColor Red
    Write-Host ""
    $buildOutput | Select-String "error:|warning:" | Select-Object -First 30 | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
    exit 1
}
Write-Host "  ✓ Build succeeded" -ForegroundColor Green
Write-Host ""

# ── Run the test ──────────────────────────────────────────────────────────────
Write-Host "Running tests for Issue #${nn}..." -ForegroundColor White
Write-Host ""

$testOutput = ctest --test-dir build -C Debug -R "^$testFilter" --output-on-failure 2>&1
$testExit   = $LASTEXITCODE

$testOutput | Where-Object { $_ -notmatch "^Internal ctest" } |
    ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "──────────────────────────────────────────"

if ($testExit -eq 0) {
    Write-Host "  ✓  All tests for Issue #${nn} PASSED!" -ForegroundColor Green
    Write-Host "     Your fix is working correctly."     -ForegroundColor Green
} else {
    Write-Host "  ✗  Tests for Issue #${nn} FAILED."                           -ForegroundColor Red
    Write-Host "     Review the output above — the 'Actual' vs 'Expected'"     -ForegroundColor Yellow
    Write-Host "     lines show exactly what your code returned."               -ForegroundColor Yellow
}

Write-Host "──────────────────────────────────────────"
Write-Host ""

exit $testExit
