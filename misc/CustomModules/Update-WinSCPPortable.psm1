#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     Update-WinSCPPortable.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################

function Update-WinSCPPrtable()
{
    $sScriptPath = Split-Path -Parent $PSCommandPath
    $ConfigFolder = $sScriptPath.Replace("\CustomModules","")
    $LocalWinSCPPath = "$ConfigFolder\WinSCP"
    $WinSCPLocalVersionFile = "$LocalWinSCPPath\winscpversion.txt"
    if(!(Test-Path $WinSCPLocalVersionFile)){"1.0.0" | Out-File $WinSCPLocalVersionFile}
    $InstalledWinSCPVersion = Get-Content -Path $WinSCPLocalVersionFile
    $URL = "https://winscp.net/eng/downloads.php"

    try
    {
        $SiteResponse = Invoke-WebRequest -Uri $URL -UseBasicParsing
        $WinSCPOnlineVersion = ($SiteResponse.Links | SELECT href | WHERE {$_.href -like "*Portable.*"}).href -replace("/download/WinSCP-","") -replace("-Portable.zip","") -replace("/download","")
    }
    catch
    {
        Write-Host "Update Error: $($Error[0].Exception.Message)$([System.Environment]::NewLine)$($Error[0].Exception.ToString())"
        break
    }

    if($InstalledWinSCPVersion -ne $WinSCPOnlineVersion)
    {
        Write-Host "Updating WinSCP-Portable, please wait ..." -ForegroundColor Yellow
        try
        {
            $NewDownloadLink = "https://winscp.net/download/WinSCP-$($WinSCPOnlineVersion)-Portable.zip/download"
            
            $webclient = [System.Net.WebClient]::new()
            $webclient.DownloadFile("https://sourceforge.net/projects/winscp/files/WinSCP/$($WinSCPOnlineVersion)/WinSCP-$($WinSCPOnlineVersion)-Portable.zip/download","$LocalWinSCPPath\WinSCP-$($WinSCPOnlineVersion)-Portable.zip")
            
            Expand-Archive -Path "$LocalWinSCPPath\WinSCP-$($WinSCPOnlineVersion)-Portable.zip" -DestinationPath "$LocalWinSCPPath" -Force
            $WinSCPOnlineVersion | Out-File $InstalledWinSCPVersion | Out-Null
            Remove-Item -Path "$LocalWinSCPPath\WinSCP-$($WinSCPOnlineVersion)-Portable.zip"
            $WinSCPOnlineVersion | Out-File $WinSCPLocalVersionFile
            Write-Host "Update Complete! Latest Version '$($WinSCPOnlineVersion)' is now Installed" -ForegroundColor Green
        }
        catch
        {
            #Write-Host "Update Error: $($Error[0].Exception.Message)$([System.Environment]::NewLine)$($Error[0].Exception.ToString())"
            Write-Host "Update Error: $($_.Exception.Message)$([System.Environment]::NewLine)$($_.Exception.ToString())"
        }
        
    }
    else
    {
        "You´re on the Latest WinSCP-Portable Verion: $($WinSCPOnlineVersion)"
    }
}


$FunctionsToExport = "Update-WinSCPPrtable"