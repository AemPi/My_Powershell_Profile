######################################################
# For SSH Tab Complition
######################################################
using namespace System.Management.Automation

######################################################
# Login Check if Admin or not
######################################################
if([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))
{
    $IsAdmin = "Yes"
    write-host "##############################################################################" -ForegroundColor Yellow -BackgroundColor Red
    #write-host "# ACHTUNG DIE POWERSHELL SESSION LAEUFT MIT ADMINISTRATOR RECHTEN!!!         #" -ForegroundColor Yellow -BackgroundColor Red
    write-host "# Attention This Session runs with elevated Privilege!!!                     #" -ForegroundColor Yellow -BackgroundColor Red
    write-host "##############################################################################" -ForegroundColor Yellow -BackgroundColor Red
}
else
{}

######################################################
# Commandline Loggin
######################################################
$PSlogging = "P:\PSlogging"
if((Test-Path $PSlogging))
{
    $PSlogging = "P:\PSlogging"
}
else
{
    $PSlogging = "C:\PSlogging"
}

######################################################
# Powershell Transcript Logging
######################################################
if (-not (Test-Path $PSlogging))
{
    New-Item -Type Directory $PSlogging
}
$dateStamp = Get-Date -Format ('yyyy-MM-dd_HH-mm-ss')
try
{
    Get-ChildItem "$PSlogging" -Recurse | Where-Object { $_.LastWriteTime -lt (get-date).AddDays(-60) } | Remove-Item -Force -Confirm:$false
    Start-Transcript "$PSlogging\PSconsole_$dateStamp.txt" | Out-Null
}
catch [System.Management.Automation.PSNotSupportedException]
{
    # ISE doesn't allow transcripts.
    Write-Host "No transcript. Not supported in this host."
}

######################################################
# MOTD
######################################################

# write-host "########################################################"     -ForegroundColor Green
# Write-Host "Microsoft Windows Info"                                       -ForegroundColor Green
# write-host "Windows System : $((Get-WmiObject win32_operatingsystem).caption) ($((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId))"   -ForegroundColor Green
# write-host "Windows Version: $(([Environment]::OSVersion).VersionString)" -ForegroundColor Green
# Write-Host "########################################################"     -ForegroundColor Green
# Write-Host "Network Info" -ForegroundColor Green
# write-host "Hostname  : $($env:COMPUTERNAME)" -ForegroundColor Green
# Write-Host "Domain    : $($env:USERDNSDOMAIN)" -ForegroundColor Green


$bootuptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$CurrentDate = Get-Date
$uptime = $CurrentDate - $bootuptime

write-host "Hello Friend!" -ForegroundColor Green
write-host "########################################################" -ForegroundColor Green
Write-host "System Uptime: $($uptime.days) Days, $($uptime.Hours) Hours, $($uptime.Minutes) Minutes" -ForegroundColor Green

$Interface = Get-WmiObject win32_networkadapterconfiguration | WHERE {($_.IPAddress -ne $null) -and ($_.DefaultIPGateway -ne $null)}

#$Interface = Get-WmiObject win32_networkadapterconfiguration `
#| Select-Object -Property @{name='IPAddress';Expression={($_.IPAddress[0])}},MacAddress `
#| Where-Object IPAddress -Like '10.*'

if ($null -eq $interface)
{
    Write-Host "No Active Connection!" -ForegroundColor Yellow -BackgroundColor Red
}
else
{
    write-host "IPAdress     : $($Interface.IPAddress[0])" -ForegroundColor Green
    write-host "MAC-Adress   : $($Interface.MacAddress)" -ForegroundColor Green
}
write-host "########################################################" -ForegroundColor Green

# write-host "Promt Log Folder : $($PSlogging)" -ForegroundColor Green
# write-host "########################################################" -ForegroundColor Green


######################################################
# List Files and Folders (Linux Like)
# https://superuser.com/questions/468782/show-human-readable-file-sizes-in-the-default-powershell-ls-command | From Indrek
######################################################
Function Format-FileSize() {
    Param ([int]$size)
    If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} Byte", $size)}
    Else                   {""}
}

function Get-ItemPermissions
{
    write-host "Possible Mode Values: d - Directory, a - Archive, r - Read-only,
                      h - Hidden, s - System, l - Reparse point, symlink, etc."
    Get-ChildItem $Args[0] -Force |
        Format-Table Mode, @{N='Owner';E={(Get-Acl $_.FullName).Owner}}, @{N="FileSize";E={ Format-FileSize -size $_.Length }}, LastWriteTime, @{N='Name';E={if($_.Target) {$_.Name+' -> '+$_.Target} else {$_.Name}}}
}

######################################################
# sudo for Powershell (Linux Like)
# https://www.elasticsky.de/2012/12/powershell-sudo/
######################################################
function elevate-process
{
    $file, [string]$arguments = $args
    $psi = new-object System.Diagnostics.ProcessStartInfo $file
    $psi.Arguments = $arguments
    $psi.Verb = "runas"
    $psi.WorkingDirectory = get-location
    [System.Diagnostics.Process]::Start($psi) | out-null
}

######################################################
# Tab Complition Section
# If Problems occure install Latest PSReadLine Module
# Install-Module -Name PSReadLine -RequiredVersion 2.1.0 -Force
######################################################
# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

######################################################
# Add and Delete Matching Braces and Quotes
# https://sergeyvasin.com/2020/08/04/quotes-and-brackets/
######################################################
# Insert matching braces
Set-PSReadLineKeyHandler -Key '(','{','[' `
                         -BriefDescription InsertPairedBraces `
                         -LongDescription "Insert matching braces" `
                         -ScriptBlock {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar)
    {
         '(' { [char]')'; break }
         '{' { [char]'}'; break }
         '[' { [char]']'; break }
    }

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
     
    if ($selectionStart -ne -1)
    {
      # Text is selected, wrap it in brackets
      [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    } else {
      # No text is selected, insert a pair
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
}

# Insert matching Quotes
Set-PSReadLineKeyHandler -Key "'",'"' `
                         -BriefDescription InsertPairedBraces `
                         -LongDescription "Insert matching Quotes" `
                         -ScriptBlock {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar)
    {
         "'" { [char]"'"; break }
         '"' { [char]'"'; break }
    }

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
     
    if ($selectionStart -ne -1)
    {
      # Text is selected, wrap it in brackets
      [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    } else {
      # No text is selected, insert a pair
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
}

#  Delete previous character or matching quotes/parens/braces
Set-PSReadLineKeyHandler -Key Backspace `
                         -BriefDescription SmartBackspace `
                         -LongDescription "Delete previous character or matching quotes/parens/braces" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0)
    {
        $toMatch = $null
        if ($cursor -lt $line.Length)
        {
            switch ($line[$cursor])
            {
                 '"' { $toMatch = '"'; break }
                 "'" { $toMatch = "'"; break }
                 ')' { $toMatch = '('; break }
                 ']' { $toMatch = '['; break }
                 '}' { $toMatch = '{'; break }
            }
        }

        if ($toMatch -ne $null -and $line[$cursor-1] -eq $toMatch)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
        }
        else
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
        }
    }
}


################################################################################
# SSH, SCP and sftp Host Tab Complition from ssh Config file
# https://gist.github.com/backerman/2c91d31d7a805460f93fe10bdfa0ffb0#comments
################################################################################
Register-ArgumentCompleter -CommandName ssh,scp,sftp -Native -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    # KnownHost file
    #$knownHosts = Get-Content ${Env:HOMEPATH}\.ssh\known_hosts `
    #| ForEach-Object { ([string]$_).Split(' ')[0] } `
    #| ForEach-Object { $_.Split(',') } `
    #| Sort-Object -Unique
    
    # Config File
    $hosts = Get-Content $Env:USERPROFILE\.ssh\config `
    | Select-String -Pattern "^Host "`
    | ForEach-Object { $_ -replace "host ", "" }`
    | Sort-Object -Unique

    # For now just assume it's a hostname.
    $textToComplete = $wordToComplete
    $generateCompletionText = {
        param($x)
        $x
    }
    if ($wordToComplete -match "^(?<user>[-\w/\\]+)@(?<host>[-.\w]+)$") {
        $textToComplete = $Matches["host"]
        $generateCompletionText = {
            param($hostname)
            #$Matches["user"] + "@" + $hostname
            $hostname
        }
    }

    $hosts `
    | Where-Object { $_ -like "${textToComplete}*" } `
    | ForEach-Object { [CompletionResult]::new((&$generateCompletionText($_)), $_, [CompletionResultType]::ParameterValue, $_) }
}

######################################################
# Check Local Git Repo Status
#######################################################
Function GitStat {
    
    $GetGit = Get-Command git.exe -ErrorAction SilentlyContinue
    if(-not [system.string]::IsNullOrEmpty($GetGit.Name))
    {
        if (Test-Path .git)
        {
            $s = git.exe status #--porcelain
            
            if(-not $s.Contains("nothing to commit, working tree clean"))
            {
                $st = (git.exe status --porcelain).trim()
                $untracked = ($st). Where({$_ -match "^\?\?"})
                $add = ($st).where({$_ -match "^A"})
                $del = ($st).where({$_ -match "^D"})
                $mod = ($st).where({$_ -match "^M"})
                [regex]$rx = "\*.\S+"
                #get the matching git branch which has the * and split the string to get only the branch name
                $branch = $rx.match((git.exe branch)).value.split()[-1]
                return "[git-$branch : A$($add.count)|M$($mod.count)|D$($del.count)|Ut$($untracked.count)]"
            }
            else
            {
                [regex]$rx = "\*.\S+"
                $branch = $rx.match((git.exe branch)).value.split()[-1]
                return "[git-$branch]"
            }
        }
    }
}

######################################################
# cd Linux-Like in to HomeDirectrory
#######################################################
function ChangeDirectory {
    param(
        [parameter(Mandatory=$false)]
        $path
    )
    if ( $PSBoundParameters.ContainsKey('path') ) {
        Set-Location $path
    } else {
        Set-Location $home
    }
}


######################################################
# Aliases
# New-Alias NewCommand Get-ChildItem
#######################################################
New-Alias -Name "ll" -Value Get-ItemPermissions
Remove-Item alias:\cd
New-Alias cd ChangeDirectory
New-Alias -Name sudo -Value elevate-process

#######################################################
# Prompt Section
#######################################################
function global:prompt
{
    # If Prompt is in Admin Mode then set # else set $
    if($IsAdmin -eq "Yes"){$PromptSign = "#"}else{$PromptSign = "$"}

    # replace the path from USERPROFILE environment variable (if it�s there) in current path by ~
    $currentDir = $pwd.Path.Replace($env:USERPROFILE, "~")
    $GitStatus = GitStat
    $Content = $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Write-Host $Content -ForegroundColor Yellow
    return "[$($env:USERNAME)@$($env:COMPUTERNAME)] ($($currentDir)) $GitStatus $($PromptSign)"
    #return " # "
}

#######################################################
# Create Custom Logfile
#######################################################
function Write-LogFile([string]$Message,[string]$Status,[string]$LogPath)
{
    $LogFileDate = Get-date -Format "yyyy-MM-dd HH:mm:ss"
    $DEKOcut = "================================================="

    Switch ($Status)
      {
        INFO { Write-Host $LogFileDate  "[$Status]" ": " $Message -BackgroundColor Green -ForegroundColor White ; $LogFileDate + " [$Status]" + ": $Message" | Out-File $LogPath -Append -Encoding utf8 }
        WARN { Write-Host $LogFileDate  "[$Status]" ": " $Message -BackgroundColor Yellow -ForegroundColor Black ; $LogFileDate + " [$Status]" + ": $Message" | Out-File $LogPath -Append -Encoding utf8 }
        FAIL { Write-Host $LogFileDate  "[$Status]" ": " $Message -BackgroundColor Red -ForegroundColor White ; $LogFileDate + " [$Status]" + ": $Message" | Out-File $LogPath -Append -Encoding utf8 }
        OKAY { Write-Host $LogFileDate  "[$Status]" ": " $Message -BackgroundColor Green -ForegroundColor White ; $LogFileDate + " [$Status]" + ": $Message" | Out-File $LogPath -Append -Encoding utf8 }
        DEKO { Write-Host $DEKOcut ; $DEKOcut | Out-File  $LogPath -Append -Encoding utf8 }
      }
}