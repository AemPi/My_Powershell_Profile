##############################################################
#
# Put your MOTD Message below
# ===========================
# invoke the MOTD in your Profile with the next two Lines
# ===========================
# $MOTD = [System.Management.Automation.ScriptBlock]::Create("C:\Path\to\MOTD.ps1")
# & $MOTD
#
##############################################################
$BannerMPRO = "
  #############
  #           #  ███╗   ███╗██████╗ ██████╗  ██████╗ 
  #  >>   <<  #  ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗
  #           #  ██╔████╔██║██████╔╝██████╔╝██║   ██║
  #  #     #  #  ██║╚██╔╝██║██╔═══╝ ██╔══██╗██║   ██║
  #   #####   #  ██║ ╚═╝ ██║██║     ██║  ██║╚██████╔╝
  #           #  ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ 
  #############  https://github.com/AemPi
"

$BannerAemPi = "
  #############
  #           #   █████╗ ███████╗███╗   ███╗██████╗ ██╗
  #  >>   <<  #  ██╔══██╗██╔════╝████╗ ████║██╔══██╗██║
  #           #  ███████║█████╗  ██╔████╔██║██████╔╝██║
  #  #     #  #  ██╔══██║██╔══╝  ██║╚██╔╝██║██╔═══╝ ██║
  #   #####   #  ██║  ██║███████╗██║ ╚═╝ ██║██║     ██║
  #           #  ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝     ╚═╝
  #############  https://github.com/AemPi
"

Write-Host $BannerAemPi -ForegroundColor Cyan

$bootuptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$CurrentDate = Get-Date
$uptime = $CurrentDate - $bootuptime

#write-host "Hello Friend!" -ForegroundColor Green
write-host "########################################################" -ForegroundColor Green
Write-host "System Uptime: $($uptime.days) Days, $($uptime.Hours) Hours, $($uptime.Minutes) Minutes" -ForegroundColor Green

$Interface = Get-CimInstance win32_networkadapterconfiguration | Where-Object {($_.IPAddress -ne $null) -and ($_.DefaultIPGateway -ne $null)}
if ($null -eq $interface)
{
    Write-Host "No Active Network Connection!" -ForegroundColor Yellow -BackgroundColor Red
}
else
{
    #write-host "IPAdress     : $($Interface.IPAddress[0])" -ForegroundColor Green
    #write-host "MAC-Adress   : $($Interface.MacAddress)" -ForegroundColor Green
}
write-host "########################################################" -ForegroundColor Green