# SkillTrack Test Runner
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "       SkillTrack - Automated Test Suite     " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    if (Test-Path "D:\flutter_sdk\flutter\bin\flutter.bat") {
        $env:PATH = "D:\flutter_sdk\flutter\bin;$env:PATH"
    } else {
        Write-Host "[!] Flutter SDK not found in PATH." -ForegroundColor Yellow
        exit 1
    }
}

Set-Location "D:\flutter"
Write-Host "`n[*] Running Flutter Static Analysis..." -ForegroundColor Cyan
& flutter analyze

Write-Host "`n[*] Running Flutter Automated Tests..." -ForegroundColor Cyan
& flutter test
