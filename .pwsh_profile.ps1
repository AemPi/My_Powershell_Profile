######################################################
# For SSH Tab Complition
######################################################
using namespace System.Management.Automation

######################################################
# Private Variables
######################################################
$sScriptPath = Split-Path -Parent $PSCommandPath
$ConfigJson = Get-Content "$sScriptPath\.pwsh_config.json" -raw  | ConvertFrom-Json
# Paths from JSON Config
$ConfigFolder = $ExecutionContext.InvokeCommand.ExpandString($ConfigJson.Paths.ConfigFolder)
$ConfigModules = $ExecutionContext.InvokeCommand.ExpandString($ConfigJson.Paths.Modules)
$ConfigMOTD = $ExecutionContext.InvokeCommand.ExpandString($ConfigJson.Paths.MOTD)
$ConfigPSWHhistory = $ExecutionContext.InvokeCommand.ExpandString($ConfigJson.Paths.PSWHhistory)
$ConfigSSHconfig = $ExecutionContext.InvokeCommand.ExpandString($ConfigJson.Paths.SSHconfig)
$ConfigPSSconfig = $ExecutionContext.InvokeCommand.ExpandString($ConfigJson.Paths.PSSconfig)
# PSReadLine Colors
$InlinePrediction = "$($ConfigJson.Colors.CustomColor_Gray)"
$Command = "$($ConfigJson.Colors.ConsoleColor_Green)"
$Comment = "$($ConfigJson.Colors.ConsoleColor_Gray)"
$Variable = "$($ConfigJson.Colors.CustomColor_Orange)" 

######################################################
# Imported Modules
######################################################
#Import-Module PSReadline -RequiredVersion 2.1.0
#Import-Module PSReadline
#Import-Module "$($ConfigFolder)\default_module.psm1"
$CustomModules = (Get-ChildItem -Path "$($ConfigFolder)\CustomModules" -Filter "*.psm1").FullName
foreach($Module in $CustomModules){Import-Module $Module}
######################################################
# Login Check if Admin or not
######################################################
function Test-IsAdmin()
{
    # Alternative: [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] “Administrator”)
}
$IsAdmin = (Test-IsAdmin)
if($IsAdmin)
{
    $HeaderText = "# ⚠️ Attention This Session runs with elevated Privilege!!! ⚠️ #"
    $HeaderDekoLine = "#"*$HeaderText.Length
    write-host "$($HeaderDekoLine)" -ForegroundColor Yellow -BackgroundColor Red
    write-host "$($HeaderText)" -ForegroundColor Yellow -BackgroundColor Red
    write-host "$($HeaderDekoLine)" -ForegroundColor Yellow -BackgroundColor Red
}

######################################################
# MOTD
######################################################
if ((Test-Path "$ConfigMOTD")) {
    $MOTD = [System.Management.Automation.ScriptBlock]::Create("$ConfigMOTD")
    & $MOTD
}
else {
    $bootuptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $CurrentDate = Get-Date
    $uptime = $CurrentDate - $bootuptime
    write-host "Hello Friend!" -ForegroundColor Green
    write-host "########################################################" -ForegroundColor Green
    Write-host "System Uptime: $($uptime.days) Days, $($uptime.Hours) Hours, $($uptime.Minutes) Minutes" -ForegroundColor Green
    write-host "########################################################" -ForegroundColor Green
}

Function Reload-Modules()
{
    try
    {
        $CustomModules = (Get-ChildItem -Path "$ConfigModules" -Filter "*.psm1").FullName
        foreach($Module in $CustomModules){Import-Module $Module -Force}
    }
    catch
    {
        $Fail = $Error[0].Exception.Message
        Write-Warning $Fail
    }
}

######################################################
# List Files and Folders (Linux Like)
# https://superuser.com/questions/468782/show-human-readable-file-sizes-in-the-default-powershell-ls-command | From Indrek
######################################################
Function Format-FileSize() {
    Param ($size)
    If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} Byte", $size)}
    Else                   {""}
}

function Get-ItemPermissions
{
    write-host "$([System.Environment]::NewLine)Possible Mode Values: d - Directory, a - Archive, r - Read-only,
                      h - Hidden, s - System, l - Reparse point, symlink, etc."
    Get-ChildItem $Args[0] -Force | Sort-Object Mode |
        Format-Table Mode, @{N='Owner';E={(Get-Acl $_.FullName).Owner}}, @{N="FileSize";E={ Format-FileSize -size $_.Length }}, LastWriteTime, @{N='Name';E={if($_.Target) {$_.Name+' -> '+$_.Target} else {$_.Name}}}
}

function ls-DirSize()
{
    Param
    (
      [Parameter(Mandatory=$false)][string]$DirectoryPath  
    )
    
    if([system.string]::IsNullOrEmpty($DirectoryPath))
    {
        $targetfolder='.'
        $dataColl = @()
        Get-ChildItem -force $targetfolder -ErrorAction SilentlyContinue | Where-Object { $_ -is [io.directoryinfo] } | ForEach-Object {
        $len = 0
        Get-ChildItem -recurse -force $_.fullname -ErrorAction SilentlyContinue | ForEach-Object { $len += $_.length }
        $foldername = $_.BaseName
        $foldersize= '{0:N2}' -f (Format-FileSize -size $len)
        $dataObject = New-Object PSObject
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "Folder" -value $foldername
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "Size" -value $foldersize
        $dataColl += $dataObject
        }
        $dataColl | Format-Table -AutoSize
    }
    else
    {
        $targetfolder= "$DirectoryPath"
        $dataColl = @()
        Get-ChildItem -force $targetfolder -ErrorAction SilentlyContinue | Where-Object { $_ -is [io.directoryinfo] } | ForEach-Object {
        $len = 0
        Get-ChildItem -recurse -force $_.fullname -ErrorAction SilentlyContinue | ForEach-Object { $len += $_.length }
        $foldername = $_.BaseName
        $foldersize= '{0:N2}' -f (Format-FileSize -size $len)
        $dataObject = New-Object PSObject 
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "Folder" -value $foldername
        Add-Member -inputObject $dataObject -memberType NoteProperty -name "Size" -value $foldersize
        $dataColl += $dataObject
        }
        $dataColl | Format-Table -AutoSize
    }
    
}

######################################################
# sudo for Powershell (Linux Like)
# https://www.elasticsky.de/2012/12/powershell-sudo/
######################################################
function grant-process
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
#Indicates that the cursor moves to the end of commands that you load from history by using a search.
# When this parameter is set to $False, the cursor remains at the position it was when you pressed the up or down arrows.
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
# Responds to various error and ambiguous conditions Default is Audible
Set-PSReadLineOption -BellStyle None
#Gives completions/suggestions from historical commands
if ($host.name -eq 'ConsoleHost') # or -notmatch 'ISE'
{
    Set-PSReadLineOption -PredictionSource History
}
Set-PSReadLineOption -Colors @{ 
    InlinePrediction = "$($InlinePrediction)"
    Command = "$($Command)"
    Comment = "$($Comment)"
    Variable = "$($Variable)"
}
#Set-PSReadLineOption -PredictionViewStyle ListView

# Linux like History File
Set-PSReadLineOption -HistorySavePath "$ConfigPSWHhistory"
# Default History Count is 4096
Set-PSReadLineOption -MaximumHistoryCount 1000
# prevents to write lines that match password|asplaintext|token|key|secret to the log.
Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$line)

    $sensitive = "password|asplaintext|token|key|secret"
    return ($line -notmatch $sensitive)
}

######################################################
# Smart Insert
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
    <#
    # KnownHost file
    $knownHosts = Get-Content ${Env:HOMEPATH}\.ssh\known_hosts `
    | ForEach-Object { ([string]$_).Split(' ')[0] } `
    | ForEach-Object { $_.Split(',') } `
    | Sort-Object -Unique
    #>
    
    # Config File
    $hosts = Get-Content $ConfigSSHconfig `
    | Select-String -Pattern "^Host "`
    | ForEach-Object { $_ -replace "host ", "" }`
    | Sort-Object -Unique

    # Config File
    $hosts2 = Get-Content "$ConfigSSHconfig.d\*" `
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

    $hosts2 `
    | Where-Object { $_ -like "${textToComplete}*" } `
    | ForEach-Object { [CompletionResult]::new((&$generateCompletionText($_)), $_, [CompletionResultType]::ParameterValue, $_) }
}

################################################################################
# PSSession Host Tab Complition from pss Config file
# 
################################################################################
Register-ArgumentCompleter -CommandName New-PSSession,pss -Native -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    # Config File
    $hosts = Get-Content $ConfigPSSconfig `
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
# ssh Like function for New-PSSession
#######################################################
function pss()
{
   Param
    (
        [Parameter(Mandatory=$true)][string[]]$RemoteComputer,
        [Parameter(Mandatory=$false)][switch[]]$domain = $false
    )

    if($domain)
    {
        try
        {
            $PSs = New-PSSession -Authentication Kerberos -ComputerName $RemoteComputer -ErrorAction SilentlyContinue
            Enter-PSSession $PSs
        }
        catch
        {
            Write-Warning "Wrong Username/Password $([System.Environment]::NewLine)$($Error[0])"
        }
    }
    else
    {
        $User = Read-Host "Username "
        $PWord = Read-Host "Password " -AsSecureString

        if(![System.String]::IsNullOrEmpty($User) -and !$PWord.Length -eq 0)
        {
            try
            {
                $Credentials = New-Object -TypeName PSCredential -ArgumentList $User, $PWord
                $PSs = New-PSSession -ComputerName $RemoteComputer -Credential $Credentials -ErrorAction SilentlyContinue
                Enter-PSSession $PSs
            }
            catch
            {
                Write-Warning "Wrong Username/Password Wrong $([System.Environment]::NewLine)$($Error[0])"
            }
        }
        else
        {
            Write-Warning "Insufficient Credentials!"
        }
    }
}

# https://www.jesusninoc.com/11/05/simulate-key-press-by-user-with-sendkeys-and-powershell/
function Send-ExitKeys {
    param (
        $SENDKEYS,
        $WINDOWTITLE
    )
    $wshell = New-Object -ComObject wscript.shell;
    IF ($WINDOWTITLE) {$wshell.AppActivate($WINDOWTITLE)}
    Start-Sleep 1
    IF ($SENDKEYS) {$wshell.SendKeys($SENDKEYS)}
}

Set-PSReadlineKeyHandler -Key 'ctrl+d' {
    Exit-PSSession
    Send-ExitKeys -SENDKEYS '{enter}'
    Get-PSSession | Remove-PSSession
}

######################################################
# df Like function for Get-Volume
#######################################################
Function Format-Byte() {
    Param ($size)
    $bytecount = $size 
    switch -Regex ([math]::truncate([math]::log($bytecount,1024))) {
        '^0' {"$bytecount Bytes"}
        '^1' {"{0:n2} KB" -f ($bytecount / 1KB)}
        '^2' {"{0:n2} MB" -f ($bytecount / 1MB)}
        '^3' {"{0:n2} GB" -f ($bytecount / 1GB)}
        '^4' {"{0:n2} TB" -f ($bytecount / 1TB)}
        '^5' {"{0:n2} PB" -f ($bytecount / 1PB)}
         Default {""}
    }

}

Function FormatPercent()
{
    Param
    ($Sizes)
    $Percent = [Math]::round($Sizes)
    "$Percent %"
}

function df()
{
    Param
    (
        [Parameter(Mandatory=$false)][switch[]]$h = $false
    )
    if(!$h)
    {
        Get-psdrive -PSProvider FileSystem | Format-Table `
                                                @{N='Drive';E={$_.Name}; Alignment="left"}, `
                                                #@{N='Total';E={(Get-Volume -DriveLetter $_.Name).Size}}, `
                                                @{N='Total';E={($_.Used + $_.Free)}; Alignment="right"}, `
                                                @{N='Used';E={($_.Used)}; Alignment="right"}, `
                                                @{N='Free';E={($_.Free)}; Alignment="right"}, `
                                                @{N='%iUsed';E={FormatPercent -Sizes (($_.Used/($_.Used+$_.Free)) * 100)}; Alignment="right"}, `
                                                @{N='Mounted';E={$_.DisplayRoot}; Alignment="left"} -AutoSize
    }
    else
    {

        Get-psdrive -PSProvider FileSystem | Format-Table `
                                                @{N='Drive';E={$_.Name}; Alignment="left"}, `
                                                #@{N='Total (GB)';E={[Math]::Round((Get-Volume -DriveLetter $_.Name).Size /1GB,2)}}, `
                                                @{N='Total';E={(Format-Byte -size ($_.Used +$_.Free))}; Alignment="right"}, `
                                                @{N='Used';E={(Format-Byte -size $_.Used)}; Alignment="right"}, `
                                                @{N='Free';E={(Format-Byte -size $_.Free)}; Alignment="right"}, `
                                                @{N='%iUsed';E={FormatPercent -Sizes (($_.Used/($_.Used+$_.Free)) * 100)}; Alignment="right"}, `
                                                @{N='Mounted';E={$_.DisplayRoot}; Alignment="left"} -AutoSize
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
    if($IsAdmin){$PromptSign = "#"}else{$PromptSign = "$"}

    # replace the path from USERPROFILE environment variable (if it’s there) in current path by ~
    $currentDir = $pwd.Path.Replace($env:USERPROFILE, "~")
    
    # Git Status Calling Variable
    $GitStatus = GitStat
    
    # Date over the Prompt
    #$Content = $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    #Write-Host $Content -ForegroundColor Yellow
    
    # Default Prompt
    #return "[$($env:USERNAME)@$($env:COMPUTERNAME)] ($($currentDir)) $GitStatus $($PromptSign)"
    
    # PROMPT DESIGN - DEFAULT IS oneline
    #$PROMPT_ALTERNATIVE="oneline"
    $PROMPT_ALTERNATIVE="twoline"

    # Colored Prompt
    # If you want the default (not Colored Prompt)
    # add <# from here and #> after 'return " "'
    # then uncommetn the default prompt above
    #=================================================
    # Colors for Prompt
    $OpenBraketColor  = $ConfigJson.Colors.OpenBraketColor
    $UserColor        = $ConfigJson.Colors.UserColor
    $AtSignColor      = $ConfigJson.Colors.AtSignColor
    $HostColor        = $ConfigJson.Colors.HostColor
    $ClosingBraketColor = $ConfigJson.Colors.CloseBraketColor
    $CurrDirColor     = $ConfigJson.Colors.CurrDirColor
    $GitStatusColor   = $ConfigJson.Colors.GitStatusColor
    $PromptSignColor  = $ConfigJson.Colors.PromptSignColor

    # Works with Windows 10
    $Firstline = $([regex]::Unescape('\u256d\u2500'))  #╭─
    $SecondLine = $([regex]::Unescape('\u2570\u2500')) #╰─

    if ($PROMPT_ALTERNATIVE -eq "oneline") {
        Write-Host "["                    -n -f $OpenBraketColor
        Write-Host "$($env:USERNAME)"     -n -f $UserColor
        Write-Host "@"                    -n -f $AtSignColor
        Write-Host "$($env:COMPUTERNAME)" -n -f $HostColor
        Write-Host "]"                    -n -f $ClosingBraketColor
        Write-Host " ($($currentDir))"    -n -f $CurrDirColor
        Write-Host " $GitStatus "         -n -f $GitStatusColor
        Write-Host "$($PromptSign)>"      -n -f $PromptSignColor
        return " "
    }
    elseif ($PROMPT_ALTERNATIVE -eq "twoline") {
        # Prompt | -n = NoNewLine | -f = ForegroundColor
        Write-Host "$Firstline["          -n -f $OpenBraketColor
        Write-Host "$($env:USERNAME)"     -n -f $UserColor
        Write-Host "@"                    -n -f $AtSignColor
        Write-Host "$($env:COMPUTERNAME)" -n -f $HostColor
        Write-Host "]"                    -n -f $ClosingBraketColor
        Write-Host " ($($currentDir))"    -n -f $CurrDirColor
        Write-Host " $GitStatus "          -f $GitStatusColor
        Write-Host "$SecondLine$($PromptSign)>"     -n   -f $PromptSignColor
        return " "
    }
    else {
        Write-Host "["                    -n -f $OpenBraketColor
        Write-Host "$($env:USERNAME)"     -n -f $UserColor
        Write-Host "@"                    -n -f $AtSignColor
        Write-Host "$($env:COMPUTERNAME)" -n -f $HostColor
        Write-Host "]"                    -n -f $ClosingBraketColor
        Write-Host " ($($currentDir))"    -n -f $CurrDirColor
        Write-Host " $GitStatus "         -n -f $GitStatusColor
        Write-Host "$($PromptSign)>"      -n -f $PromptSignColor
        return " "
    }
    
}