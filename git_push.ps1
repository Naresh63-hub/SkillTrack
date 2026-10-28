# SkillTrack - GitHub Repository Setup & Push
param (
    [string]$RepoUrl
)

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   SkillTrack - Git & GitHub Repository Push " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if (-not (Test-Path ".git")) {
    Write-Host "[*] Initializing local Git repository..." -ForegroundColor Cyan
    & git init -b main
}

if (-not $RepoUrl) {
    $RepoUrl = Read-Host "Enter your GitHub repository URL (e.g. https://github.com/your-username/skilltrack.git)"
}

if (-not $RepoUrl) {
    Write-Host "[!] No repository URL provided. Aborting." -ForegroundColor Yellow
    exit 1
}

Write-Host "[*] Staging files..." -ForegroundColor Cyan
& git add .

Write-Host "[*] Creating commit..." -ForegroundColor Cyan
& git commit -m "SkillTrack: Production Student Skills & Placement Tracker (Android & Web for Vercel)"

Write-Host "[*] Configuring remote origin: $RepoUrl" -ForegroundColor Cyan
& git remote remove origin 2>$null
& git remote add origin $RepoUrl

Write-Host "[*] Pushing to GitHub (main branch)..." -ForegroundColor Cyan
& git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=============================================" -ForegroundColor Green
    Write-Host " [√] Successfully pushed to GitHub!         " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "`nNext Step - Connect to Vercel:" -ForegroundColor Cyan
    Write-Host " 1. Go to https://vercel.com/new" -ForegroundColor White
    Write-Host " 2. Click 'Import' next to your new GitHub repository." -ForegroundColor White
    Write-Host " 3. Vercel will automatically detect vercel.json and build command." -ForegroundColor White
    Write-Host " 4. Click 'Deploy' and your live URL will be ready in minutes!" -ForegroundColor White
} else {
    Write-Host "[!] Push failed. Please check your GitHub credentials or repo permissions." -ForegroundColor Red
}
