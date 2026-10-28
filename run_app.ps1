# SkillTrack Local Runner Script
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   SkillTrack - Local Runner & Diagnostics   " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Ensure Flutter SDK is in PATH
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue

if (-not $flutterCmd) {
    $possiblePaths = @(
        "D:\flutter_sdk\flutter\bin",
        "D:\flutter_sdk\bin",
        "C:\flutter\bin",
        "C:\src\flutter\bin",
        "$env:LOCALAPPDATA\flutter\bin",
        "$env:USERPROFILE\flutter\bin"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path "$path\flutter.bat") {
            Write-Host "[+] Found Flutter SDK at: $path" -ForegroundColor Green
            $env:PATH = "$path;$env:PATH"
            $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
            break
        }
    }
}

if (-not $flutterCmd) {
    Write-Host "[!] Flutter SDK not found in PATH or standard directories." -ForegroundColor Yellow
    Write-Host "Please ensure D:\flutter_sdk\flutter\bin is in your Environment Variables PATH." -ForegroundColor Yellow
    exit 1
}

# 2. Configure Java 21 LTS environment for Gradle
$javaPath = "C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
if (Test-Path $javaPath) {
    $env:JAVA_HOME = $javaPath
    Write-Host "[+] Using Java 21 LTS JDK: $javaPath" -ForegroundColor Green
}

Write-Host "[+] Flutter detected: " -NoNewline -ForegroundColor Green
& flutter --version | Select-Object -First 1

# 3. Check Devices
Write-Host "`n[*] Checking connected devices/emulators..." -ForegroundColor Cyan
& flutter devices

# 4. Fetch dependencies
Write-Host "`n[*] Running 'flutter pub get' in D:\flutter..." -ForegroundColor Cyan
Set-Location "D:\flutter"
& flutter pub get

# 5. Launch app
Write-Host "`n[*] Starting SkillTrack application..." -ForegroundColor Green
Write-Host "Tip: Connect your Android phone via USB (with USB debugging ON) or start an Android Emulator." -ForegroundColor DarkGray
Write-Host "Press 'r' for hot reload, 'R' for hot restart, 'q' to quit." -ForegroundColor DarkGray
& flutter run --android-skip-build-dependency-validation $args
