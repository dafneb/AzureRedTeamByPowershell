<#
.SYNOPSIS
    This script retrieves detailed information about all Azure Storage Accounts in the current subscription.

.DESCRIPTION
    This script retrieves detailed information about all Azure Storage Accounts in the current subscription.
    It includes properties, network rules, services properties, containers, shares, queues, and tables.

.PARAMETER CaseName
    Specifies the case's name for which the user data will be retrieved. This parameter is mandatory.

.EXAMPLE
    .\get-storageaccounts.ps1 -CaseName "contoso.com"
    This example retrieves all storage accounts for the "contoso.com" domain and logs the information to a text file.

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
Write-Output "*********** Storage Accounts ******************************"
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
$logFilePath = Join-Path -Path $accountFolderPath -ChildPath "storageaccounts.txt"

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

$dataStorage = @()
$storages = Get-AzStorageAccount
$storages | ForEach-Object {
    $storageItem = $_
    $storageContext = New-AzStorageContext -StorageAccountName $storageItem.StorageAccountName -UseConnectedAccount
    $dataStorage += "Name: $($storageItem.StorageAccountName); Location: $($storageItem.Location); SKU: $($storageItem.Sku.Name); Kind: $($storageItem.Kind); Status: $($storageItem.ProvisioningState)"
    $dataStorage += "`tAccessTier: $($storageItem.AccessTier)"
    # Get storages's Tags
    if ($storageItem.Tags.Count -gt 0) {
        $dataStorage += "`tTags:"
        $storageItem.Tags.GetEnumerator() | ForEach-Object {
            $dataStorage += "`t`t$($_.Key): $($_.Value)"
        }
    } else {
        $dataStorage += "`tTags: None"
    }
    # Get storages's Properties
    $dataStorage += "`tDnsEndpointType: $($storageItem.DnsEndpointType)"
    $dataStorage += "`tCustomDomain: $($storageItem.CustomDomain)"
    $dataStorage += "`tRoutingPreference: $($storageItem.RoutingPreference)"
    $dataStorage += "`tPrimaryEndpoints:"
    $dataStorage += "`t`tBlob: $($storageItem.PrimaryEndpoints.Blob)"
    $dataStorage += "`t`tQueue: $($storageItem.PrimaryEndpoints.Queue)"
    $dataStorage += "`t`tTable: $($storageItem.PrimaryEndpoints.Table)"
    $dataStorage += "`t`tFile: $($storageItem.PrimaryEndpoints.File)"
    $dataStorage += "`tMinimumTlsVersion: $($storageItem.MinimumTlsVersion)"
    $dataStorage += "`tPublicNetworkAccess: $($storageItem.PublicNetworkAccess)"
    $dataStorage += "`tAllowBlobPublicAccess: $($storageItem.AllowBlobPublicAccess)"
    $dataStorage += "`tAllowSharedKeyAccess: $($storageItem.AllowSharedKeyAccess)"
    $dataStorage += "`tAllowCrossTenantReplication: $($storageItem.AllowCrossTenantReplication)"
    $dataStorage += "`tEnableHttpsTrafficOnly: $($storageItem.EnableHttpsTrafficOnly)"
    $dataStorage += "`tEnableHierarchicalNamespace: $($storageItem.EnableHierarchicalNamespace)"
    $dataStorage += "`tEnableNfsV3: $($storageItem.EnableNfsV3)"
    $dataStorage += "`tEnableSftp: $($storageItem.EnableSftp)"
    $dataStorage += "`tEnableLocalUser: $($storageItem.EnableLocalUser)"
    $dataStorage += "`tImmutableStorageWithVersioning: $($storageItem.ImmutableStorageWithVersioning)"
    $dataStorage += "`tEncryption.KeySource: $($storageItem.Encryption.KeySource)"
    $dataStorage += "`tEncryption.RequireInfrastructureEncryption: $($storageItem.Encryption.RequireInfrastructureEncryption)"
    # Get storage's network rules
    $dataStorage += "`tNetworkRuleSet:"
    $dataStorage += "`t`tBypass: $($storageItem.NetworkRuleSet.Bypass)"
    $dataStorage += "`t`tDefaultAction: $($storageItem.NetworkRuleSet.DefaultAction)"
    $dataStorage += "`t`tvNet Rules:"
    $storageItem.NetworkRuleSet.VirtualNetworkRules | ForEach-Object {
        $rule = $_
        $dataStorage += "`t`t`t[$($rule.State)] $($rule.Action): $($rule.VirtualNetworkResourceId)"
    }
    $dataStorage += "`t`tIP Rules:"
    $storageItem.NetworkRuleSet.IpRules | ForEach-Object {
        $rule = $_
        $dataStorage += "`t`t`t$($rule.Action): $($rule.IPAddressOrRange)"
    }
    $dataStorage += "`t`tResource Rules:"
    $storageItem.NetworkRuleSet.ResourceAccessRules | ForEach-Object {
        $rule = $_
        $dataStorage += "`t`t`t$($rule.ResourceId) (Tenant: $($rule.TenantId))"
    }
    # Get storage's services properties
    # BlobServiceProperties
    $dataStorage += "`tBlobServiceProperties:"
    $blobServiceProperties = Get-AzStorageBlobServiceProperty -StorageAccountName $storageItem.StorageAccountName -ResourceGroupName $storageItem.ResourceGroupName
    $dataStorage += "`t`tDefaultServiceVersion: $($blobServiceProperties.DefaultServiceVersion)"
    $dataStorage += "`t`tDeleteRetentionPolicy:"
    $dataStorage += "`t`t`tEnabled: $($blobServiceProperties.DeleteRetentionPolicy.Enabled)"
    $dataStorage += "`t`t`tDays: $($blobServiceProperties.DeleteRetentionPolicy.Days)"
    $dataStorage += "`t`tCorsRules:"
    $blobServiceProperties.Cors.CorsRulesProperty | ForEach-Object {
        $corsRuleItem = $_
        $dataStorage += "`t`t`tAllowedOrigins: $($corsRuleItem.AllowedOrigins)"
        $dataStorage += "`t`t`tAllowedMethods: $($corsRuleItem.AllowedMethods)"
        $dataStorage += "`t`t`tMaxAgeInSeconds: $($corsRuleItem.MaxAgeInSeconds)"
        $dataStorage += "`t`t`tExposedHeaders: $($corsRuleItem.ExposedHeaders)"
        $dataStorage += "`t`t`tAllowedHeaders: $($corsRuleItem.AllowedHeaders)"
    }
    # FileServiceProperty
    $fileShareServiceProperties = Get-AzStorageFileServiceProperty -StorageAccountName $storageItem.StorageAccountName -ResourceGroupName $storageItem.ResourceGroupName
    $dataStorage += "`tFileShareServiceProperties:"
    $dataStorage += "`t`tShareDeleteRetentionPolicy:"
    $dataStorage += "`t`t`tEnabled: $($fileShareServiceProperties.ShareDeleteRetentionPolicy.Enabled)"
    $dataStorage += "`t`t`tDays: $($fileShareServiceProperties.ShareDeleteRetentionPolicy.Days)"
    $dataStorage += "`t`tProtocolSettings:"
    $dataStorage += "`t`t`tSMB:"
    $dataStorage += "`t`t`t`tMultichannel: $($fileShareServiceProperties.ProtocolSettings.Smb.Multichannel.Enabled)"
    $dataStorage += "`t`t`t`tVersions: $($fileShareServiceProperties.ProtocolSettings.Smb.Versions | Out-String)"
    $dataStorage += "`t`t`t`tAuthenticationMethods: $($fileShareServiceProperties.ProtocolSettings.Smb.AuthenticationMethods | Out-String)"
    $dataStorage += "`t`t`t`tKerberosTicketEncryption: $($fileShareServiceProperties.ProtocolSettings.Smb.KerberosTicketEncryption | Out-String)"
    $dataStorage += "`t`t`t`tChannelEncryption: $($fileShareServiceProperties.ProtocolSettings.Smb.ChannelEncryption | Out-String)"
    # Get storage's Containers
    $dataStorage += "`tStorageContainers:"
    $containers = Get-AzStorageContainer -Context $storageContext
    $containers | ForEach-Object {
        $containerItem = $_
        $dataStorage += "`t`tName: $($containerItem.Name)"
        $dataStorage += "`t`t`tPublicAccess: $($containerItem.PublicAccess)"
        $dataStorage += "`t`t`tLastModified: $($containerItem.LastModified)"
        $dataStorage += "`t`t`tHasImmutabilityPolicy: $($containerItem.HasImmutabilityPolicy)"
        $dataStorage += "`t`t`tHasLegalHold: $($containerItem.HasLegalHold)"
        # Get container's Blobs
        $dataStorage += "`t`t`tBlobs:"
        $blobs = Get-AzStorageBlob -Container $containerItem.Name -Context $storageContext -IncludeVersion
        $blobs | ForEach-Object {
            $blobItem = $_
            $dataStorage += "`t`t`t`tName: $($blobItem.Name)"
            $dataStorage += "`t`t`t`t`tVersionId: $($blobItem.VersionId)"
            $dataStorage += "`t`t`t`t`tBlobType: $($blobItem.BlobType)"
            $dataStorage += "`t`t`t`t`tLastModified: $($blobItem.LastModified)"
            $dataStorage += "`t`t`t`t`tLength: $($blobItem.Length)"
        }
    }
    # Get storage's File Shares
    $dataStorage += "`tStorageShares:"
    $shares = Get-AzStorageShare -Context $storageContext
    $shares | ForEach-Object {
        $shareItem = $_
        $dataStorage += "`t`tName: $($shareItem.Name)"
        $dataStorage += "`t`t`tLastModified: $($shareItem.LastModified)"
        $dataStorage += "`t`t`tQuota: $($shareItem.Quota)"
        # Get share's Files
        $dataStorage += "`t`t`tFiles:"
        $files = Get-AzStorageFile -ShareName $shareItem.Name -Context $storageContext
        $files | ForEach-Object {
            $fileItem = $_
            $dataStorage += "`t`t`t`tName: $($fileItem.Name)"
            $dataStorage += "`t`t`t`t`tLastModified: $($fileItem.LastModified)"
            $dataStorage += "`t`t`t`t`tLength: $($fileItem.Length)"
        }
    }
    # Get storage's Queues
    $dataStorage += "`tStorageQueues:"
    $queues = Get-AzStorageQueue -Context $storageContext
    $queues | ForEach-Object {
        $queueItem = $_
        $dataStorage += "`t`tName: $($queueItem.Name)"
        $dataStorage += "`t`t`tUri: $($queueItem.Uri)"
        $dataStorage += "`t`t`tApproximateMessageCount: $($queueItem.ApproximateMessageCount)"
    }
    # Get storage's Tables
    $dataStorage += "`tStorageTables:"
    $tables = Get-AzStorageTable -Context $storageContext
    $tables | ForEach-Object {
        $tableItem = $_
        $dataStorage += "`t`tName: $($tableItem.Name)"
        $dataStorage += "`t`t`tUri: $($tableItem.Uri)"
    }
}
# Export the storage account details to a text file
Write-Verbose -Message "Saving data ..."
$dataStorage | ForEach-Object { Add-Content -Path $logFilePath -Value $_ }

# Close connection
Disconnect-AzAccount | Out-Null

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
