<#
.SYNOPSIS
	Easy script to remove all empty folders from a folder tree.
.DESCRIPTION
	This script will run on the designated folder tree and remove all empty
	folders, even nested ones.  A HTML report will then be created and 
	emailed to the designated email address.
	
	Update the Param section to meet your needs, or use the -TargetFolder
	parameter when running the script to designate what folder you want the
	script to work on.
	
	** Please Note ** Will run a very long time on massive folder structures.
.PARAMETER TargetFolder
	Designate the folder you want to run the script on.  Will remove all 
	empty folders in that path.
.PARAMETER To
	Who to email the report to
.PARAMETER From
	You can designate who the email is coming from
.PARAMETER SMTPServer
	You must designate the name or IP address of your SMTP relay server
.EXAMPLE
	.\Remove-EmptyFolders.ps1 -TargetFolder \\Server\Share\Accounting
	Will remove all empty folders in the Accounting folder on your server.  The
	report will be emailed to the default settings.
.EXAMPLE 
	.\Remove-EmptyFolders.ps1 -TargetPath d:\shares -To admin@mydomain.com -From me@thesurlyadmin.com -SMTPServer exchange1
	Will remove all empty folders in D:\Shares, and email it to admin@mydomain.com 
	using the server Exchange1 as the SMTP relay.
.NOTES
	Author:        Martin Pugh
	Twitter:       @thesurlyadm1n
	Spiceworks:    Martin9700
	Blog:          www.thesurlyadmin.com
	
	Changelog:
	   1.1         Updated to add some error checking and reporting if there 
	               are no empty folders.
	   1.0         Initial release
.LINK
	http://community.spiceworks.com/scripts/show/1735-remove-emptyfolders-ps1
#>
Param (
	[string]$TargetFolder = "c:\utils",
	[string]$To = "me@mydomain.com",
	[string]$From = "remove-emptyfolders-script@thesurlyadmin.com",
	[string]$SMTPServer = "yourexchangeserver"
)
$Deleted = @()
$Folders = @()
ForEach ($Folder in (Get-ChildItem -Path $TargetFolder -Recurse | Where { $_.PSisContainer }))
{	
	$Folders += New-Object PSObject -Property @{
		Object = $Folder
		Depth = ($Folder.FullName.Split("\")).Count
	}
}
$Folders = $Folders | Sort Depth -Descending
ForEach ($Folder in $Folders)
{	#$Folder = Get-ItemProperty -Path $Dir.FullName
	If ($Folder.Object.GetFileSystemInfos().Count -eq 0)
	{	$Deleted += New-Object PSObject -Property @{
			Folder = $Folder.Object.FullName
			Deleted = (Get-Date -Format "hh:mm:ss tt")
			Created = $Folder.Object.CreationTime
			'Last Modified' = $Folder.Object.LastWriteTime
			Owner = (Get-Acl $Folder.Object.FullName).Owner
		}
		Remove-Item -Path $Folder.Object.FullName -Force
	}
}
$Today = Get-Date -Format "MM-dd-yyyy"
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
<Title>
Deleted Folders Report for $Today
</Title>
"@

$MailProperties = @{
	From = $From
	To = $To
	Subject = "Remove-EmptyFolers.ps1 Run on $TargetFolder"
	SMTPServer = $SMTPServer
}
If ($Deleted)
{	$Deleted = $Deleted | Select Folder,Deleted,Created,'Last Modified',Owner | Sort Folder
	$Deleted | ConvertTo-Html -Head $Header | Out-File c:\utils\DeletedFolders-$Today.html
	$Deleted = $Deleted | ConvertTo-Html -Head $Header | Out-String
}
Else
{	$Deleted = @"
<Title>
Deleted Folders Report for $Today
</Title>
<Body>
Deleted Folder run at $Today $(Get-Date -f "hh:mm:ss tt")<br>
<b>No empty folders detected</b>
</Body>
"@
	$Deleted | Out-File c:\utils\DeletedFolders-$Today.html
}

Send-MailMessage @MailProperties -Body $Deleted -BodyAsHtml




<#
Measure-Command {
	$Folders = (gci $TargetFolder -r | ? {$_.PSIsContainer -eq $True}) | ?{$_.GetFileSystemInfos().Count -eq 0}
}#48 milliseconds

Measure-Command {
	$Folders2 = Get-ChildItem $TargetFolder -Recurse | Where { $_.PSisContainer -and $_.GetFileSystemInfos().Count -eq 0 }
}#11 milliseconds

Start-Transcript c:\utils\test.txt
$Folders = Get-ChildItem $TargetFolder -Recurse | Where { $_.PSisContainer -and $_.GetFileSystemInfos().Count -eq 0 }
Foreach ($Folder in $Folders)
{	Remove-Item -Path $Folder.FullName -Recurse -Force -Verbose
	$Deleted += "Folder Deleted: $($Folder.FullName)`n"
}
Stop-Transcript

Start-Transcript c:\utils\test-$(get-date -f "MM-dd-yyyy").txt
ForEach ($Folder in (GCI $TargetFolder -Recurse | ? { $_.PSisContainer -and $_.GetFileSystemInfos().Count -eq 0 }))
{	RM -Path $_.Fullname -Recurse -Force -Verbose }
Stop-Transcript

Function Remove-Dir {
	Param (
		[string]$Dir
	)
	Get-ChildItem
	
	
	$Folders = Get-ChildItem -Path $Dir
	If ($Folders -eq $null)
	{	$Folder = Get-ItemProperty -Path $Dir
		$Global:Deleted += New-Object PSObject -Property @{
			Folder = $Folder.FullName
			Deleted = (Get-Date -Format "hh:mm:ss tt")
			Created = $Folder.CreationTime
			'Last Modifed' = $Folder.LastWriteTime
			Owner = (Get-Acl $Folder).Owner
		}
		Remove-Item -Path $Dir -Force
	}
	Else
	{	ForEach ($Folder in $Folders)
		{	If ($Folder.PSIsContainer)
			{	Remove-Dir $Folder.FullName
			}
		}
	}
}
#>