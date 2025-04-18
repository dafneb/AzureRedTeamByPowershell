<#
.SYNOPSIS
    This script retrieves all visible resources in the Azure subscription and exports their details to a CSV file.

.DESCRIPTION
    The script connects to Azure, retrieves all visible resources, and logs their details, including resource name, type, group name, location, ID, and tags, to a CSV file.

.PARAMETER CaseName
    Specifies the case's name for which the user data will be retrieved. This parameter is mandatory.

.EXAMPLE
    .\get-visibleresources.ps1 -CaseName "contoso.com"
    This example retrieves all visible resources for the "contoso.com" case and logs the information to a CSV file.

.NOTES
    Ensure that the Microsoft Az PowerShell module is installed before running the script.
    The script requires appropriate permissions to access resource data in Azure.
    The output is saved in a CSV file located in a case-specific folder under the "case" directory.

    Author: David Burel (@dafneb)
    Date: April 17, 2025
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
Write-Output "*********** Visible Resources *****************************"
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
$logFilePath = Join-Path -Path $accountFolderPath -ChildPath "resources.csv"

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

# Get list of all visible resources
$dataResources = @()
$resources = Get-AzResource -ApiVersion '2024-11-01'
$resources | ForEach-Object {
    $resource = $_
    Write-Verbose -Message "Name: $($resource.Name); ResourceType: $($resource.ResourceType)"
    $dataResources += [PSCustomObject]@{
        ResourceName = "$($resource.Name)";
        ResourceType = "$($resource.ResourceType)";
        ResourceGroupName = "$($resource.ResourceGroupName)";
        Location = "$($resource.Location)";
        ResourceId = "$($resource.ResourceId)"
        Tags = "$($resource.Tags | Out-String)"
    }
}
# Export the resource details to a CSV file
$dataResources | Export-Csv -Path $logFilePath -NoTypeInformation

# Close connection
Disconnect-AzAccount | Out-Null

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
