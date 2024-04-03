clear


$UserProfileFile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$GlobalProfileFile = "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1"

function Test-IsAdmin()
{
    # Alternative: [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")
}
$IsAdmin = (Test-IsAdmin)

if($IsAdmin -eq $false)
{
    Write-Host "To Uninstall the Profile run Powershell in Administrator Mode! ... Bye" -ForegroundColor Black -BackgroundColor Yellow
    break
}
else {
    try {
        $DeleteMyProfile = Read-Host "Do you want to remove your Powershell Profile? (y/n)"
        if ($DeleteMyProfile -eq "y") {
            Write-Host "[-] Removing Powershell Profile(s).." -ForegroundColor Red
            if((Test-Path $UserProfileFile)){Remove-Item -Path $UserProfileFile}
            if((Test-Path $GlobalProfileFile)){Remove-Item -Path $GlobalProfileFile}
        }
        
        $DeleteConDirectorys = Read-Host "Do you want to remove the .pss and .ssh folder in your Homedirectory? (y/n)"
        if($DeleteConDirectorys -eq "y")
        {
            Write-Host "[-] Remove the .pss and .ssh folder in your Homedirectory..." -ForegroundColor Red
            Remove-Item -Path "$env:USERPROFILE\.pss" -Recurse -Force
            Remove-Item -Path "$env:USERPROFILE\.ssh" -Recurse -Force
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)$([System.Environment]::NewLine)$($_.Exception.ToString())"
    }
}