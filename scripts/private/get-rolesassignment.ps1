<#
.SYNOPSIS
This script retrieves and displays all role assignments in an Azure environment, saving the results to a CSV file.

.DESCRIPTION
The script connects to an Azure account, fetches the role assignments, and logs the details into a structured file for further analysis.
It ensures necessary folders and files are created and verifies the presence of the required Azure PowerShell module.

.PARAMETER Domain
Specifies the domain name to be used for organizing log files. This parameter is mandatory.

.EXAMPLE
.\get-rolesassignment.ps1 -Domain "contoso.com"
This example retrieves all roles assigned to users and groups for the "contoso.com" domain and logs the information to a CSV file.

.NOTES
- Ensure that the Microsoft Az PowerShell module is installed before running the script.
- The script requires appropriate permissions to access user data in Microsoft Entra ID (Azure AD).
- The output is saved in a text file located in a domain-specific folder under the "case" directory.

#>

# Define the script's parameters
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Domain = "your-domain"
)

# Paths for logs
$basePath = Join-Path -Path (Get-Location) -ChildPath "case"
$logFolder = Join-Path -Path $basePath -ChildPath $Domain

# Create case folder if it doesn't exist
if (-not (Test-Path -Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
}
# Create domain folder if it doesn't exist
if (-not (Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

# Check if the module is installed
if (-not (Get-Module -ListAvailable -Name Az)) {
    Write-Host "Azure module is not installed. Please install it using 'Install-Module Az'."
    exit
}
# Import Azure module
Import-Module Az -ErrorAction Stop

# Connect to Azure
Connect-AzAccount
# Check if the connection was successful
if ($null -eq (Get-AzContext)) {
    Write-Host "Failed to connect to Azure. Please check your credentials and permissions."
    exit
}

$azContext = Get-AzContext

$logFolder2 = Join-Path -Path $logFolder -ChildPath "$($azContext.Account)"
$logFile = Join-Path -Path $logFolder2 -ChildPath "rolesassignment.csv"

# Create entity folder if it doesn't exist
if (-not (Test-Path -Path $logFolder2)) {
    New-Item -ItemType Directory -Path $logFolder2 | Out-Null
}
# Create log file if it doesn't exist
if (-not (Test-Path -Path $logFile)) {
    New-Item -ItemType File -Path $logFile | Out-Null
}
else {
    # Clear the log file if it already exists
    Clear-Content -Path $logFile
}

# Get list of all assigned roles
$dataRoles = @()
$roles = Get-AzRoleAssignment
$roles | ForEach-Object {
    $roleItem = $_
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
$dataRoles | Export-Csv -Path $logFile -NoTypeInformation

# Close connection
Disconnect-AzAccount | Out-Null
