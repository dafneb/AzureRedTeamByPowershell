

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Blob')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$Domain = "your-domain",

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
$logFolder = Join-Path -Path $basePath -ChildPath $Domain
$blobFolder = Join-Path -Path $logFolder -ChildPath "blobs"

# Create case folder if it doesn't exist
if (-not (Test-Path -Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
}
# Create domain folder if it doesn't exist
if (-not (Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}
# Create blob folder if it doesn't exist
if (-not (Test-Path -Path $blobFolder)) {
    New-Item -ItemType Directory -Path $blobFolder | Out-Null
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

# Get blob context
$Context = New-AzStorageContext -StorageAccountName $StorageAccount -UseConnectedAccount

# Get the blob's context from the specified container
if ($PSCmdlet.ParameterSetName -eq 'VersionId') {
    $blobik = Get-AzStorageBlob -Container $Container -Context $Context -Blob $Blob -VersionId $VersionId
} else {
    $blobik = Get-AzStorageBlob -Container $Container -Context $Context -Blob $Blob
}

if ($null -eq $blobik) {
    Write-Host "Blob not found. Please check the blob name, version id and container."
    exit
}

$blobPath = Join-Path -Path $blobFolder -ChildPath $blobik.Name
$blobik | Get-AzStorageBlobContent -Destination $blobPath -Force | Out-Null

# Check if the blob was downloaded successfully
if (Test-Path -Path $blobPath) {
    Write-Host "Blob downloaded successfully to $blobPath"
} else {
    Write-Host "Failed to download the blob."
}

# Close connection
Disconnect-AzAccount | Out-Null
