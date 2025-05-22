<#
.SYNOPSIS
    This script retrieves and displays all role assignments in an Azure environment, saving the results to a CSV file.

.DESCRIPTION
    The script connects to an Azure account, fetches the role assignments, and logs the details into a structured file for further analysis.
    It ensures necessary folders and files are created and verifies the presence of the required Azure PowerShell module.

.PARAMETER CaseName
    Specifies the case's name for which the user data will be retrieved. This parameter is mandatory.

.EXAMPLE
    .\get-rolesassignment.ps1 -CaseName "contoso.com"
    This example retrieves all roles assigned to users and groups for the "contoso.com" domain and logs the information to a CSV file.

.NOTES
    Ensure that the Microsoft Az PowerShell module is installed before running the script.
    The script requires appropriate permissions to access resource data in Azure.
    The output is saved in a text file located in a case-specific folder under the "case" directory.

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
Write-Output "*********** Role's Assignment *****************************"
Write-Output "*********** Author: David Burel (@dafneb) *****************"
Write-Output "***********************************************************"

Write-Verbose -Message "Checking requirements ..."

# Check if PowerShell version is 7.4 or higher
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Verbose -Message "PowerShell version is lower than 7.4, actual version is $($PSVersionTable.PSVersion) ..."
    Write-Error -Message "PowerShell version 7.4 or higher is required" -Category NotInstalled
    exit
}

# Check if module is already installed
if (-not (Get-Module -Name Az -ListAvailable)) {
    Write-Verbose -Message "Az module not found ..."
    Write-Error -Message "Az module not found, please install it first" -Category NotInstalled
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
    Write-Error -Message "Failed to connect to Azure. Please check your credentials and permissions." -Category ConnectionError
    exit
}

$azAccount = $azContext.Account.Id
# Normalize account name to lowercase
$accountFolderName = $azAccount.ToLower()
$accountFolderName = $accountFolderName.Trim()
$accountFolderName = $accountFolderName -replace '[\\/:*?"<>|]', '_'

# Paths for logs (2/2)
$accountFolderPath = Join-Path -Path $caseFolderPath -ChildPath "$($accountFolderName)"
$logFilePath = Join-Path -Path $accountFolderPath -ChildPath "rolesassignment.csv"

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

# Get list of all assigned roles
$dataRoles = @()
$roles = Get-AzRoleAssignment
$roles | ForEach-Object {
    $roleItem = $_
    Write-Verbose -Message "DisplayName: $($roleItem.DisplayName); RoleDefinitionName: $($roleItem.RoleDefinitionName)"
    # Display the role assignment details
    $dataRoles += [PSCustomObject]@{
        RoleName = "$($roleItem.RoleDefinitionName)";
        PrincipalName = "$($roleItem.DisplayName)";
        PrincipalType = "$($roleItem.ObjectType)";
        PrincipalId = "$($roleItem.ObjectId)";
        Scope = "$($roleItem.Scope)"
    }
}
# Export the role assignment details to a CSV file
Write-Verbose -Message "Saving data ..."
$dataRoles | Export-Csv -Path $logFilePath -NoTypeInformation

# Close connection
Disconnect-AzAccount | Out-Null

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
