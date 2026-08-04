# ===================================================================
# Downloads Folder Sorter - Minimal Edition
# Single-pass sort. Runs once and exits. No background loop.
# Sorts Downloads into 12 flat destination buckets:
#   Pictures, Videos, Music, Documents,
#   Documents\PDFs, Documents\MS Word, Documents\MS Excel,
#   Documents\MS PowerPoint, Documents\Archives,
#   Documents\Applications, Documents\Code, Documents\Uncategorized
# Keeps: SHA-256 dedup, in-progress protection, collision renaming.
# ===================================================================

$ErrorActionPreference = "SilentlyContinue"

$downloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$documents = [Environment]::GetFolderPath("MyDocuments")
$pictures  = [Environment]::GetFolderPath("MyPictures")
$music     = [Environment]::GetFolderPath("MyMusic")
$videos    = [Environment]::GetFolderPath("MyVideos")

# ---------------------------------------------------------------
# 8 flat destination buckets
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

$pdfExts = @(
    ".pdf", ".xps", ".djvu", ".epub", ".mobi", ".azw", ".azw3", ".lit"
)
foreach ($e in $pdfExts) { $fileTypes[$e] = "$documents\PDFs" }

$wordExts = @(
    ".doc", ".docx", ".docm", ".dot", ".dotx", ".rtf", ".odt", ".wps",
    ".wpd", ".pages"
)
foreach ($e in $wordExts) { $fileTypes[$e] = "$documents\MS Word" }

$excelExts = @(
    ".xls", ".xlsx", ".xlsm", ".xlsb", ".xlt", ".xltx", ".csv", ".ods",
    ".numbers"
)
foreach ($e in $excelExts) { $fileTypes[$e] = "$documents\MS Excel" }

$pptExts = @(
    ".ppt", ".pptx", ".pptm", ".pot", ".potx", ".pps", ".ppsx", ".odp"
)
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
    ".sol", ".vue", ".gradle", ".sln", ".csproj", ".vcxproj", ".dockerfile"
)
foreach ($e in $codeExts) { $fileTypes[$e] = "$documents\Code" }

# ---------------------------------------------------------------
# In-progress extension filter
# ---------------------------------------------------------------
$inProgressPattern = "tmp|crdownload|part|opdownload|partial|!ut|bc!|download|filepart|dlm|downloading|incomplete|unfinished|idm|aria2"

function Get-FileHash-Custom([string]$filePath) {
    try {
        $stream = [System.IO.File]::OpenRead($filePath)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hash = $sha256.ComputeHash($stream)
        $stream.Close()
        return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
    }
    catch { return $null }
}

function IsFileInUse([string]$filePath) {
    try {
        $stream = [System.IO.File]::Open($filePath, 'Open', 'Read', 'None')
        $stream.Close()
        return $false
    }
    catch { return $true }
}

# ---------------------------------------------------------------
# Single pass over Downloads
# ---------------------------------------------------------------
$allFiles = Get-ChildItem -Path $downloads -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -notmatch $inProgressPattern }

$movedCount = 0
$dedupCount = 0

foreach ($f in $allFiles) {
    try {
        if (IsFileInUse $f.FullName) { continue }

        $ext = $f.Extension.ToLower()
        $destFolder = $null

        if ($fileTypes.ContainsKey($ext)) {
            $destFolder = $fileTypes[$ext]
        }
        elseif ($ext -eq "" -or $ext -eq ".") {
            $destFolder = "$documents\Uncategorized"
        }
        else {
            $destFolder = "$documents\Uncategorized"
        }

        if (!(Test-Path $destFolder)) {
            New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
        }

        $destPath = Join-Path $destFolder $f.Name
        $counter = 1

        while (Test-Path $destPath) {
            $existingHash = Get-FileHash-Custom $destPath
            $incomingHash = Get-FileHash-Custom $f.FullName
            if ($existingHash -and $incomingHash -and ($existingHash -eq $incomingHash)) {
                Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
                $dedupCount++
                continue
            }
            $newName = "$([System.IO.Path]::GetFileNameWithoutExtension($f.Name)) ($counter)$ext"
            $destPath = Join-Path $destFolder $newName
            $counter++
        }

        Move-Item -LiteralPath $f.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
        if (Test-Path $destPath) { $movedCount++ }
    }
    catch { }
}

# ---------------------------------------------------------------
# Cleanup empty leftover folders
# ---------------------------------------------------------------
for ($i = 0; $i -lt 5; $i++) {
    $empty = @(Get-ChildItem -Path $downloads -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue).Count -eq 0 })
    foreach ($dir in $empty) {
        Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Sort complete. Moved: $movedCount | Deduped: $dedupCount"
