<#
.SYNOPSIS
    Download a blob from Azure Storage Account

.DESCRIPTION
    This script connects to Azure, retrieves a specified blob from a given storage account and container, and saves it to a local directory.
    The script supports downloading blobs by name or by version ID.

.PARAMETER CaseName
    Specifies the case's name for which the user data will be retrieved. This parameter is mandatory.

.PARAMETER StorageAccount
    Specifies the name of the Azure Storage Account. This parameter is mandatory.

.PARAMETER Container
    Specifies the name of the Azure Storage Container. This parameter is mandatory.

.PARAMETER Blob
    Specifies the name of the blob to be downloaded. This parameter is mandatory.

.PARAMETER VersionId
    Specifies the version ID of the blob to be downloaded. This parameter is mandatory when using the 'VersionId' parameter set.

.EXAMPLE
    .\get-storageblob.ps1 -CaseName "contoso.com" -StorageAccount "mystorageaccount" -Container "mycontainer" -Blob "myblob.txt"
    This example retrieves the specified blob from the Azure Storage Account and saves it to a local directory.

.NOTES
    Ensure that the Az PowerShell module is installed before running the script.
    The script requires appropriate permissions to access resource data in Azure.
    The output is saved in a file located in a case-specific folder under the "case" directory.

    Author: David Burel (@dafneb)
    Date: April 17, 2025
    Version: 1.0.0
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Blob')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccount,

    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$Container,

    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$Blob,

    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$VersionId
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Downloading blobs *****************************"
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

# Paths for logs
$baseFolderPath = Join-Path -Path (Get-Location) -ChildPath "case"
$caseFolderPath = Join-Path -Path $baseFolderPath -ChildPath "$($caseFolderName)"
$blobFolderPath = Join-Path -Path $caseFolderPath -ChildPath "blobs"

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

# Create blob folder if it doesn't exist
if (-not (Test-Path -Path $blobFolderPath)) {
    Write-Verbose -Message "Blob folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $blobFolderPath | Out-Null
}

# Connect to Azure
Write-Verbose -Message "Connecting to Azure ..."
Write-Verbose -Message "ParameterSetName: $($PSCmdlet.ParameterSetName)"

Connect-AzAccount
# Check if the connection was successful
$azContext = Get-AzContext
if ($null -eq $azContext) {
    Write-Verbose -Message "Failed to connect to Azure ..."
    Write-Error -Message "Failed to connect to Azure. Please check your credentials and permissions." -Category ConnectionError
    exit
}

Write-Verbose -Message "Getting blobs from Azure ..."
Write-Verbose -Message "ParameterSetName: $($PSCmdlet.ParameterSetName)"

switch($PSCmdlet.ParameterSetName) {
    'Blob' {
        # Get storage account context
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccount -UseConnectedAccount

        if ($null -eq $storageContext) {
            Write-Error -Message "Storage context not found. Please check the storage account name." -Category ObjectNotFound
            exit
        }

        # Get the blob's context from the specified container
        $blobik = Get-AzStorageBlob -Container $Container -Context $storageContext -Blob $Blob -ErrorAction SilentlyContinue

        if ($null -eq $blobik) {
            Write-Error -Message "Blob not found. Please check the blob name and container." -Category ObjectNotFound
            exit
        }

        $blobPath = Join-Path -Path $blobFolderPath -ChildPath $blobik.Name
        $blobik | Get-AzStorageBlobContent -Destination $blobPath -Force | Out-Null

        # Check if the blob was downloaded successfully
        if (Test-Path -Path $blobPath) {
            Write-Output "Blob downloaded successfully to $blobPath"
        } else {
            Write-Error -Message "Failed to download the blob."
        }
    }

    'VersionId' {
        # Get storage account context
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccount -UseConnectedAccount

        if ($null -eq $storageContext) {
            Write-Error -Message "Storage context not found. Please check the storage account name." -Category ObjectNotFound
            exit
        }

        # Get the blob's context from the specified container
        $blobik = Get-AzStorageBlob -Container $Container -Context $storageContext -Blob $Blob -VersionId $VersionId

        if ($null -eq $blobik) {
            Write-Error -Message "Blob not found. Please check the blob name, version id and container." -Category ObjectNotFound
            exit
        }

        $blobPath = Join-Path -Path $blobFolderPath -ChildPath $blobik.Name
        $blobik | Get-AzStorageBlobContent -Destination $blobPath -Force | Out-Null

        # Check if the blob was downloaded successfully
        if (Test-Path -Path $blobPath) {
            Write-Output "Blob downloaded successfully to $blobPath"
        } else {
            Write-Error -Message "Failed to download the blob."
        }
    }
}

# Close connection
Disconnect-AzAccount | Out-Null

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
