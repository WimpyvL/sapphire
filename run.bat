@echo off
setlocal

cd /d "%~dp0"

if defined VIRTUAL_ENV (
    python main.py
    exit /b %ERRORLEVEL%
)

if exist "%USERPROFILE%\miniconda3\condabin\conda.bat" (
    call "%USERPROFILE%\miniconda3\condabin\conda.bat" run -n sani python main.py
    if %ERRORLEVEL%==0 exit /b 0
)

if exist "%USERPROFILE%\anaconda3\condabin\conda.bat" (
    call "%USERPROFILE%\anaconda3\condabin\conda.bat" run -n sani python main.py
    if %ERRORLEVEL%==0 exit /b 0
)

if exist "%USERPROFILE%\Miniconda3\condabin\conda.bat" (
    call "%USERPROFILE%\Miniconda3\condabin\conda.bat" run -n sani python main.py
    if %ERRORLEVEL%==0 exit /b 0
)

if exist "%USERPROFILE%\Anaconda3\condabin\conda.bat" (
    call "%USERPROFILE%\Anaconda3\condabin\conda.bat" run -n sani python main.py
    if %ERRORLEVEL%==0 exit /b 0
)

where py >nul 2>nul
if %ERRORLEVEL%==0 (
    py -3 main.py
    exit /b %ERRORLEVEL%
)

where python >nul 2>nul
if %ERRORLEVEL%==0 (
    python main.py
    exit /b %ERRORLEVEL%
)

if exist "%USERPROFILE%\anaconda3\python.exe" (
    "%USERPROFILE%\anaconda3\python.exe" main.py
    exit /b %ERRORLEVEL%
)

if exist "%USERPROFILE%\miniconda3\python.exe" (
    "%USERPROFILE%\miniconda3\python.exe" main.py
    exit /b %ERRORLEVEL%
)

if exist "%USERPROFILE%\Anaconda3\python.exe" (
    "%USERPROFILE%\Anaconda3\python.exe" main.py
    exit /b %ERRORLEVEL%
)

if exist "%USERPROFILE%\Miniconda3\python.exe" (
    "%USERPROFILE%\Miniconda3\python.exe" main.py
    exit /b %ERRORLEVEL%
)

echo No usable Python launcher found. Install Python or Miniconda, or activate the sani environment first.
exit /b 1
