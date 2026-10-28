# SkillTrack APK Direct Installer
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  SkillTrack - Instant Android Device Installer" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$adbPath = "C:\Users\NARESH\AppData\Local\Android\sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) {
        $adbPath = $adbCmd.Source
    } else {
        Write-Host "[!] ADB tool not found. Please install Android Platform Tools." -ForegroundColor Red
        exit 1
    }
}

$apkPath = "D:\flutter\build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "[!] APK not found at $apkPath. Please run 'flutter build apk' first." -ForegroundColor Red
    exit 1
}

Write-Host "[+] ADB located at: $adbPath" -ForegroundColor Green
Write-Host "[*] Checking for connected Android devices..." -ForegroundColor Cyan

$devices = & $adbPath devices | Where-Object { $_ -match "\tdevice$" }
if (-not $devices) {
    Write-Host "[!] No active Android device detected via USB debugging." -ForegroundColor Yellow
    Write-Host "Please do the following:" -ForegroundColor White
    Write-Host "  1. Connect your Android phone via USB cable." -ForegroundColor Gray
    Write-Host "  2. Go to Phone Settings -> Developer Options -> Enable USB Debugging." -ForegroundColor Gray
    Write-Host "  3. Accept the 'Allow USB debugging?' prompt on your phone screen." -ForegroundColor Gray
    Write-Host "  4. Run this script again." -ForegroundColor Gray
    exit 1
}

Write-Host "[+] Detected Android device: $devices" -ForegroundColor Green
Write-Host "[*] Installing SkillTrack APK ($apkPath)..." -ForegroundColor Cyan

& $adbPath install -r $apkPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] Installation Successful!" -ForegroundColor Green
    Write-Host "[*] Launching SkillTrack on device..." -ForegroundColor Cyan
    & $adbPath shell am start -n com.skilltrack.app/.MainActivity
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host " SkillTrack is now running on your phone!    " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Cyan
} else {
    Write-Host "[!] Installation failed with error code $LASTEXITCODE." -ForegroundColor Red
}
