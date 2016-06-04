

$Dir = "C:\Dropbox\github\Remove-EmptyFolders\TestDir"
If (Test-Path $Dir)
{
    Remove-Item -Recurse -Path $Dir
}

New-Item $Dir -ItemType Directory > $null
Copy-Item -Path "C:\Dropbox\github\Remove-EmptyFolders\TestFolder\*" -Include * -Destination $Dir -Recurse
"Before $(Get-ChildItem $Dir\* -Recurse -Directory | Measure-Object | Select -ExpandProperty Count)"

C:\Dropbox\github\Remove-EmptyFolders\Remove-EmptyFolders.ps1 -Path "c:\dropbox\github\Remove-EmptyFolders\TestDir" -Passthru -Verbose #-Mail -To "mpugh@athenahealth.com" -SMTPServer "hub.corp.athenahealth.com"

"After $(Get-ChildItem $Dir\* -Recurse -Directory | Measure-Object | Select -ExpandProperty Count)"