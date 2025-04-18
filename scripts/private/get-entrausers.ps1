<#
.SYNOPSIS
    Retrieves all users and their custom security attributes from Microsoft Entra ID (Azure AD) and logs the information to a file.

.DESCRIPTION
    This script connects to Microsoft Graph, retrieves all users in the specified domain, and logs their details, including custom security attributes, to a text file. 
    The script ensures that necessary folders and files are created before logging the data. It also verifies the presence of the Microsoft Graph module and handles connection errors.

.PARAMETER CaseName
    Specifies the case's name for which the user data will be retrieved. This parameter is mandatory.

.EXAMPLE
    .\get-entrausers.ps1 -CaseName "contoso.com"
    This example retrieves all users and their custom security attributes for the "contoso.com" domain and logs the information to a file.

.NOTES
    Ensure that the Microsoft Graph PowerShell module is installed before running the script.
    The script requires appropriate permissions to access user data in Microsoft Entra ID (Azure AD).
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
Write-Output "*********** Users at Entra Id *****************************"
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
if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
    Write-Verbose -Message "Microsoft.Graph module not found ..."
    Write-Output -ForegroundColor Red "Microsoft.Graph module not found, please install it first"
    exit
}

# Check if Microsoft.Graph module is loaded
if (-not (Get-Module -Name Microsoft.Graph)) {
    Write-Verbose "Loading Microsoft.Graph module ..."
    Import-Module Microsoft.Graph -ErrorAction Stop
}

# Normalize case name to lowercase
$caseFolderName = $CaseName.ToLower()
$caseFolderName = $caseFolderName.Trim()
$caseFolderName = $caseFolderName -replace '[\\/:*?"<>|]', '_'

# Paths for logs
$baseFolderPath = Join-Path -Path (Get-Location) -ChildPath "case"
$caseFolderPath = Join-Path -Path $baseFolderPath -ChildPath "$($caseFolderName)"
$logFilePath = Join-Path -Path $caseFolderPath -ChildPath "entrausers.txt"

Write-Verbose -Message "Checking folders ..."

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

# Create log file if it doesn't exist
if (-not (Test-Path -Path $logFilePath)) {
    Write-Verbose -Message "File for logs does not exist, creating it..."
    New-Item -ItemType File -Path $logFilePath | Out-Null
} else {
    # Clear the log file if it already exists
    Clear-Content -Path $logFilePath
}

# Connect to Microsoft Graph
Write-Verbose -Message "Connecting to Microsoft Graph ..."

Connect-MgGraph -NoWelcome
# Check if the connection was successful
if ($null -eq (Get-MgUser)) {
    Write-Verbose -Message "Connection to Microsoft Graph failed!"
    Write-Output -ForegroundColor Red "Failed to connect to Microsoft Graph. Please check your credentials and permissions."
    exit
}

Write-Verbose -Message "Getting data from Entra ID ..."

# Get the list of all users in the organization
[string[]]$dataUsers = @()
$users = Get-MgUser -All
# Loop through each user and retrieve their custom security attributes
$users | ForEach-Object {
    $user = $_
    Write-Verbose -Message "DisplayName: $($user.DisplayName)"
    $dataUsers += "ID: $($user.ID); DisplayName: $($user.DisplayName); UserPrincipalName: $($user.UserPrincipalName)"

    # Retrieve the custom security attributes for the user
    $customAttributes = Get-MgUser -UserId $user.Id -Property "customSecurityAttributes"
    if ($customAttributes.CustomSecurityAttributes.AdditionalProperties.Count -gt 0) {
        $customAttributes.CustomSecurityAttributes.AdditionalProperties.Keys | ForEach-Object {
            $key = $_
            $value = $customAttributes.CustomSecurityAttributes.AdditionalProperties.$($key) | Out-String
            # Append the custom attribute to the user information
            $dataUsers += "`t$($key): $($value)"
        }
    }
}

Write-Verbose -Message "Saving data ..."
$dataUsers | ForEach-Object { Add-Content -Path $logFilePath -Value $_ }

# Close connection
Disconnect-MgGraph | Out-Null

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
