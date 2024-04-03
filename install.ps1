clear


$UserProfileFile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$GlobalProfileFile = "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1"
$ProfileString = "$env:USERPROFILE\.config\PWSH\.pwsh_profile.ps1"
$MiscFolder = "$env:USERPROFILE\.config\PWSH\misc"

function Test-IsAdmin()
{
    # Alternative: [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")
}
$IsAdmin = (Test-IsAdmin)

function Show-Menu {
    param (
        [string]$Title = 'My Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' for User based Profile."
    Write-Host "2: Press '2' for Global Profile."
    Write-Host "Q: Press 'Q' to quit."
}

if($IsAdmin -eq $false)
{
    Write-Host "To install the Profile(s) run Powershell in Administrator Mode! ... Bye" -BackgroundColor Yellow -ForegroundColor Black
    break
}
if($(Get-ExecutionPolicy) -ne "Unrestricted"){Write-Host "Change your Execution Policy to 'Unrestricted' to intsall the Profile .. Bye"; break}
Show-Menu -Title 'My Menu'
 $selection = Read-Host "Please make a selection"
 switch ($selection)
 {
     '1' {
         'You chose User based Profile.. Please wait..'
         if((Test-Path $UserProfileFile)) {
            Write-Host "Exists"
        }
        else {
            Write-Host "Apply Profile.." -ForegroundColor Yellow
            try {
                if(-not (Test-Path "$env:USERPROFILE\Documents\WindowsPowerShell")){mkdir "$env:USERPROFILE\Documents\WindowsPowerShell" | Out-Null}
                Write-Host "Install PSReadline.." -ForegroundColor Yellow
                Install-Module PSReadline -Force
                '. "'+$($ProfileString)+'"' | Out-File $UserProfileFile
                Copy-Item -Path "$MiscFolder\Templates\.pss" -Destination "$env:USERPROFILE" -Recurse
                Copy-Item -Path "$MiscFolder\Templates\.ssh" -Destination "$env:USERPROFILE" -Recurse
            }
            catch {
                Write-Host "Error: $($_.Exception.Message)$([System.Environment]::NewLine)$($_.Exception.ToString())"
            }
        }
     } '2' {
        'You chose Global Profile.. Please wait..'
         if((Test-Path $GlobalProfileFile)) {
            Write-Host "Exists"
        }
        else {
            Write-Host "Apply Profile.." -ForegroundColor Yellow
            try {
                Write-Host "Install PSReadline.." -ForegroundColor Yellow
                Install-Module PSReadline -Force
                '. "'+$($ProfileString)+'"' | Out-File $GlobalProfileFile
                Copy-Item -Path "$MiscFolder\Templates\.pss" -Destination "$env:USERPROFILE" -Recurse
                Copy-Item -Path "$MiscFolder\Templates\.ssh" -Destination "$env:USERPROFILE" -Recurse
            }
            catch {
                Write-Host "Error: $($_.Exception.Message)$([System.Environment]::NewLine)$($_.Exception.ToString())"
            }
        }
     } 'q' {
         return
     }
 }