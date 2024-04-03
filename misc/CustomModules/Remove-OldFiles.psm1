#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     Remove-OldFiles.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################
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

$FunctionsToExport = "Remove-OldFiles"