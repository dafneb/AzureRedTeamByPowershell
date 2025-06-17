<#
.SYNOPSIS
    This script retrieves all visible resources in the Azure subscription
    and exports their details to a CSV file.

.DESCRIPTION
    The script connects to Azure, retrieves all visible resources, and logs
    their details, including resource name, type, group name, location, ID,
    and tags, to a CSV file.

    Script will try if connection to Azure is successful, and if not, it will
    try to connect.

    After that, it will try find all visible resources in all tenants and
    subscriptions the user has access to, and will log the information to
    a CSV file.

.PARAMETER CaseName
    Specifies the case's name for which the user data will be retrieved.
    This parameter is mandatory.

.EXAMPLE
    ./get-visibleresources.ps1 -CaseName "MyCase"
    This example retrieves all visible resources for the "MyCase"
    case and logs the information to a CSV file.

.NOTES
    Ensure that the Microsoft Az PowerShell module is installed before
    running the script.
    The script requires appropriate permissions to access resource data
    in Azure.
    The output is saved in a CSV file located in a case-specific folder
    under the "case" directory.

    Author: David Burel (@dafneb)
    Date: June 16, 2025
    Version: 1.1.0
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = "Default")]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Default")]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName
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
$logFilePath = Join-Path -Path $accountFolderPath -ChildPath "resources.csv"
$domainFilePath = Join-Path -Path $accountFolderPath -ChildPath "domains.txt"

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
$dataDomains = @()

$tenants = Get-AzTenant -ErrorAction SilentlyContinue
if (-not $tenants) {
    Write-Warning -Message "No tenants found, please check your connection"
}
$tenants | ForEach-Object {
    $tenant = $_
    Write-Output "Tenant ID: $($tenant.Id); Tenant Name: $($tenant.Name)"
    $tenant.Domains | ForEach-Object {
        $dataDomains += $_
    }

    # Get all subscriptions for the tenant
    $subscriptions = Get-AzSubscription -TenantId $tenant.Id -ErrorAction SilentlyContinue
    if (-not $subscriptions) {
        Write-Warning -Message "No subscriptions found for tenant $($tenant.Name) ($($tenant.Id))"
    }
    $subscriptions | ForEach-Object {
        $subscription = $_
        Write-Output "Subscription ID: $($subscription.Id); Subscription Name: $($subscription.Name)"

        # Skip if the subscription is disabled
        if ($subscription.State -eq "Disabled") {
            Write-Warning -Message "Subscription $($subscription.Name) ($($subscription.Id)) is Disabled, skipping ..."
            return
        }
        Set-AzContext -SubscriptionId $subscription.Id -TenantId $tenant.Id | Out-Null
        if (-not (Get-AzContext)) {
            Write-Warning -Message "Failed to set context for subscription $($subscription.Name) ($($subscription.Id))"
            return
        }

        $resources = Get-AzResource -ApiVersion '2024-11-01'
        $resources | ForEach-Object {
            $resource = $_
            Write-Output "Name: $($resource.Name); ResourceType: $($resource.ResourceType)"
            $dataResources += [PSCustomObject]@{
                TenantId = "$($tenant.Id)";
                TenantName = "$($tenant.Name)";
                SubscriptionId = "$($subscription.Id)";
                SubscriptionName = "$($subscription.Name)";
                SubscriptionState = "$($subscription.State)";
                ResourceId = "$($resource.Id)";
                ResourceName = "$($resource.Name)";
                ResourceType = "$($resource.ResourceType)";
                ResourceGroupName = "$($resource.ResourceGroupName)";
                Location = "$($resource.Location)";
                Tags = "$($resource.Tags | Out-String)"
            }
        }

    }
}

# Export the resource details to a CSV file
$dataResources | Export-Csv -Path $logFilePath -NoTypeInformation -Encoding UTF8
$dataDomains | Out-File -Path $domainFilePath -Encoding UTF8

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
