# Downloads Folder Sorter — Minimal Edition

A single-pass Downloads sorter. Runs **once**, sorts your `Downloads` folder
into clean, organized folders, then exits. No background service, no VBS, no
startup shortcut — just a one-time `RunOnce` registry entry.

---

## One-Liner Install

Open **Windows PowerShell** (Win + R -> type `powershell` -> Enter) and paste:

```powershell
$d="$env:LOCALAPPDATA\SortFolder";New-Item -ItemType Directory -Path $d -Force|Out-Null;irm https://raw.githubusercontent.com/drnx64/Folder-Sorter/main/SortDownloadsFolder.ps1 -OutFile "$d\SortDownloadsFolder.ps1";Remove-Item "$d\launcher.exe" -Force -ErrorAction SilentlyContinue;Add-Type -TypeDefinition 'using System;using System.Diagnostics;using System.IO;public class L{[STAThread]public static void Main(){string s=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"SortFolder","SortDownloadsFolder.ps1");var psi=new ProcessStartInfo("powershell.exe","-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \""+s+"\""){CreateNoWindow=true,WindowStyle=ProcessWindowStyle.Hidden,UseShellExecute=false};using(var pr=Process.Start(psi)){pr.WaitForExit();}}}' -OutputAssembly "$d\launcher.exe" -OutputType WindowsApplication;reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v SortDownloads /t REG_SZ /d "`"$d\launcher.exe`"" /f;Start-Process "$d\launcher.exe"
```

What it does:

1. Downloads the sorter to `%LOCALAPPDATA%\SortFolder\SortDownloadsFolder.ps1`
2. Compiles a tiny windowless **`launcher.exe`** (using built-in .NET, no extra tools)
3. Writes a **RunOnce** registry key under `HKCU\...\CurrentVersion\RunOnce` pointing to `launcher.exe`
4. Starts the sort immediately — **100% silent: no window, no taskbar flash, no reboot needed**

The RunOnce key fires **once** on your next logon, runs `launcher.exe` (which
spawns PowerShell hidden with `CreateNoWindow`), then Windows deletes the key
automatically. It does **not** run continuously in the background and does
nothing after finishing.

> Why not just `powershell.exe -WindowStyle Hidden`? `powershell.exe` is a
> console app, so at logon Windows still opens a console host for a moment.
> The `launcher.exe` is a GUI-subsystem app — Windows never creates a console
> for it, so nothing ever appears.

---

## What It Does

- Sorts everything in `Downloads` into clean, organized folders
- Images go **directly into Pictures** — no date buckets, no camera-type subfolders
- Office files split into **PDFs, MS Word, MS Excel, MS PowerPoint** subfolders
- SHA-256 deduplication — identical files are deleted instead of duplicated
- In-progress protection — skips `.crdownload`, `.part`, `.tmp`, and similar
- Collision renaming — `file (1).zip` instead of overwriting
- Removes leftover empty folders after sorting

---

## Folder Structure

| Destination              | Contents |
| ------------------------ | -------- |
| `Pictures\`              | All images (JPG, PNG, RAW, PSD, SVG, ...) — flat |
| `Videos\`                | All video + subtitle files |
| `Music\`                 | All audio + music-project files |
| `Documents\`             | Other documents (text, notes, fonts, databases, ...) |
| `Documents\PDFs\`        | PDF, XPS, EPUB, MOBI, ... |
| `Documents\MS Word\`     | DOC, DOCX, RTF, ODT, ... |
| `Documents\MS Excel\`    | XLS, XLSX, CSV, ODS, ... |
| `Documents\MS PowerPoint\` | PPT, PPTX, PPS, ODP, ... |
| `Documents\Archives\`    | ZIP, RAR, 7z, TAR, ISO, ... |
| `Documents\Applications\`| EXE, MSI, installers, APK, ... |
| `Documents\Code\`        | Source code files |
| `Documents\Uncategorized\` | Everything else |

---

## Manual Run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\SortFolder\SortDownloadsFolder.ps1"
```

Silent run (no window):

```powershell
Start-Process "%LOCALAPPDATA%\SortFolder\launcher.exe"
```

---

## Uninstall

```powershell
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v SortDownloads /f
Remove-Item "$env:LOCALAPPDATA\SortFolder" -Recurse -Force
```

---

## Requirements

- Windows 10 or 11
- PowerShell 5.1+ (built into Windows)

---

## License

MIT
