#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     Test-IsAdmin.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################
function Test-IsAdmin()
{
    # Alternative: [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")
}

# Check if Script is Running as Admin
function Test-RunAsAdmin()
{
    $ADMINMessage = "-=[ Session runs with elevated Privileges ]=-"
    $NoADMINMessage = "-=[ Please run this as Administrator .. Exiting ]=-"
    $DEKOLINE = "=" *$ADMINMessage.Length
    $DEKOLINENoAdmin = "=" *$NoADMINMessage.Length
    $ScriptNamePath = (Get-PSCallStack).ScriptName[0] 
    $ScriptName = (Get-PSCallStack).Location.Split(":")[0]

    If ([System.Diagnostics.EventLog]::SourceExists($ScriptName) -eq $False) {
     New-EventLog -LogName Application -Source $ScriptName
    }
    
    try{
        $Admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if(!$Admin)
        {
            Write-Host "$($DEKOLINE)$([System.Environment]::NewLine)$($ADMINMessage)$([System.Environment]::NewLine)$($DEKOLINE)" -BackgroundColor Red -ForegroundColor Yellow
        }
        else
        {
            Write-Host "$($DEKOLINENoAdmin)$([System.Environment]::NewLine)$($NoADMINMessage)$([System.Environment]::NewLine)$($DEKOLINENoAdmin)" -BackgroundColor Yellow -ForegroundColor Black
            Write-EventLog -LogName Application -Message "insufficient privileges to run this Script!$([System.Environment]::NewLine)Must be run as Administrator$([System.Environment]::NewLine)$([System.Environment]::NewLine)`
                                                          Script Path: $($ScriptNamePath)$([System.Environment]::NewLine)Executet User: $($env:USERNAME)" -EventId 1337 -Source "$ScriptName" -EntryType Error
            Exit
        }
    }
    catch{
        Write-Warning "$($Error[0].Exception.Message)"
    }
}

$FunctionsToExport = "Test-IsAdmin", `
                     "Test-RunAsAdmin"