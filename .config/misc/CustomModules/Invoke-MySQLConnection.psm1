#    ___                  ____  _
#   /   | ___  ____ ___  / __ \(_)
#  / /| |/ _ \/ __ `__ \/ /_/ / /
# / ___ /  __/ / / / / / ____/ /
#/_/  |_\___/_/ /_/ /_/_/   /_/
#
# Filename:     Invoke-MySQLConnection.psm1
# Github:       https://github.com/AemPi/My_Powershell_Profile
# Maintainer:   Markus Pröpper (AemPi)
#########################################################
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


$FunctionsToExport = "Connect-MySQL", `
                     "Invoke-MySQLQuery", `
                     "Disconnect-MySQL"