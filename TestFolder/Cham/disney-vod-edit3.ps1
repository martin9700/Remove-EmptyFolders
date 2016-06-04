$sourceDir = "C:\test" #Production Folder "D:\Vodassets\_PreImport_Success"
$tempDir = "C:\test-temp"
$targetDir = "C:\test-copyback"
$Date = "Get-Date -format MM-dd-yyy"
$DateTime = "Get-Date"
$LogFile = "Log.txt"
$LogXML = "LogXML.txt"

### Edit these E-mail settings
$SMTPProperties = @{
    To = "matt.bergeron@whidbeytel.com"
    From = "email@domain.com"
    Subject = "Disney VOD Proccessing Completed for $Date"
    SMTPServer = "mail.domain.com"
	}


### Copy Disney Metadata.xml's to a temporary folder for the editting process
if (-not (Test-Path $sourceDir | Where-Object {$_.FullName -like "*disney*"})){
$Results = @()
$GetXML = @(Get-ChildItem $sourceDir -recurse -filter "Metadata.xml" | Where-Object {$_.FullName -like "*disney*"})
	if ($GetXML.length -eq 0) {
	write-host "No files to copy. Ending Process....." -foregroundcolor yellow -backgroundcolor black 
		} else {
			ForEach ($File in $GetXML)
					{   $Path = $File.DirectoryName.Replace($sourceDir,$tempDir)
						if (-not (Test-Path $Path)) {
						Write-Host "Destination $Path doesn't exist, creating it." -foregroundcolor yellow -backgroundcolor black
						New-Item -Path $Path -ItemType Directory
						}
			Copy-Item -Path $File.FullName -Destination $Path -ErrorAction silentlyContinue
		if(-not $?) {
		write-warning "Failed to copy $($File.Fullname)" -foregroundcolor red -backgroundcolor black 
		$Results += "Failed to copy $($File.Fullname)"
		} else {
		write-host "Succesfully copied $($File.Fullname) to $($targetDir)" -foregroundcolor green -backgroundcolor black 
		$Results += "Succesfully copied $($File.Fullname) to $($targetDir)"
		}
	}
}

### Edit XML Process
ForEach ($File in $GetXML)
		{	$Path = $File.DirectoryName.Replace($sourceDir,$tempDir)
		if (Test-Path $Path) {
			$xmlData = [xml](Get-Content $File.FullName)
		foreach ($group in $xmlData){
		Write-Host "Processing XML file $($File.Name) in Directory: $($File.DirectoryName)" -foregroundcolor white -backgroundcolor black
		$Results += "Processing XML file $($File.Name) in Directory: $($File.DirectoryName)"
		$xmlData.assetpackages.assetpackage.'Type' = 'SVOD'
		$xmlData.assetpackages.assetpackage.'Product' = 'SVOD'
		$xmlData.assetpackages.assetpackage.'Name' = 'Disney Family Movies'
		}
	}	
	$xmlData.Save($File.Fullname)
}



### Copy Files to VOD Import Server
$import = (Get-ChildItem $tempDir -recurse -filter "Metadata.xml" | Where-Object {$_.FullName -like "*disney*"})
if ($import.length -eq 0) {
write-host "No files to import. Ending Process....." -foregroundcolor yellow -backgroundcolor black
	} else {
	ForEach ($File in $import)
		{   $Path = $File.DirectoryName.Replace($tempDir,$targetDir)
		if (-not (Test-Path $Path)) {
				$Results += New-Object PSObject -Property @{
				File = $File
				SourcePath = "$File.DirectoryName"
				DestinationPath = "None"
				Status = "Destination $Path doesn't exist, creating it."
		}
			New-Item -Path $Path -ItemType Directory
		}
	}	
	Copy-Item -Path $File.FullName -Destination $Path -ErrorAction silentlyContinue
	if(-not $?) {write-warning "Failed to copy $($File.Fullname)" -foregroundcolor red -backgroundcolor black 
		} else {
		$Results += New-Object PSObject -Property @{
	        File = $File
	        SourcePath = "$File.DirectoryName"
	        DestinationPath = "$targetDir"
	        Status = "Successful"
	    }
	}
}


### Cleanup temporary directory
if (-not (Test-Path $tempDir | Where-Object {$_.FullName -like "*disney*"})){
Get-ChildItem $tempDir -recurse | % { Remove-Item $_.FullName -recurse } #Remove the -whatif to actual clean out the directory
}

}

### Prepare the report
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
<title>
Folder Copy Operations for Group: $Group
</title>
"@
$Pre = "<h2>Disney VOD Proccessing Completed for $Date</h2>"
$Body = $Results | ConvertTo-Html -Head $Header -PreContent $Pre | Out-String
	
### Send the report
#Send-MailMessage @SMTPProperties -Body $Body -BodyAsHtml