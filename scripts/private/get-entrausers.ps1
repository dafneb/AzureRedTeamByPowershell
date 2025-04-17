<#
.SYNOPSIS
Retrieves all users and their custom security attributes from Microsoft Entra ID (Azure AD) and logs the information to a file.

.DESCRIPTION
This script connects to Microsoft Graph, retrieves all users in the specified domain, and logs their details, including custom security attributes, to a text file. 
The script ensures that necessary folders and files are created before logging the data. It also verifies the presence of the Microsoft Graph module and handles connection errors.

.PARAMETER Domain
Specifies the domain name for which the user data will be retrieved. This parameter is mandatory.

.EXAMPLE
.\get-entrausers.ps1 -Domain "contoso.com"
This example retrieves all users and their custom security attributes for the "contoso.com" domain and logs the information to a file.

.NOTES
- Ensure that the Microsoft Graph PowerShell module is installed before running the script.
- The script requires appropriate permissions to access user data in Microsoft Entra ID (Azure AD).
- The output is saved in a text file located in a domain-specific folder under the "case" directory.

#>

# Define the script's parameters
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Domain = "your-domain"
)

# Paths for logs
$basePath = Join-Path -Path (Get-Location) -ChildPath "case"
$logFolder = Join-Path -Path $basePath -ChildPath "$($Domain)"
$logFile = Join-Path -Path $logFolder -ChildPath "entrausers.txt"

# Create case folder if it doesn't exist
if (-not (Test-Path -Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
}
# Create domain folder if it doesn't exist
if (-not (Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}
# Create log file if it doesn't exist
if (-not (Test-Path -Path $logFile)) {
    New-Item -ItemType File -Path $logFile | Out-Null
} else {
    # Clear the log file if it already exists
    Clear-Content -Path $logFile
}

# Check if the module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft Graph module is not installed. Please install it using 'Install-Module Microsoft.Graph'."
    exit
}
# Import Microsoft Graph module
Import-Module Microsoft.Graph -ErrorAction Stop

# Connect to Microsoft Graph
Connect-MgGraph -NoWelcome #-Scopes "User.Read.All","Directory.Read.All","Group.Read.All"
# Check if the connection was successful
if ($null -eq (Get-MgUser)) {
    Write-Host "Failed to connect to Microsoft Graph. Please check your credentials and permissions."
    exit
}

# Get the list of all users in the organization
[string[]]$dataUsers = @()
$users = Get-MgUser -All
# Loop through each user and retrieve their custom security attributes
$users | ForEach-Object {
    $user = $_
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
$dataUsers | ForEach-Object { Add-Content -Path $logFile -Value $_ }

# Close connection
Disconnect-MgGraph | Out-Null
