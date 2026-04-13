param(
    [ValidateSet("web", "voice", "full")]
    [string]$Track = "web"
)

# Sani — Windows Installer (PowerShell)
# One-liner: irm https://raw.githubusercontent.com/your-org/sani/main/install/install.ps1 | iex
$ErrorActionPreference = "Stop"

$SANI_DIR = "$env:USERPROFILE\sani"
$CONDA_ENV = "sani"
$REPO = "https://github.com/your-org/sani.git"
$LAUNCHER = "$env:USERPROFILE\sani.bat"

function Info($msg)  { Write-Host "[Sani] $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "[Sani] $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "[Sani] $msg" -ForegroundColor Red; exit 1 }

function Install-PythonDeps($conda, $envName, $projectDir, $track) {
    if ($track -eq "full") {
        Info "Installing full dependency set..."
        & $conda run -n $envName pip install -r "$projectDir\requirements.txt"
        return
    }

    Info "Installing web-first dependency set..."
    & $conda run -n $envName pip install -r "$projectDir\install\requirements-web.txt"
    if ($LASTEXITCODE -ne 0) { return }

    if ($track -eq "voice") {
        Info "Installing optional voice add-ons..."
        & $conda run -n $envName pip install -r "$projectDir\install\requirements-voice.txt"
    }
}

# Find conda — check common locations
function Find-Conda {
    # Already on PATH?
    if (Get-Command conda -ErrorAction SilentlyContinue) { return "conda" }

    # Common install locations
    $paths = @(
        "$env:USERPROFILE\miniconda3\condabin\conda.bat",
        "$env:USERPROFILE\anaconda3\condabin\conda.bat",
        "$env:USERPROFILE\Miniconda3\condabin\conda.bat",
        "$env:USERPROFILE\Anaconda3\condabin\conda.bat",
        "C:\ProgramData\miniconda3\condabin\conda.bat",
        "C:\ProgramData\Miniconda3\condabin\conda.bat"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

# ── Upgrade path ─────────────────────────────────────────────
if (Test-Path "$SANI_DIR\.git") {
    Warn "Sani is already installed at $SANI_DIR"
    $reply = Read-Host "Upgrade? (Y/n)"

    if ($reply -eq 'n' -or $reply -eq 'N') {
        Info "Run Sani anytime: ~\sani.bat"
        exit 0
    }

    Set-Location $SANI_DIR
    git pull
    if ($LASTEXITCODE -ne 0) { Fail "git pull failed" }

    $conda = Find-Conda
    if (-not $conda) { Fail "Could not find conda" }
    Install-PythonDeps $conda $CONDA_ENV $SANI_DIR $Track
    if ($LASTEXITCODE -ne 0) { Fail "pip install failed" }

    Info "Sani upgraded!"
    Info "Run: ~\sani.bat"
    exit 0
}

# ── Fresh install ────────────────────────────────────────────
Write-Host ""
Write-Host "  +===================================+" -ForegroundColor Green
Write-Host "  |        Sani - Installing          |" -ForegroundColor Green
Write-Host "  +===================================+" -ForegroundColor Green
Write-Host ""
Warn "Track: $Track"
Warn "Web is the default. Voice add-ons stay optional."
Write-Host ""

# Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Info "Installing Git via winget..."
    winget install Git.Git --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { Fail "Git install failed" }
    # Add to PATH for this session
    $env:PATH = "$env:ProgramFiles\Git\cmd;$env:PATH"
}

# Miniconda
$conda = Find-Conda
if (-not $conda) {
    Info "Installing Miniconda via winget..."
    winget install Anaconda.Miniconda3 --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { Fail "Miniconda install failed" }

    # Init conda for PowerShell and CMD
    $condaBat = "$env:USERPROFILE\miniconda3\condabin\conda.bat"
    if (-not (Test-Path $condaBat)) {
        $condaBat = "$env:USERPROFILE\Miniconda3\condabin\conda.bat"
    }
    if (Test-Path $condaBat) {
        & $condaBat init powershell 2>$null
        & $condaBat init cmd.exe 2>$null
        Info "Miniconda installed and initialized."
    } else {
        Fail "Miniconda installed but conda.bat not found. Close and reopen terminal, then re-run."
    }

    # Refresh for this session
    $env:PATH = "$env:USERPROFILE\miniconda3\condabin;$env:USERPROFILE\miniconda3\Scripts;$env:PATH"
    $conda = Find-Conda
    if (-not $conda) { Fail "Conda not found after install. Close and reopen terminal, then re-run." }
}

# Clone
Info "Cloning Sani..."
git clone $REPO $SANI_DIR
if ($LASTEXITCODE -ne 0) { Fail "git clone failed" }

# Conda environment
Info "Creating conda environment (python 3.11)..."
& $conda create -n $CONDA_ENV python=3.11 -y
if ($LASTEXITCODE -ne 0) { Fail "Failed to create conda env" }
& $conda activate $CONDA_ENV

# Python deps
Info "Installing Python dependencies..."
Install-PythonDeps $conda $CONDA_ENV $SANI_DIR $Track
if ($LASTEXITCODE -ne 0) { Fail "pip install failed" }

# Launcher .bat
$batContent = @"
@echo off
call conda activate sani
cd /d %USERPROFILE%\sani
python main.py
"@
Set-Content -Path $LAUNCHER -Value $batContent -Encoding ASCII
Info "Created launcher at $LAUNCHER"

# Done
Write-Host ""
Write-Host "  +===================================+" -ForegroundColor Green
Write-Host "  |    Sani installed successfully     |" -ForegroundColor Green
Write-Host "  +===================================+" -ForegroundColor Green
Write-Host ""
Write-Host "  Run anytime:  ~\sani.bat"
Write-Host "  Web UI:       https://localhost:3004"
Write-Host ""

$reply = Read-Host "Launch Sani now? (Y/n)"
if ($reply -ne 'n' -and $reply -ne 'N') {
    & $LAUNCHER
}
