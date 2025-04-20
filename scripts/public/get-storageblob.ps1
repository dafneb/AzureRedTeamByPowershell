<#
.SYNOPSIS
    Download blobs from Azure Storage Account.

.DESCRIPTION
    This script downloads blobs from an Azure Storage Account. It can download blobs with or without a version ID.
    The script can also read a CSV file containing the list of blobs to download.

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

.PARAMETER FilePath
    Specifies the path to a CSV file containing the list of blobs to download. This parameter is mandatory when using the 'File' parameter set.

.EXAMPLE
    ./get-storageblob.ps1 -CaseName "contoso.com" -StorageAccount "mystorageaccount" -Container "mycontainer" -Blob "myblob.txt"
    This example retrieves the specified blob from the Azure Storage Account and saves it to a local directory.

.NOTES
    Author: David Burel (@dafneb)
    Date: April 20, 2025
    Version: 1.0.0
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Blob')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName = "case-name",

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
    [string]$VersionId,

    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Download Blob *********************************"
Write-Output "*********** Author: David Burel (@dafneb) *****************"
Write-Output "***********************************************************"

Write-Verbose -Message "Checking requirements ..."

# Check if PowerShell version is 7.4 or higher
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Verbose -Message "PowerShell version is lower than 7.4, actual version is $($PSVersionTable.PSVersion) ..."
    Write-Error -Message "PowerShell version 7.4 or higher is required" -Category NotInstalled
    exit
}

# Normalize case name to lowercase
$caseFolderName = $CaseName.ToLower()
$caseFolderName = $caseFolderName.Trim()
$caseFolderName = $caseFolderName -replace '[\\/:*?"<>|]', '_'

# Paths for logs and case folders
$baseFolderPath = Join-Path -Path (Get-Location) -ChildPath "case"
$caseFolderPath = Join-Path -Path $baseFolderPath -ChildPath "$($caseFolderName)"

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

# Prepare list of blobs to download
$blobsToDownload = @()
switch ($PSCmdlet.ParameterSetName) {
    'Blob' {
        # Add blob to download list
        Write-Verbose -Message "Creating custom object for storage account and container amd blob from command line ..."
        $blobsToDownload += [PSCustomObject]@{
            StorageAccount = $StorageAccount
            Container      = $Container
            Blob           = $Blob
            VersionId      = $null
        }
    }
    'VersionId' {
        # Add blob with version ID to download list
        Write-Verbose -Message "Creating custom object for storage account and container and blob with version from command line ..."
        $blobsToDownload += [PSCustomObject]@{
            StorageAccount = $StorageAccount
            Container      = $Container
            Blob           = $Blob
            VersionId      = $VersionId
        }
    }
    'File' {
        # Read the CSV file and create a custom object for each row
        Write-Verbose -Message "Reading blobs from CSV file ..."
        if (Test-Path -Path $FilePath) {
            try {
                $import = Import-Csv -Path $FilePath
                $import | ForEach-Object {
                    $blobsToDownload += [PSCustomObject]@{
                        StorageAccount = $_.StorageAccount
                        Container      = $_.Container
                        Blob           = $_.BlobName
                        VersionId      = $_.VersionId
                    }
                }

            } catch {
                Write-Error -Message "Error reading CSV file: $($FilePath)" -Category InvalidOperation
                exit
            }

        } else {
            Write-Error -Message "File not found: $($FilePath)" -Category ObjectNotFound
            exit
        }
    }
}

# Let's download blobs ....
Write-Verbose -Message "Downloading blobs ..."
$blobsToDownload | ForEach-Object {
    $blobik = $_
    Write-Verbose -Message "Processing blob: $blobik"
    $endpoint = "https://$($blobik.StorageAccount).blob.core.windows.net/"
    Write-Verbose -Message "Endpoint: $($endpoint)"
    # URI builder for the blob storage
    try {
        $uriBuilderEndpoint = New-Object System.UriBuilder($endpoint)
    } catch {
        Write-Warning -Message "Error processing endpoint: $($endpoint)"
        continue
    }
    $storFolderPath = Join-Path -Path $caseFolderPath -ChildPath $uriBuilderEndpoint.Host
    # Create storage folder if it doesn't exist
    if (-not (Test-Path -Path $storFolderPath)) {
        Write-Verbose -Message "Storage folder does not exist, creating it..."
        New-Item -ItemType Directory -Path $storFolderPath | Out-Null
    }
    $contFolderPath = Join-Path -Path $storFolderPath -ChildPath $blobik.Container
    # Create container folder if it doesn't exist
    if (-not (Test-Path -Path $contFolderPath)) {
        Write-Verbose -Message "Container folder does not exist, creating it..."
        New-Item -ItemType Directory -Path $contFolderPath | Out-Null
    }
    $blobsFolderPath = Join-Path -Path $contFolderPath -ChildPath "blobs"
    # Create blob folder if it doesn't exist
    if (-not (Test-Path -Path $blobsFolderPath)) {
        Write-Verbose -Message "Blob folder does not exist, creating it..."
        New-Item -ItemType Directory -Path $blobsFolderPath | Out-Null
    }

    if ($blobik.VersionId) {
        # Download blob with version ID
        Write-Verbose -Message "Downloading blob with version ID: $($blobik.Blob)"
        $uriBuilderEndpoint.Path = "$($blobik.Container)/$($blobik.Blob)"
        $uriBuilderEndpoint.Query = "versionId=$($blobik.VersionId)"
        # Normalize case name to lowercase
        $versFolderName = $blobik.VersionId.ToLower()
        $versFolderName = $versFolderName.Trim()
        $versFolderName = $versFolderName -replace '[\\/:*?"<>|]', '_'
        $versFolderPath = Join-Path -Path $blobsFolderPath -ChildPath $versFolderName
        # Create version folder if it doesn't exist
        if (-not (Test-Path -Path $versFolderPath)) {
            Write-Verbose -Message "Version folder does not exist, creating it..."
            New-Item -ItemType Directory -Path $versFolderPath | Out-Null
        }
    } else {
        # Download blob without version ID
        Write-Verbose -Message "Downloading blob: $($blobik.Blob)"
        $uriBuilderEndpoint.Path = "$($blobik.Container)/$($blobik.Blob)"
        $versFolderPath = $blobsFolderPath
    }
    $fileOutputPath = Join-Path -Path $versFolderPath -ChildPath $blobik.Blob
    $requestHeadersVersion = @{
        "x-ms-version" = "2019-12-12";
        "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
        "Accept-Language" = "en-US,en;q=0.5";
    }
    # Download the blob
    try {
        Write-Verbose -Message "Uri: $($uriBuilderEndpoint.Uri)"
        Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeadersVersion -OutFile $fileOutputPath -UseBasicParsing
        Write-Verbose -Message "Blob downloaded: $($fileOutputPath)"
    } catch {
        Write-Warning -Message "Error downloading blob: $($blobik.Blob) from $($blobik.StorageAccount) in $($blobik.Container)"
        continue
    }

}

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
