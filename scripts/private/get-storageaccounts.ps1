

# Define the script's parameters
[CmdletBinding()]
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
$logFile = Join-Path -Path $logFolder2 -ChildPath "storageaccounts.txt"

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
$dataStorage | ForEach-Object { Add-Content -Path $logFile -Value $_ }

# Close connection
Disconnect-AzAccount | Out-Null
