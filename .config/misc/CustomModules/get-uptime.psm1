#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     Get-Uptime.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################
function Get-Uptime()
{
<#
.SYNOPSIS
  Script to ouput Last Reboot Datetime and Calculate the Uptime
.DESCRIPTION
  This script will ouput Last Reboot Datetime and Calculate the Uptime
.PARAMETER Param1
  None
.INPUTS
  None
.OUTPUTS
  A the DateTime of LastReboot and Uptime since LastReboot
.NOTES
  Version:        0.1
  Author:         Markus Pröpper <markus.proepper@t-online.de>
  Creation Date:  2023-01-18
  Purpose/Change: Initial script development
.EXAMPLE
  Get-Uptime

        Output:
        LastReboot          Uptime                                 
        ----------          ------                                 
        17.01.2023 10:31:46 1 Days, 3 Hours, 15 Minutes, 24 Seconds
    
.EXAMPLE    
  (Get-Uptime).LastReboot

        Output:
        17.01.2023 10:31:46
        
.EXAMPLE    
  (Get-Uptime).Uptime

        Output:
        1 Days, 3 Hours, 15 Minutes, 24 Seconds
#>

#requires -version 5.1
    try
    {
        $SYSUP = @()
        $LastReboot = (gcim Win32_OperatingSystem).LastBootUpTime.ToString()
        $UPTIME = (get-date) - (gcim Win32_OperatingSystem).LastBootUpTime
        $SYSUP += [PSCustomObject]@{LastReboot=$($LastReboot);Uptime="$($UPTIME.Days) Days, $($UPTIME.Hours) Hours, $($UPTIME.Minutes) Minutes, $($UPTIME.Seconds) Seconds";UptimeShort="$($UPTIME.ToString("dd\:hh\:mm\:ss"))"}
        #return "Last Reboot: $($LastReboot)$([System.Environment]::NewLine)System is up since: $($UPTIME.Days) Days, $($UPTIME.Hours) Hours, $($UPTIME.Minutes) Minutes, $($UPTIME.Seconds) Seconds"
        return $SYSUP
        #return "$($SYSUP.LastReboot)$([System.Environment]::NewLine)$($SYSUP.Uptime)"
    }
    catch
    {
        $Line = ""
        $Line = $Error[0].InvocationInfo
        return "Invoked-Command:: $($MyInvocation.MyCommand)$([System.Environment]::NewLine)Message:: $($Error[0].Exception.Message)$([System.Environment]::NewLine)Position:: In Line: $($Line.ScriptLineNumber) Sign: $($Line.OffsetInLine)"
    }
}

$FunctionsToExport = "Get-Uptime"