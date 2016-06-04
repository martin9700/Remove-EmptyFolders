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
.PARAMETER Path
	Designate the folder you want to run the script on.  Will remove all 
	empty folders in that path.
.PARAMETER Passthru
    Specify if you want object output from the script
.PARAMETER Mail
    Specify if you want the script to email the report to you
.PARAMETER To
	Who to email the report to 
.PARAMETER From
	You can designate who the email is coming from
.PARAMETER SMTPServer
	You must designate the name or IP address of your SMTP relay server
.EXAMPLE
	.\Remove-EmptyFolders.ps1 -Path \\Server\Share\Accounting

	Will remove all empty folders in the Accounting folder on your server.  You will be prompted to confirm each deleted
    folder (or you can use "Yes for All")

.EXAMPLE 
	.\Remove-EmptyFolders.ps1 -Path d:\shares -Mail -To admin@mydomain.com -From me@thesurlyadmin.com -SMTPServer exchange1 -confirm:$false

	Will remove all empty folders in D:\Shares, and email it to admin@mydomain.com using the server Exchange1 as the SMTP 
    relay.  There will be no prompt for deleting the folders.

.EXAMPLE
    .\Remove-EmptyFolders.ps1 -Path d:\shares -Passthru -confirm:$false

    All empty folders in d:\shares will be deleted, you will not be prompted to confirm the deletions and you will get 
    outputed objects suitable for logging.

.EXAMPLE
    .\Remove-EmptyFOlders.ps1 -Path d:\shares -Passthru -WhatIf

    This will run the script, locate the empty folders and return objects for logging that they've been deleted. But
    because of the -WhatIf parameter they will not actually be deleted.

.NOTES
	Author:        Martin Pugh
	Twitter:       @thesurlyadm1n
	Spiceworks:    Martin9700
	Blog:          www.thesurlyadmin.com
	
	Changelog:
       2.0         Big rewrite to include Parameter decorators, PSCustomObjects, performance improvements, ShouldProcess 
                   support, verbose logging.  Added support for object output (in fact, that's the default) but you can
                   still email results using the -Mail parameter
	   1.1         Updated to add some error checking and reporting if there 
	               are no empty folders.
	   1.0         Initial release
.LINK
	http://community.spiceworks.com/scripts/show/1735-remove-emptyfolders-ps1
#>

#requires -Version 3.0
[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High",DefaultParameterSetName="object")]
Param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
	[string]$Path,

    [Parameter(ParameterSetName="object")]
    [switch]$Passthru,

    [Parameter(ParameterSetName="mail")]
    [switch]$Mail,

    [Parameter(ParameterSetName="mail")]
	[string]$To = "me@mydomain.com",
    [Parameter(ParameterSetName="mail")]
	[string]$From = "remove-emptyfolders-script@thesurlyadmin.com",
    [Parameter(ParameterSetName="mail")]
	[string]$SMTPServer = "yourexchangeserver"
)
Write-Verbose "$(Get-Date): Remove-EmptyFolders.ps1 begins"

Write-Verbose "Gathering directory information"
$Folders = ForEach ($Folder in (Get-ChildItem -Path $Path -Recurse -Directory))
{	
	[PSCustomObject]@{
		Object = $Folder
		Depth = ($Folder.FullName.Split("\")).Count
	}
}
$Folders = $Folders | Sort Depth -Descending

[PSCustomObject[]]$Deleted = ForEach ($Folder in $Folders)
{	
	If ($Folder.Object.GetFileSystemInfos().Count -eq 0)
	{	
        [PSCustomObject]@{
			Folder = $Folder.Object.FullName
			Deleted = Get-Date
			Created = $Folder.Object.CreationTime
			'Last Modified' = $Folder.Object.LastWriteTime
			Owner = (Get-Acl $Folder.Object.FullName).Owner
		}
        If ($PSCmdlet.ShouldProcess($Folder.Object.FullName, "Confirm Delete?"))
        {
            Write-Verbose "Removing $($Folder.Object.FullName)..."
		    Remove-Item -Path $Folder.Object.FullName -Force 
        }
	}
}


If ($Mail)
{
    Write-Verbose "Generating report and sending email"

    $Today = Get-Date -Format "MM-dd-yyyy"
    $OutputPath = Join-Path -Path (Split-Path $MyInvocation.MyCommand.Path) -ChildPath "DeletedFolders-$Today.html"
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
	    From       = $From
	    To         = $To
	    Subject    = "Remove-EmptyFolers.ps1 Run on $Path"
	    SMTPServer = $SMTPServer
        BodyAsHtml = $true
    }
    If ($Deleted)
    {	
        Write-Verbose "$($Deleted.Count) folders were removed"
        $Deleted = $Deleted | Select Folder,Deleted,Created,'Last Modified',Owner | Sort Folder
	    $HTML = $Deleted | ConvertTo-Html -Head $Header -PreContent "<h3>Deleted Folder run at $Today $(Get-Date -f "hh:mm:ss tt")</h3>" -PostContent "<h4>Total folders deleted: $($Deleted.Count)</h4>"
    }
    Else
    {	
        Write-Verbose "No folders were removed"
        $HTML = @"
<html>
  <head>
    <Title>
      Deleted Folders Report for $Today
    </Title>
  </head>
  <Body>
    <p>
    Deleted Folder run at $Today $(Get-Date -f "hh:mm:ss tt")<br>
    <br/>
    Target Folder: $Path<br/>
    <b>No empty folders detected</b>
  </Body>
</html>
"@
    }

    $HTML | Out-File $OutputPath -Encoding ascii
    Send-MailMessage @MailProperties -Body ($HTML | Out-String)
}
ElseIf ($Passthru)
{
    Write-Output $Deleted
    Write-Verbose "$($Deleted.Count) folders were removed"
}

Write-Verbose "$(Get-Date): Remove-EmptyFolders.ps1 completed"