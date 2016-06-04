Function Reset-TestFolder {
    If (Test-Path $Dir)
    {
        Remove-Item -Recurse -Path $Dir
    }
    New-Item $Dir -ItemType Directory > $null
    Copy-Item -Path "C:\Remove-EmptyFolders\TestFolder\*" -Include * -Destination $Dir -Recurse
}

$Dir = "C:\Remove-EmptyFolders\TestDir"
Reset-TestFolder
$Before = Get-ChildItem $Dir\* -Recurse -Directory | Measure-Object | Select -ExpandProperty Count

Describe "Test Remove-EmptyFolders" {
    It "Does it work?" {
        C:\Remove-EmptyFolders\Remove-EmptyFolders.ps1 -Path "c:\Remove-EmptyFolders\TestDir" -Confirm:$false
        $After = Get-ChildItem $Dir\* -Recurse -Directory | Measure-Object | Select -ExpandProperty Count
        $Before | Should Be 13
        $After | Should Be 8
    }
    It "Does it produce objects?" {
        Reset-TestFolder
        $Objects = C:\Remove-EmptyFolders\Remove-EmptyFolders.ps1 -Path "c:\Remove-EmptyFolders\TestDir" -Confirm:$false -Passthru
        $Objects.Count | Should Be 5
        @($Objects | Where Folder -eq "C:\Remove-EmptyFolders\TestDir\Cham\test").Count | Should Be 1
    }
    It "Does it produce a HTML report?" {
        Mock Send-MailMessage {}
        Reset-TestFolder
        C:\Remove-EmptyFolders\Remove-EmptyFolders.ps1 -Path "c:\Remove-EmptyFolders\TestDir" -Confirm:$false -Mail
        "C:\Remove-EmptyFolders\DeletedFolders-$(Get-Date -Format 'MM-dd-yyyy').html" | Should Exist
    }
    It "Is the HTML good?" {
        $Search = Select-String -Path "C:\Remove-EmptyFolders\DeletedFolders-$(Get-Date -Format 'MM-dd-yyyy').html" -Pattern "C:\\Remove-EmptyFolders\\TestDir\\Canute" 
        $Search.Line | Should Match "<tr><td>C:\\Remove-EmptyFolders\\TestDir\\Canute</td><td>"
    }
}