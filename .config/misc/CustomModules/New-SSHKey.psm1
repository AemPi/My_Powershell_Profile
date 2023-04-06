#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     New-SSHKey.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################
function New-SSHKey()
{
    Param(
        [Parameter(Mandatory=$true,Position=0)][string]$BenutzerName,
        [Parameter(Mandatory=$false,Position=0)][switch[]]$PassPhrase = $false
    )

    $ScriptPath = Split-Path -Parent $PSCommandPath
    $winSCPCom = "$(($ScriptPath).replace('CustomModules',''))WinSCP\WinSCP.com"
    $SSHcommand = (Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*').state

    if(!(Test-Path $env:USERPROFILE\Desktop\$BenutzerName))
    {
        Write-Host "Erstelle Verzeichnis auf dem Desktop fuer SSH Key ..." -ForegroundColor Green
        mkdir $env:USERPROFILE\Desktop\$BenutzerName | Out-Null
        mkdir $env:USERPROFILE\Desktop\$BenutzerName\key | Out-Null
    }

    if(($($SSHcommand) -eq "Installed") -and ((Test-Path "$($winSCPCom)")))
    {
        try
        {
            Write-Host "Erstelle ED25519 SSH Key ..." -ForegroundColor Green
            if(!$PassPhrase)
            {
                ssh-keygen.exe -t ed25519 -m PEM -C $BenutzerName -f $env:USERPROFILE\Desktop\$BenutzerName\key\id_ed25519 -q -N """"
            }
            else
            {
                $SecPW = Read-Host -AsSecureString "Enter SSH-Key PassPhrase"
                $PlainPW = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecPW))
                ssh-keygen.exe -t ed25519 -m PEM -C $BenutzerName -f $env:USERPROFILE\Desktop\$BenutzerName\key\id_ed25519 -q -N "$PlainPW"
            }
            start-Sleep 3
            Write-host "Erstelle Named kopie des Public Keys ..." -ForegroundColor Green
            Copy-Item -Path "$env:USERPROFILE\Desktop\$BenutzerName\key\id_ed25519.pub" -Destination "$env:USERPROFILE\Desktop\$BenutzerName\key\$($BenutzerName)@ed25519.pub"
        }
        catch
        {
            $Exception = $_.Exception.Message
            Write-Host $Exception
            Write-Host "Exit Script..." -BackgroundColor Red -ForegroundColor White
            exit
        }
        
        Start-Sleep 3

        try
        {
            Write-Host "Konvertiere OpenSSH Key nach .ppk ..." -ForegroundColor Green
            & "$($winSCPCom)" /keygen $env:USERPROFILE\Desktop\$BenutzerName\key\id_ed25519 /output=$env:USERPROFILE\Desktop\$BenutzerName\key\id_ed25519.ppk
        }
        catch
        {
            $Exception = $_.Exception.Message
            Write-Host $Exception
            Write-Host "Exit Script..." -BackgroundColor Red -ForegroundColor White
            exit
        }
    }
    else
    {
        Write-Host "Es wurde keine installation von OpenSSH gefunden!" -BackgroundColor Red
    }
}

$FunctionsToExport = "New-SSHKey"