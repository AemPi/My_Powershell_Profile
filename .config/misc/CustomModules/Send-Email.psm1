#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     Send-Emails.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################
function Send-Email()
{
    param(
        [Parameter(Mandatory=$false)][string]$SmtpServer,
        [Parameter(Mandatory=$false)][string]$From,
        [Parameter(Mandatory=$true)][string]$Recipient,
        [Parameter(Mandatory=$false)][string]$CarbonCopy,
        [Parameter(Mandatory=$false)][string]$BlindCarbonCopy,
        [Parameter(Mandatory=$true)][string]$Subject,
        [Parameter(Mandatory=$true)][string]$Mailbody,
        [Parameter(Mandatory=$false)][string[]]$Attachments,
        [Parameter(Mandatory=$true)][string]$SendAsUser,
        [Parameter(Mandatory=$true)][string]$PasswordFileSendAS,
        [Parameter(Mandatory=$true)][string]$KeyFile
    )

    if([System.String]::IsNullOrEmpty($Attachments)){$Attachments = ""}
    
    if ((Test-Path $PasswordFileSendAs) -and (Test-Path $KeyFile)) 
    {
	    $KeyData = Get-Content $KeyFile
	    $SendAsCred = New-Object System.Management.Automation.PSCredential `
		    -ArgumentList $SendAsUser, (Get-Content $PasswordFileSendAs | ConvertTo-SecureString -Key $KeyData)

        if([system.string]::IsNullOrEmpty($CarbonCopy) -and [system.string]::IsNullOrEmpty($BlindCarbonCopy))
        {
            Send-MailMessage -From $From `
			         -To $Recipient `
                     -smtpserver $SmtpServer `
			         -Subject $Subject `
			         -Body $Mailbody `
                     -Attachments $Attachments `
			         -encoding ([System.Text.Encoding]::UTF8) `
			         -Port 587 -Credential $SendAsCred -UseSsl
        }
        elseif([system.string]::IsNullOrEmpty($BlindCarbonCopy))
        {
            Send-MailMessage -From $From `
			         -To $Recipient `
                     -Cc $CarbonCopy `
                     -smtpserver $SmtpServer `
			         -Subject $Subject `
			         -Body $Mailbody `
                     -Attachments $Attachments `
			         -encoding ([System.Text.Encoding]::UTF8) `
			         -Port 587 -Credential $SendAsCred -UseSsl
        }
        else
        {
            Send-MailMessage -From $From `
			         -To $Recipient `
                     -Cc $CarbonCopy `
                     -Bcc $BlindCarbonCopy `
                     -smtpserver $SmtpServer `
			         -Subject $Subject `
			         -Body $Mailbody `
                     -Attachments $Attachments `
			         -encoding ([System.Text.Encoding]::UTF8) `
			         -Port 587 -Credential $SendAsCred -UseSsl
        }
         
    }
    else
    {
        Write-LogFile -Status "FAIL" -Message "Mail Passwort Datei oder Key Datei nicht vorhanden!" -LogPath $global:logfilepath
    }  
}

$FunctionsToExport = "Send-Email"