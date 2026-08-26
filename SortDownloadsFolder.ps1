# ===================================================================
# Downloads Folder Sorter - Login Edition (Hardened)
# Single-pass sort. Runs once and exits. Safe for a Login task.
#
# Fixes over the previous version:
#   - Recursion respects explicit exclusions (folder names + a
#     ".nosort" marker file) so manually-organized subfolders in
#     Downloads are never touched.
#   - Errors are logged instead of globally swallowed.
#   - Duplicate files go to the Recycle Bin, not permanent delete.
#   - Partial-hash pre-check before full SHA256 (fast on large files).
#   - In-use check happens only once, as part of the move attempt
#     itself, instead of a separate open/close probe per file.
#   - Every run appends a timestamped entry to a log file.
# ===================================================================

# ---------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------
$downloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$documents = [Environment]::GetFolderPath("MyDocuments")
$pictures  = [Environment]::GetFolderPath("MyPictures")
$music     = [Environment]::GetFolderPath("MyMusic")
$videos    = [Environment]::GetFolderPath("MyVideos")

# Any subfolder in Downloads whose NAME is in this list is skipped
# entirely (not scanned, not moved, not deleted). Add your own here.
$excludedFolderNames = @("Keep", "DoNotSort", "Projects")

# Alternatively, drop an empty file named ".nosort" inside any
# Downloads subfolder to exclude it dynamically without editing
# this script.
$exclusionMarkerFile = ".nosort"

$logPath = Join-Path $downloads "_sorter.log"
$maxLogSizeBytes = 1MB

# Set to $true if you've run `Install-Module BurntToast` once.
$enableToastNotification = $false

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------
# Logging
# ---------------------------------------------------------------
function Write-SortLog {
    param([string]$Message, [string]$Level = "INFO")
    try {
        if ((Test-Path $logPath) -and (Get-Item $logPath).Length -gt $maxLogSizeBytes) {
            Remove-Item $logPath -Force -ErrorAction SilentlyContinue
        }
        $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
        Add-Content -Path $logPath -Value $line -ErrorAction SilentlyContinue
    }
    catch { }
}

# ---------------------------------------------------------------
# Recycle Bin delete (instead of permanent Remove-Item)
# ---------------------------------------------------------------
Add-Type -AssemblyName Microsoft.VisualBasic

function Remove-ToRecycleBin {
    param([string]$Path)
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
        $Path,
        [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
    )
}

# ---------------------------------------------------------------
# Exclusion check — walks a file's ancestor folders (relative to
# Downloads) and returns $true if any of them should be skipped.
# ---------------------------------------------------------------
function Test-PathExcluded {
    param([string]$FullPath)

    $relative = $FullPath.Substring($downloads.Length).TrimStart('\')
    $parts = $relative -split '\\'

    # Walk each ancestor folder (excluding the filename itself).
    $currentPath = $downloads
    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
        $folderName = $parts[$i]
        $currentPath = Join-Path $currentPath $folderName

        if ($excludedFolderNames -contains $folderName) {
            return $true
        }
        if (Test-Path (Join-Path $currentPath $exclusionMarkerFile)) {
            return $true
        }
    }
    return $false
}

# ---------------------------------------------------------------
# Destination buckets
# ---------------------------------------------------------------
$fileTypes = @{}

$picturesExts = @(
    ".jpg", ".jpeg", ".jpe", ".png", ".gif", ".bmp", ".tiff", ".tif",
    ".webp", ".svg", ".ico", ".heic", ".heif", ".avif", ".jxl", ".hdr",
    ".exr", ".tga", ".pcx", ".ppm", ".pgm", ".pbm", ".jfif", ".jp2",
    ".j2k", ".jpx", ".psd", ".psb", ".ai", ".eps", ".raw", ".cr2",
    ".cr3", ".nef", ".nrw", ".arw", ".dng", ".orf", ".raf", ".rw2",
    ".pef", ".srw", ".x3f", ".dcm", ".dicom", ".emf", ".wmf"
)
foreach ($e in $picturesExts) { $fileTypes[$e] = $pictures }

$videosExts = @(
    ".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v",
    ".mpeg", ".mpg", ".mpe", ".3gp", ".3g2", ".vob", ".ogv", ".ts",
    ".mts", ".m2ts", ".m2v", ".divx", ".xvid", ".asf", ".rmvb", ".f4v",
    ".qt", ".hevc", ".h264", ".h265", ".mjpg", ".mjpeg", ".prproj",
    ".aep", ".aet", ".drp", ".veg", ".srt", ".sub", ".ass", ".ssa",
    ".vtt", ".smi", ".idx", ".sbv"
)
foreach ($e in $videosExts) { $fileTypes[$e] = $videos }

$musicExts = @(
    ".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".m4a", ".aiff",
    ".aif", ".alac", ".opus", ".mid", ".midi", ".amr", ".ape", ".au",
    ".ra", ".rm", ".mka", ".wv", ".tta", ".ac3", ".dts", ".mp2", ".mpc",
    ".xm", ".mod", ".it", ".s3m", ".nsf", ".vgm", ".sid", ".als", ".flp",
    ".logic", ".logicx", ".ptf", ".nki", ".sf2", ".sfz", ".vstpreset"
)
foreach ($e in $musicExts) { $fileTypes[$e] = $music }

$pdfExts = @(".pdf", ".xps", ".djvu", ".epub", ".mobi", ".azw", ".azw3", ".lit")
foreach ($e in $pdfExts) { $fileTypes[$e] = "$documents\PDFs" }

$wordExts = @(".doc", ".docx", ".docm", ".dot", ".dotx", ".rtf", ".odt", ".wps", ".wpd", ".pages")
foreach ($e in $wordExts) { $fileTypes[$e] = "$documents\MS Word" }

$excelExts = @(".xls", ".xlsx", ".xlsm", ".xlsb", ".xlt", ".xltx", ".csv", ".ods", ".numbers")
foreach ($e in $excelExts) { $fileTypes[$e] = "$documents\MS Excel" }

$pptExts = @(".ppt", ".pptx", ".pptm", ".pot", ".potx", ".pps", ".ppsx", ".odp")
foreach ($e in $pptExts) { $fileTypes[$e] = "$documents\MS PowerPoint" }

$documentsExts = @(
    ".key", ".mdb", ".accdb", ".pub", ".one", ".vsdx", ".vsd", ".mpp",
    ".msg", ".eml", ".mbox", ".cbz", ".cbr", ".txt", ".text", ".nfo",
    ".md", ".markdown", ".rst", ".adoc", ".org", ".tex", ".ltx", ".bib",
    ".ttf", ".otf", ".woff", ".woff2", ".eot", ".fnt", ".fon", ".odg",
    ".sql", ".json", ".xml", ".yaml", ".yml", ".toml", ".ini", ".cfg",
    ".conf", ".reg", ".log", ".mdx"
)
foreach ($e in $documentsExts) { $fileTypes[$e] = $documents }

$archivesExts = @(
    ".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz", ".lz", ".lz4",
    ".lzma", ".zst", ".zstd", ".tgz", ".tbz2", ".txz", ".cab", ".z",
    ".arc", ".arj", ".lha", ".lzh", ".ace", ".iso", ".img", ".dmg"
)
foreach ($e in $archivesExts) { $fileTypes[$e] = "$documents\Archives" }

$applicationsExts = @(
    ".exe", ".msi", ".dmg", ".run", ".com", ".scr", ".appref-ms",
    ".apk", ".aab", ".ipa", ".msix", ".msixbundle", ".appxbundle",
    ".bat", ".cmd", ".jar", ".war", ".whl", ".deb", ".rpm", ".pkg",
    ".nupkg", ".vsix", ".crx", ".xpi", ".ovpn"
)
foreach ($e in $applicationsExts) { $fileTypes[$e] = "$documents\Applications" }

$codeExts = @(
    ".py", ".pyw", ".ipynb", ".js", ".mjs", ".cjs", ".ts", ".tsx",
    ".jsx", ".vue", ".svelte", ".cpp", ".cc", ".cxx", ".c", ".h",
    ".hpp", ".cs", ".vb", ".fs", ".java", ".kt", ".kts", ".scala",
    ".go", ".rs", ".swift", ".m", ".mm", ".rb", ".php", ".pl", ".pm",
    ".lua", ".r", ".jl", ".hs", ".ex", ".exs", ".erl", ".clj", ".cljs",
    ".scm", ".rkt", ".d", ".nim", ".zig", ".asm", ".s", ".ps1", ".psm1",
    ".sh", ".bash", ".zsh", ".fish", ".html", ".htm", ".css", ".scss",
    ".sass", ".less", ".styl", ".php3", ".php4", ".php5", ".wasm",
    ".sol", ".gradle", ".sln", ".csproj", ".vcxproj", ".dockerfile"
)
foreach ($e in $codeExts) { $fileTypes[$e] = "$documents\Code" }

# ---------------------------------------------------------------
# In-progress extension filter
# ---------------------------------------------------------------
$inProgressPattern = "\.(tmp|crdownload|part|opdownload|partial|!ut|bc!|download|filepart|dlm|downloading|incomplete|unfinished|idm|aria2)$"

# ---------------------------------------------------------------
# Duplicate detection — cheap partial hash first, full hash only
# if the partial hashes actually match (keeps large-file dedup fast)
# ---------------------------------------------------------------
function Get-QuickHash {
    param([string]$Path, [int]$SampleBytes = 65536)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $length = [Math]::Min($SampleBytes, $stream.Length)
        $buffer = New-Object byte[] $length
        [void]$stream.Read($buffer, 0, $length)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        return [BitConverter]::ToString($sha.ComputeHash($buffer))
    }
    finally { $stream.Close() }
}

function Test-FilesIdentical {
    param([string]$PathA, [string]$PathB)

    if ((Get-QuickHash $PathA) -ne (Get-QuickHash $PathB)) { return $false }
    # Quick hashes matched (or files are small enough that quick == full);
    # confirm with a full hash before treating as a duplicate.
    $hashA = (Get-FileHash -LiteralPath $PathA -Algorithm SHA256).Hash
    $hashB = (Get-FileHash -LiteralPath $PathB -Algorithm SHA256).Hash
    return $hashA -eq $hashB
}

# ---------------------------------------------------------------
# Single pass over Downloads
# ---------------------------------------------------------------
$movedCount = 0
$dedupCount = 0
$errorCount = 0

Write-SortLog "Sort started."

$allFiles = Get-ChildItem -Path $downloads -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -notmatch $inProgressPattern -and
        -not (Test-PathExcluded $_.FullName)
    }

foreach ($f in $allFiles) {
    try {
        $ext = $f.Extension.ToLower()
        $destFolder = $null

        if ($fileTypes.ContainsKey($ext)) {
            $destFolder = $fileTypes[$ext]
        }
        elseif ($ext -eq "" -or $ext -eq ".") {
            $destFolder = "$documents\Uncategorized\NO_EXTENSION"
        }
        else {
            $extName = $ext.TrimStart(".").ToUpper()
            $destFolder = "$documents\Uncategorized\$extName"
        }

        if (!(Test-Path $destFolder)) {
            New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
        }

        $destPath = Join-Path $destFolder $f.Name
        $counter = 1
        $isDuplicate = $false

        while (Test-Path $destPath) {
            $existingFile = Get-Item -LiteralPath $destPath

            if ($existingFile.Length -eq $f.Length -and (Test-FilesIdentical $destPath $f.FullName)) {
                $isDuplicate = $true
                break
            }

            $newName = "$([System.IO.Path]::GetFileNameWithoutExtension($f.Name)) ($counter)$ext"
            $destPath = Join-Path $destFolder $newName
            $counter++
        }

        if ($isDuplicate) {
            Remove-ToRecycleBin -Path $f.FullName
            $dedupCount++
            Write-SortLog "Duplicate removed (Recycle Bin): $($f.FullName)"
        }
        else {
            # Attempt the move directly — this doubles as the "file in
            # use" check, avoiding a separate open/close probe per file.
            Move-Item -LiteralPath $f.FullName -Destination $destPath -Force -ErrorAction Stop
            $movedCount++
        }
    }
    catch [System.IO.IOException] {
        # File is locked/in use — skip quietly, it'll be picked up next login.
        Write-SortLog "Skipped (in use): $($f.FullName)"
    }
    catch {
        $errorCount++
        Write-SortLog "ERROR on $($f.FullName): $($_.Exception.Message)" "ERROR"
    }
}

# ---------------------------------------------------------------
# Cleanup empty leftover folders (deepest first), skipping excluded ones
# ---------------------------------------------------------------
Get-ChildItem -Path $downloads -Directory -Recurse -ErrorAction SilentlyContinue |
    Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true} |
    Where-Object {
        -not (Test-PathExcluded (Join-Path $_.FullName "x")) -and
        $excludedFolderNames -notcontains $_.Name -and
        -not (Test-Path (Join-Path $_.FullName $exclusionMarkerFile)) -and
        @(Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0
    } |
    ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
        Write-SortLog "Removed empty folder: $($_.FullName)"
    }

# ---------------------------------------------------------------
# Completion
# ---------------------------------------------------------------
$summary = "Sort complete. Moved: $movedCount | Deduped (Recycle Bin): $dedupCount | Errors: $errorCount"
Write-Host $summary
Write-SortLog $summary

if ($enableToastNotification -and ($movedCount -gt 0 -or $dedupCount -gt 0)) {
    try {
        Import-Module BurntToast -ErrorAction Stop
        New-BurntToastNotification -Text "Downloads Organizer", "Moved $movedCount files. Sent $dedupCount duplicates to Recycle Bin."
    }
    catch {
        Write-SortLog "Toast notification failed: $($_.Exception.Message)" "WARN"
    }
}
