#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     Request-Connections.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################

$ScriptPath = Split-Path -Parent $PSCommandPath
$ModuleConfigPath = $ScriptPath -replace("\\misc\\CustomModules","")
$ConfigJson = Get-Content "$ModuleConfigPath\.module-config.json" -raw  | ConvertFrom-Json
# Paths from JSON Config
#Exchange online
$UserPrincipalName = "$($ConfigJson.ExOnline.UserPrincipalName)"
$DelegatedOrganization = "$($ConfigJson.ExOnline.DelegatedOrganization)"
# Exchange OnPrem
$ExOnPremConnectionUri = "$($ConfigJson.ExOnPrem.ConnectionUri)"
$ExOnPremUser = "$($ConfigJson.ExOnPrem.ExOnPremUser)"
# VMware vCenter Server
$VIServer = "$($ConfigJson.vCenter.VIServer)"
$VIUserName = "$($ConfigJson.vCenter.VIUserName)"

###########################################################
# Connect to Microsoft Exchange Online
###########################################################
function connect-exonline
{
    try {
        if(-not $(Get-Module -ListAvailable -Name ExchangeOnlineManagement))
        {
            Write-Host "[?] ExchangeOnlineManagement Module is not installed. $([System.Environment]::NewLine)Install it with 'Install-Module -Name ExchangeOnlineManagement'" -ForegroundColor DarkYellow
            break
        }
        Import-Module -Name ExchangeOnlineManagement
        Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -DelegatedOrganization $DelegatedOrganization
    }
    catch {
        $_.Exception.Message
    }    
}

###########################################################
# Connect to Local Exchange
###########################################################
function connect-exonprem
{
    try {
        $LiveCred = Get-Credential -Message "Bitte anmeldedaten eingeben " -UserName $ExOnPremUser
        $SessionOpt = New-PSSessionOption -SkipCACheck:$true -SkipCNCheck:$true -SkipRevocationCheck:$true
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ExOnPremConnectionUri -Credential $LiveCred -SessionOption $SessionOpt
        Import-PSSession $Session
    }
    catch {
        $_.Exception.Message
    }    
}

###########################################################
# Connect to VMWare vCenter Server
###########################################################
function connect-vcenter
{
    $ErrorActionPreference = "SilentlyContinue"
    $VMwareParticipateInCEIP = (Get-PowerCLIConfiguration -Scope User).ParticipateInCEIP
    if($VMwareParticipateInCEIP -eq $true)
    {
        "DISABLE 'VMware's Customer Experience Improvement Program (CEIP)' ..."
        try {
            Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
        }
        catch {
            $_.Exception.Message
        }
    }

    try {
        if(-not $(Get-Module -ListAvailable -Name VMware.PowerCLI*))
        {
            Write-Host "[?] VMware PowerCLI Module is not installed. $([System.Environment]::NewLine)Install it with 'Install-Module VMware.PowerCLI -Scope CurrentUser'" -ForegroundColor DarkYellow
            break
        }
        $Cred = Get-Credential -Message "Bitte anmeldedaten eingeben " -UserName $VIUserName
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12 
        Connect-VIServer $VIServer -Credential $Cred
    }
    catch {
        $_.Exception.Message
    }    
}