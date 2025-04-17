

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Blob')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccount = "storage-account",

    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$Container = "container-name",

    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$Blob = "blob-name",

    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$VersionId = "version-id"
)

# Paths for logs
$basePath = Join-Path -Path (Get-Location) -ChildPath "case"
$storageFolder = Join-Path -Path $basePath -ChildPath $StorageAccount
$containerFolder = Join-Path -Path $storageFolder -ChildPath $Container
$blobFolder = Join-Path -Path $containerFolder -ChildPath "blobs"

# Create case folder if it doesn't exist
if (-not (Test-Path -Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
}
# Create storage folder if it doesn't exist
if (-not (Test-Path -Path $storageFolder)) {
    New-Item -ItemType Directory -Path $storageFolder | Out-Null
}
# Create container folder if it doesn't exist
if (-not (Test-Path -Path $containerFolder)) {
    New-Item -ItemType Directory -Path $containerFolder | Out-Null
}
# Create blob folder if it doesn't exist
if (-not (Test-Path -Path $blobFolder)) {
    New-Item -ItemType Directory -Path $blobFolder | Out-Null
}



