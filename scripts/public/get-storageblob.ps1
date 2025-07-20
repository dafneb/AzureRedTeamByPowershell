<#
.NOTES
    Author: David Burel (@dafneb)
    Date: July 20, 2025
    Version: 1.0.2
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Blob')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Blob")]
    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [Parameter(Mandatory = $true, ParameterSetName = 'VersionId')]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerEndpoints,

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
$storageFolderPath = Join-Path -Path $caseFolderPath -ChildPath "storage"

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

# Create storage folder if it doesn't exist
if (-not (Test-Path -Path $storageFolderPath)) {
    Write-Verbose -Message "Storage folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $storageFolderPath | Out-Null
}

# Prepare list of blobs to download
$blobsToDownload = @()
switch ($PSCmdlet.ParameterSetName) {
    'Blob' {
        Write-Verbose -Message "Reading endpoints from command line (/wo VersionId) ..."
        $blobsToDownload += [PSCustomObject]@{
            Container = $ContainerEndpoints
            Blob      = $Blob
            VersionId = $null
        }
    }
    'VersionId' {
        Write-Verbose -Message "Reading endpoints from command line (/w VersionId) ..."
        $blobsToDownload += [PSCustomObject]@{
            Container = $ContainerEndpoints
            Blob      = $Blob
            VersionId = $VersionId
        }
    }
    'File' {
        Write-Verbose -Message "Reading endpoints from file: $($FilePath) ..."
        if (Test-Path -Path $FilePath -PathType Leaf) {
            $csvContent = Import-Csv -Path $FilePath -Delimiter ',' -Encoding UTF8
            $csvContent | ForEach-Object {
                $row = $_
                if ($row.Value -and $row.BlobName) {
                    $blobsToDownload += [PSCustomObject]@{
                        Container = $row.Value
                        Blob      = $row.BlobName
                        VersionId = ($row.VersionId -ne $null) ? $row.VersionId : $null
                    }

                } elseif ($row.Endpoint -and $row.Container -and $row.BlobName) {
                    $blobsToDownload += [PSCustomObject]@{
                        Container = 'https://' + $row.Endpoint + '/' + $row.Container
                        Blob      = $row.BlobName
                        VersionId = ($row.VersionId -ne $null) ? $row.VersionId : $null
                    }

                } else {
                    Write-Warning "CSV row does not contain all required columns"
                    return

                }
            }
        } else {
            Write-Error -Message "File path '$FilePath' does not exist." -Category ObjectNotFound
            exit
        }

    }
}

# Let's download blobs ....
Write-Verbose -Message "Downloading blobs ..."
$blobsToDownload | ForEach-Object -Parallel {
    $blobik = $_
    Write-Output "Processing: $($blobik.Blob) at $($blobik.Container)"
    $VerbosePreference = $using:VerbosePreference
    $DebugPreference = $using:DebugPreference
    $storageFolderPath = $using:storageFolderPath

    # Prepare the request headers
    # x-ms-version: 2025-05-05
    # x-ms-date: {{$datetime rfc1123}}
    # x-ms-client-request-id: {{$guid}}
    $requestHeaders = @{
        'x-ms-version' = '2025-05-05';
        'x-ms-date' = (Get-Date).ToUniversalTime().ToString("R");
        'x-ms-client-request-id' = [guid]::NewGuid().ToString();
    }

    # URI builder for the blob storage
    try {
        $uriBuilderEndpoint = New-Object System.UriBuilder($blobik.Container)
        $uriBuilderEndpoint.Scheme = 'https'
        $uriBuilderEndpoint.Port = 443
    } catch {
        Write-Warning -Message "Error processing endpoint: $($blobik.Container)"
        return
    }

    # Endpoint folder path
    $endpointFolderPath = Join-Path -Path $storageFolderPath -ChildPath $uriBuilderEndpoint.Host
    if (-not (Test-Path -Path $endpointFolderPath)) {
        Write-Verbose -Message "Creating folder for endpoint: $($endpoint)"
        New-Item -ItemType Directory -Path $endpointFolderPath | Out-Null
    }
    $containerName = $uriBuilderEndpoint.Path.TrimStart('/')
    $containerFolderPath = Join-Path -Path $endpointFolderPath -ChildPath $containerName
    if (-not (Test-Path -Path $containerFolderPath)) {
        Write-Verbose -Message "Creating folder for container: $($containerName)"
        New-Item -ItemType Directory -Path $containerFolderPath | Out-Null
    }
    $blobsFolderPath = Join-Path -Path $containerFolderPath -ChildPath "blobs"
    # Create blob folder if it doesn't exist
    if (-not (Test-Path -Path $blobsFolderPath)) {
        Write-Verbose -Message "Blob folder does not exist, creating it..."
        New-Item -ItemType Directory -Path $blobsFolderPath | Out-Null
    }

    $versFolderPath = $blobsFolderPath
    if ($blobik.VersionId) {
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
    }
    $uriBuilderEndpoint.Path = "$($containerName)/$($blobik.Blob)"
    $uriBuilderEndpoint.Query = ($blobik.VersionId) ? "versionId=$($blobik.VersionId)" : $null
    $fileOutputPath = Join-Path -Path $versFolderPath -ChildPath $blobik.Blob

    try {
        Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders -OutFile $fileOutputPath -UseBasicParsing
        Write-Verbose -Message "Blob downloaded: $($fileOutputPath)"
    } catch {
        Write-Warning -Message "Error downloading blob: $($uriBuilderEndpoint.Host) in $($uriBuilderEndpoint.Path)"
        return
    }

} -ThrottleLimit 10

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
