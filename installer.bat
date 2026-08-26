@echo off
setlocal EnableExtensions

set "RAW_URL=https://raw.githubusercontent.com/drnx64/Folder-Sorter/refs/heads/main/SortDownloadsFolder.ps1"
set "INSTALL_DIR=%LOCALAPPDATA%\DownloadsSorter"
set "PS1_PATH=%INSTALL_DIR%\SortDownloadsFolder.ps1"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "VBS_PATH=%STARTUP_DIR%\DownloadsSorterLauncher.vbs"

echo ============================================
echo  Downloads Sorter - Silent Installer
echo ============================================
echo.

echo [1/4] Creating install folder...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo [2/4] Downloading script...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%RAW_URL%' -OutFile '%PS1_PATH%' -UseBasicParsing } catch { Write-Host $_.Exception.Message; exit 1 }"

if not exist "%PS1_PATH%" (
    echo.
    echo [ERROR] Failed to download the script. Aborting.
    pause
    exit /b 1
)
echo     Saved to "%PS1_PATH%"

echo [3/4] Creating silent startup launcher...
echo Set objShell = CreateObject("WScript.Shell") > "%VBS_PATH%"
echo objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " ^& Chr(34) ^& "%PS1_PATH%" ^& Chr(34), 0, False >> "%VBS_PATH%"

if not exist "%VBS_PATH%" (
    echo.
    echo [ERROR] Failed to create the startup launcher. Aborting.
    pause
    exit /b 1
)
echo     Saved to "%VBS_PATH%"

echo [4/4] Done.
echo.
echo The Downloads Sorter will now run silently every time you log in.
echo No console window, no taskbar icon.
echo.
pause
