' Silent launcher for SortDownloadsFolder.ps1
' Run with: wscript.exe run-silent.vbs
' wscript is a GUI host -> no console window ever appears.
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & dir & "\SortDownloadsFolder.ps1""", 0, False
