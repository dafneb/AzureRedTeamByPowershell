<#
.SYNOPSIS
    This script retrieves information about all virtual machines in an Azure account and saves the details to a text file.

.DESCRIPTION
    The script connects to an Azure account, fetches the details of all virtual machines, and logs the information into a structured file for further analysis.
    It ensures necessary folders and files are created and verifies the presence of the required Azure PowerShell module.

.PARAMETER CaseName
    Specifies the case's name for which the user data will be retrieved. This parameter is mandatory.

.EXAMPLE    
    .\get-virtualmachines.ps1 -CaseName "contoso.com"
    This example retrieves all virtual machines for the "contoso.com" domain and logs the information to a text file.

.NOTES
    Ensure that the Microsoft Az PowerShell module is installed before running the script.
    The script requires appropriate permissions to access resource data in Azure.
    The output is saved in a text file located in a case-specific folder under the "case" directory.

    Author: David Burel (@dafneb)
    Date: April 18, 2025
    Version: 1.0.0
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = "Default")]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Default")]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName = "case-name"
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Virtual Machines ******************************"
Write-Output "*********** Author: David Burel (@dafneb) *****************"
Write-Output "***********************************************************"

Write-Verbose -Message "Checking requirements ..."

# Check if PowerShell version is 7.4 or higher
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Verbose -Message "PowerShell version is lower than 7.4, actual version is $($PSVersionTable.PSVersion) ..."
    Write-Output -ForegroundColor Red "PowerShell version 7.4 or higher is required"
    exit
}

# Check if module is already installed
if (-not (Get-Module -Name Az -ListAvailable)) {
    Write-Verbose -Message "Az module not found ..."
    Write-Output -ForegroundColor Red "Az module not found, please install it first"
    exit
}

# Check if Az module is loaded
if (-not (Get-Module -Name Az)) {
    Write-Verbose -Message "Loading Az module ..."
    Import-Module Az -ErrorAction Stop
}

# Normalize case name to lowercase
$caseFolderName = $CaseName.ToLower()
$caseFolderName = $caseFolderName.Trim()
$caseFolderName = $caseFolderName -replace '[\\/:*?"<>|]', '_'

# Paths for logs (1/2)
$baseFolderPath = Join-Path -Path (Get-Location) -ChildPath "case"
$caseFolderPath = Join-Path -Path $baseFolderPath -ChildPath "$($caseFolderName)"

Write-Verbose -Message "Checking folders (1/2) ..."

# Create case folder if it doesn't exist
if (-not (Test-Path -Path $baseFolderPath)) {
    Write-Verbose -Message "Base folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $baseFolderPath | Out-Null
}

# Create domain folder if it doesn't exist
if (-not (Test-Path -Path $caseFolderPath)) {
    Write-Verbose -Message "Case folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $caseFolderPath | Out-Null
}

# Connect to Azure
Write-Verbose -Message "Connecting to Azure ..."

Connect-AzAccount
# Check if the connection was successful
$azContext = Get-AzContext
if ($null -eq $azContext) {
    Write-Verbose -Message "Failed to connect to Azure ..."
    Write-Output -ForegroundColor Red "Failed to connect to Azure. Please check your credentials and permissions."
    exit
}

$azAccount = $azContext.Account.Id
# Normalize account name to lowercase
$accountFolderName = $azAccount.ToLower()
$accountFolderName = $accountFolderName.Trim()
$accountFolderName = $accountFolderName -replace '[\\/:*?"<>|]', '_'

# Paths for logs (2/2)
$accountFolderPath = Join-Path -Path $caseFolderPath -ChildPath "$($accountFolderName)"
$logFilePath = Join-Path -Path $accountFolderPath -ChildPath "virtualmachines.txt"

Write-Verbose -Message "Checking folders (2/2) ..."

# Create account folder if it doesn't exist
if (-not (Test-Path -Path $accountFolderPath)) {
    Write-Verbose -Message "Case folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $accountFolderPath | Out-Null
}

# Create log file if it doesn't exist
if (-not (Test-Path -Path $logFilePath)) {
    Write-Verbose -Message "File for logs does not exist, creating it..."
    New-Item -ItemType File -Path $logFilePath | Out-Null
} else {
    # Clear the log file if it already exists
    Clear-Content -Path $logFilePath
}

Write-Verbose -Message "Getting data from Azure ..."

# Get list of all virtual machines
$dataVMs = @()
$virtualMachines = Get-AzVM
$virtualMachines | ForEach-Object {
    $vmItem = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -UserData
    # Display the virtual machine details
    Write-Verbose -Message "Name: $($vmItem.Name)"
    $dataVMs += "Name: $($vmItem.Name); ResourceGroupName: $($vmItem.ResourceGroupName); Location: $($vmItem.Location)"
    # Get VM's OS type
    if ($vmItem.StorageProfile.OsDisk.OsType -eq "Windows") {
        $dataVMs += "`tOS: Windows"
    } else {
        $dataVMs += "`tOS: Linux"
    }
    # Get VM's Tags
    if ($vmItem.Tags.Count -gt 0) {
        $dataVMs += "`tTags:"
        $vmItem.Tags.GetEnumerator() | ForEach-Object {
            $dataVMs += "`t`t$($_.Key): $($_.Value)"
        }
    } else {
        $dataVMs += "`tTags: None"
    }
    # Get VM's User data
    if ($vmItem.UserData -ne $null) {
        # Decode the UserData property
        $userData = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($vmItem.UserData))
        $dataVMs += "`tUserData:"
        $dataVMs += "$($userData)"
    }
}
$dataVMs | ForEach-Object { Add-Content -Path $logFilePath -Value $_ }

# Close connection
Disconnect-AzAccount | Out-Null

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
