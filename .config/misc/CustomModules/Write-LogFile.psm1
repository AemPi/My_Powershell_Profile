#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     Write-LogFile.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################
function Write-LogFile()
{
    Param
    (
        [Parameter(Mandatory=$true,Position=0)][ValidateSet('INFO','WARN','FAIL','OKAY','DEKO')][string[]]$Status,
        [Parameter(Mandatory=$false,Position=1)][string[]]$Message,
        [Parameter(Mandatory=$false,Position=2)]$LogPath #= "$env:userprofile\Desktop\default-log.txt"
    )

    if([system.string]::IsNullOrEmpty($LogPath))
    {
        $LogPath = "$env:userprofile\Desktop\default-log.txt"
    }

    $LogFileDate = Get-date -Format "yyyy-MM-dd HH:mm:ss"
    $DEKOcut = "================================================="

    Switch ($Status)
      {
        INFO { Write-Host "[$LogFileDate]" : "[$Status]" ": " $Message -BackgroundColor Green -ForegroundColor White ; "[$LogFileDate] :" + " [$Status]" + ": $Message" | Out-File $LogPath -Append -Encoding utf8 }
        WARN { Write-Host "[$LogFileDate]" : "[$Status]" ": " $Message -BackgroundColor Yellow -ForegroundColor Black ; "[$LogFileDate] :" + " [$Status]" + ": $Message" | Out-File $LogPath -Append -Encoding utf8 }
        FAIL { Write-Host "[$LogFileDate]" : "[$Status]" ": " $Message -BackgroundColor Red -ForegroundColor White ; "[$LogFileDate] :" + " [$Status]" + ": $Message" | Out-File $LogPath -Append -Encoding utf8 }
        OKAY { Write-Host "[$LogFileDate]" : "[$Status]" ": " $Message -BackgroundColor Green -ForegroundColor White ; "[$LogFileDate] :" + " [$Status]" + ": $Message" | Out-File $LogPath -Append -Encoding utf8 }
        DEKO { Write-Host $DEKOcut ; $DEKOcut | Out-File  $LogPath -Append -Encoding utf8 }
      }
}

$FunctionsToExport = "Write-LogFile"