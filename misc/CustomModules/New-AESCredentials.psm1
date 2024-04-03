#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     New-AESCredentials.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################
function New-AEScredentials()
{

    Param(
        [Parameter(Mandatory=$true,Position=1)][string]$CredentialName,
        [Parameter(Mandatory=$false,Position=2)][string]$OutputPath
    )

    # Enter Key Name
    $CredNames = $CredentialName

    # Check if Folder Exists
    if([system.string]::IsNullOrEmpty($OutputPath))
    {
        $KeyPath = "$env:USERPROFILE\Desktop\$($CredNames)_Creds"
    }
    else
    {
        $KeyPath = "$OutputPath\$($CredNames)_Creds"
    }

    if(-not (Test-Path $KeyPath))
    {
        mkdir $KeyPath | Out-Null
    }

    try
    {
        # Prompt you to enter the username and password
        $credObject = Get-Credential
        # The credObject now holds the password in a "securestring" format
        $passwordSecureString = $credObject.password

        # Define a location to store the AESKey
        $AESKeyFilePath = "$KeyPath\$CredNames" + "_aes.key"
        # Define a location to store the file that hosts the encrypted password
        $credentialFilePath = "$KeyPath\$CredNames" + "_Password.txt"

        # Generate a random AES Encryption Key.
        $AESKey = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)

        # Store the AESKey into a file. This file should be protected! (e.g. ACL on the file to allow only select people to read)
        Set-Content $AESKeyFilePath $AESKey # Any existing AES Key file will be overwritten
        $password = $passwordSecureString | ConvertFrom-SecureString -Key $AESKey
        Add-Content $credentialFilePath $password
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        write-host $ErrorMessage
    }

    if((Test-Path $KeyPath))
    {
        Write-Host "Die Dateien liegen unter: "$KeyPath -BackgroundColor Green -ForegroundColor White
        Start-Process $KeyPath
    }

}

function Restore-AEScredentials()
{
    Param(
        [Parameter(Mandatory=$false,Position=0)][string]$KeyFilePath,
        [Parameter(Mandatory=$false,Position=1)][string]$PasswordFilePath
    )    

    try
    {
        $aes = Get-Content $KeyFilePath
        $pass = Get-Content $PasswordFilePath | ConvertTo-SecureString -Key $aes
        $ClearText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($($pass)));
        return "Your Secure AES Password is: $($ClearText)"
    }
    catch
    {
        $FailMessage = $Error[0].Exception.Message
        Write-Warning "An Error Ocurred: $($FailMessage)"
    }
}

$FunctionsToExport = "New-AEScredentioals", `
                     "Restore-AEScredentioals"