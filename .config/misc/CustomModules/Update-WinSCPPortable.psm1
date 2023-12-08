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
    $SiteContent = (Invoke-WebRequest -Method Get -Uri $URL -UseBasicParsing).rawcontent
    $html = New-Object -ComObject "HTMLFile"

    try
    {
        # Works when Office is Installed
        $html.IHTMLDocument2_write($SiteContent)
    }
    catch
    {
        # Works if Office is not Installed
        $src = [System.Text.Encoding]::Unicode($SiteContent)
        $html.write($src)
    }
    $WinSCPOnlineVersion = (($html.all.tags("a") | Where {($_.innerText -like "*Download WinSCP*") -and ($_.innerText -notlike "*beta*")} ).innerText -replace("Download WinSCP ","") -split(" "))[0]


    if($InstalledWinSCPVersion -ne $WinSCPOnlineVersion)
    {
        Write-Host "New WinSCP Version found: $($WinSCPOnlineVersion)" -ForegroundColor Yellow
        Write-Host "Updating WinSCP-Portable, please wait ..." -ForegroundColor Yellow
        try
        {
            $NewDownloadLink = "https://winscp.net/download/WinSCP-$($WinSCPOnlineVersion)-Portable.zip"
            
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
            Write-Host "Update Error: $($Error[0].Exception.Message)$([System.Environment]::NewLine)$($Error[0].Exception.ToString())"
        }
        
    }
    else
    {
        "You´re on the Latest WinSCP-Portable Verion: $($WinSCPOnlineVersion)"
    }
}


$FunctionsToExport = "Update-WinSCPPrtable"