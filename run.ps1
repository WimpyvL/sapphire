$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

function Test-Command($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Find-Conda {
    $candidates = @(
        "conda",
        "$env:USERPROFILE\miniconda3\condabin\conda.bat",
        "$env:USERPROFILE\anaconda3\condabin\conda.bat",
        "$env:USERPROFILE\Miniconda3\condabin\conda.bat",
        "$env:USERPROFILE\Anaconda3\condabin\conda.bat",
        "C:\ProgramData\miniconda3\condabin\conda.bat",
        "C:\ProgramData\Miniconda3\condabin\conda.bat"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -eq "conda") {
            if (Test-Command "conda") { return "conda" }
            continue
        }
        if (Test-Path $candidate) { return $candidate }
    }

    return $null
}

if ($env:VIRTUAL_ENV -or $env:CONDA_PREFIX) {
    & python main.py
    exit $LASTEXITCODE
}

$conda = Find-Conda
if ($conda) {
    & $conda run -n sani python main.py
    if ($LASTEXITCODE -eq 0) {
        exit 0
    }
}

if (Test-Command "py") {
    & py -3 main.py
    exit $LASTEXITCODE
}

if (Test-Command "python") {
    & python main.py
    exit $LASTEXITCODE
}

$pythonCandidates = @(
    "$env:USERPROFILE\anaconda3\python.exe",
    "$env:USERPROFILE\miniconda3\python.exe",
    "$env:USERPROFILE\Anaconda3\python.exe",
    "$env:USERPROFILE\Miniconda3\python.exe"
)

foreach ($candidate in $pythonCandidates) {
    if (Test-Path $candidate) {
        & $candidate main.py
        exit $LASTEXITCODE
    }
}

Write-Error "No usable Python launcher found. Install Python or Miniconda, or activate the sani environment first."
