#=======================================================================
# Created on:   18.01.2023 13:37
# Created by:   Markus Pröpper <markus.proepper@t-online.de>
# Organization: None
# Filename:     default_module.psm1   
#=======================================================================

<#
.SYNOPSIS


.DESCRIPTION
-  

.NOTES
- requires 
#>

#############################################################
# FUNCTIONS
#############################################################
# System Uptime/Last Reboot
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
        $UPTIME = (get-date) – (gcim Win32_OperatingSystem).LastBootUpTime
        $SYSUP += [PSCustomObject]@{LastReboot=$($LastReboot);Uptime="$($UPTIME.Days) Days, $($UPTIME.Hours) Hours, $($UPTIME.Minutes) Minutes, $($UPTIME.Seconds) Seconds"}
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

# Check User is in Admin Role (boolen)
function Test-IsAdmin()
{
    # Alternative: [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] “Administrator”)
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
        $Admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] “Administrator”)
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

# Write a Logfile
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

# Function to cleanup Files
function Remove-OldFiles([string]$Path,[string]$Daysback)
{
    $Days = "-$($Daysback)"
    $CurrentDate = Get-Date
    $DatetoDelete = $CurrentDate.AddDays($Days)

    try{
        Get-ChildItem $Path -Recurse | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item -Recurse -Confirm:$false -Force
    }
    catch{
        $FailMessage = $Error[0].Exception.Message
        Write-Host "An Error occurred while Trying to delete Files :: $($FailMessage)" -ForegroundColor White -BackgroundColor Red
    }
}

# INI FILE HANDLING
Function Get-IniContent()
{  
    <#  
    .Synopsis  
        Gets the content of an INI file  
          
    .Description  
        Gets the content of an INI file and returns it as a hashtable  
          
    .Notes  
        Author        : Oliver Lipkau <oliver@lipkau.net>  
        Blog        : http://oliver.lipkau.net/blog/  
        Source        : https://github.com/lipkau/PsIni 
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
        Version        : 1.0 - 2010/03/12 - Initial release  
                      1.1 - 2014/12/11 - Typo (Thx SLDR) 
                                         Typo (Thx Dave Stiff) 
          
        #Requires -Version 2.0  
          
    .Inputs  
        System.String  
          
    .Outputs  
        System.Collections.Hashtable  
          
    .Parameter FilePath  
        Specifies the path to the input file.  
          
    .Example  
        $FileContent = Get-IniContent "C:\myinifile.ini"  
        -----------  
        Description  
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent  
      
    .Example  
        $inifilepath | $FileContent = Get-IniContent  
        -----------  
        Description  
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent  
      
    .Example  
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"  
        C:\PS>$FileContent["Section"]["Key"]  
        -----------  
        Description  
        Returns the key "Key" of the section "Section" from the C:\settings.ini file  
          
    .Link  
        Out-IniFile  
    #>  
      
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [string]$FilePath  
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $ini = @{}  
        switch -regex -file $FilePath  
        {  
            "^\[(.+)\]$" # Section  
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0  
            }  
            "^(;.*)$" # Comment  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $value = $matches[1]  
                $CommentCount = $CommentCount + 1  
                $name = "Comment" + $CommentCount  
                $ini[$section][$name] = $value  
            }   
            "(.+?)\s*=\s*(.*)" # Key  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                $ini[$section][$name] = $value  
            }  
        }  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
        Return $ini  
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
}

# Create MySQL-Connection
function Connect-MySQL()
{
    
    param(
        [Parameter(Mandatory=$true)][string]$MySQLUsername,
        [Parameter(Mandatory=$true)][string]$MySQLPassword,
        [Parameter(Mandatory=$true)][string]$MySQLServerName,
        [Parameter(Mandatory=$false)][string]$MySQLDatabaseName
    )
    [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
    # Open Connection
    if([system.string]::IsNullOrEmpty($MySQLDatabaseName))
    {
        $MySQLConnectionString = "server=$MySQLServerName;user id=$MySQLUsername;password=$MySQLPassword;pooling=false"
    }
    else
    {
        $MySQLConnectionString = "server=$MySQLServerName;user id=$MySQLUsername;password=$MySQLPassword;database=$MySQLDatabaseName;pooling=false"
    }
    try {
        $MySQLConnection = New-Object MySql.Data.MySqlClient.MySqlConnection($MySQLConnectionString)
        $MySQLConnection.Open()
    } catch [System.Management.Automation.PSArgumentException] {
        Write-LogFile -status "FAIL" -Message "Unable to connect to MySQL server" -LogPath $global:logfilepath
        Exit
    }
    Write-LogFile -Status "OKAY" -Message "Connected to MySQL server" -LogPath $global:logfilepath
    return $MySQLConnection
}

# Invoke MySQL-Querys
function Invoke-MySQLQuery([string]$query, $MySQLConnection)
{
    $cmd = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $MySQLConnection)
    
    $dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($cmd)
    $dataSet = New-Object System.Data.DataSet
    $dataAdapter.Fill($dataSet, "Daten") | out-null
    $cmd.Dispose()
    return $dataSet.Tables["Daten"]
}

# Close MySQL-Connection
function Disconnect-MySQL($MySQLConnection)
{
    # Close Connection
    $MySQLConnection.Close()
    Write-Host "Disconnected from MySQL server" -ForegroundColor White -BackgroundColor Green
}

function Send-Telegram()
{
    param(
      [Parameter(Mandatory=$false)][ValidateSet('OKAY','WARN','FAIL')][string]$Icon,
      [Parameter(Mandatory=$false)][string]$T_Token,
      [Parameter(Mandatory=$false)][string]$T_ChatID,
      [Parameter(Mandatory=$false)][string]$T_Message
    )

    $Hostname = $env:COMPUTERNAME

    if(![System.String]::IsNullOrEmpty($T_Token) -and ![System.String]::IsNullOrEmpty($T_ChatID))
    {
      $TelegramBotToken  = "$($T_Token)"
      $TelegramBOTChatID = "$($T_ChatID)"
      
      Switch ($Icon)
      { 
        OKAY { $Status_Icon = $([regex]::Unescape('\u2705')) }
        WARN { $Status_Icon = $([regex]::Unescape('\u26a0\ufe0f')) }
        Fail { $Status_Icon = $([regex]::Unescape('\ud83c\udd98')) }
        default { $Status_Icon = "" }
      }

      $MessageBody = @"
-----------------------------
--- $($Hostname) $($Status_Icon) ---
-----------------------------
$($T_Message)
"@

      try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($TelegramBotToken)/sendMessage?chat_id=$($TelegramBOTChatID)&text=$($MessageBody)"
        #$($MessageBody)
        Write-Host "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") :: Send Telegram :: $($Response)"
      }
      catch {
        $Fail = $Error[0].Exception.Message
        Write-Warning "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") :: Failed to Send Telegram :: $($Fail)"
      }
      
    }
    else
    {
        Write-Warning "No Icon, Telegram Token (T_Token) or ChatID (T_ChatID) Available!"
    }
}

#############################################################
# Definition der zu exportierenden Funktionen
#############################################################
$FunctionsToExport = "Get-Uptime", `
                     "Test-IsAdmin", `
                     "Write-LogFile", `
                     "Remove-OldFiles", `
                     "Get-IniContent", `
                     "Connect-MySQL", `
                     "Invoke-MySQLQuery", `
                     "Disconnect-MySQL", `
                     "Test-RunAsAdmin", `
                     "Send-Telegram"