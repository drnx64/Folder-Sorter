# Downloads Folder Sorter — Minimal Edition

A single-pass Downloads sorter. Runs **once**, sorts your `Downloads` folder
into clean, organized folders, then exits. No background service, no VBS, no
startup shortcut — just a one-time `RunOnce` registry entry.

---

## One-Liner Install

Open **PowerShell** (Win + R -> type `powershell` -> Enter) and paste:

```powershell
$d="$env:LOCALAPPDATA\SortFolder";New-Item -ItemType Directory -Path $d -Force|Out-Null;irm https://raw.githubusercontent.com/drnx64/Folder-Sorter/main/SortDownloadsFolder.ps1 -OutFile "$d\SortDownloadsFolder.ps1";reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v SortDownloads /t REG_SZ /d "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$d\SortDownloadsFolder.ps1`"" /f;Start-Process powershell -ArgumentList '-NoProfile','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',"`"$d\SortDownloadsFolder.ps1`"" -WindowStyle Hidden
```

What it does:

1. Downloads the sorter to `%LOCALAPPDATA%\SortFolder\SortDownloadsFolder.ps1`
2. Writes a **RunOnce** registry key under `HKCU\...\CurrentVersion\RunOnce`
3. Starts the sort immediately — fully silent (no window, no taskbar), no reboot needed

The RunOnce key fires **once** on your next logon, runs the sorter silently,
then Windows deletes the key automatically. It does **not** run continuously
in the background and does nothing after finishing.

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
