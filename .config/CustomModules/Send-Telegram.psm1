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
$($Hostname) $($Status_Icon)
-----------------------------
--- $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") ---
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

$FunctionsToExport = "Send-Telegram"