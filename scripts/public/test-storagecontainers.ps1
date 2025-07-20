<#
.SYNOPSIS
    This script checks Azure Blob Storage containers and retrieves their properties, metadata, and blob listings.

.DESCRIPTION
    The script can be run in two modes:
    1. By providing a case name and a list of container endpoints via command line parameters.
    2. By providing a case name and a file path containing container endpoints in CSV format.

.PARAMETER CaseName
    The name of the case. This will be used to create a folder for storing
    results.

.PARAMETER ContainerEndpoints
    An array of container endpoints to check.

.PARAMETER FilePath
    The path to a CSV file containing container endpoints.

.NOTES
    Author: David Burel (@dafneb)
    Date: July 19, 2025
    Version: 1.0.0
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Container')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Container")]
    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Container')]
    [ValidateNotNullOrEmpty()]
    [string[]]$ContainerEndpoints,

    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Blob Storage Containers checking **************"
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

# Prepare list of endpoints
$endpoints = @()
switch ($PSCmdlet.ParameterSetName) {
    'Container' {
        # Get endpoints from the command line
        Write-Verbose -Message "Reading endpoints from command line ..."
        $endpoints = $ContainerEndpoints
    }
    'File' {
        Write-Verbose -Message "Reading endpoints from file: $($FilePath) ..."
        if (Test-Path -Path $FilePath -PathType Leaf) {
            $csvContent = Import-Csv -Path $FilePath -Delimiter ',' -Encoding UTF8
            $csvContent | ForEach-Object {
                $row = $_
                if ($row.Value) {
                    $endpoints += $row.Value

                } elseif ($row.Endpoint -and $row.Container) {
                    $endpoints += 'https://' + $row.Endpoint + '/' + $row.Container

                } else {
                    Write-Warning "CSV row does not contain 'Value' column, neither 'Endpoint' and 'Container' columns"
                    return

                }
            }

        } else {
            Write-Error -Message "File not found: $($FilePath)" -Category ObjectNotFound
            exit
        }
    }
}

$endpoints | ForEach-Object -Parallel {
    $endpoint = $_.Trim()
    Write-Output "Processing: $($endpoint)"
    $VerbosePreference = $using:VerbosePreference
    $DebugPreference = $using:DebugPreference
    $storageFolderPath = $using:storageFolderPath

    # Prepare the request headers
    # x-ms-version: 2025-05-05
    # x-ms-date: {{$datetime rfc1123}}
    # x-ms-client-request-id: {{$guid}}
    $requestHeaders = @{
        'Accept' = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
        'Accept-Language' = 'en-US,en;q=0.5';
        'x-ms-version' = '2025-05-05';
        'x-ms-date' = (Get-Date).ToUniversalTime().ToString("R");
        'x-ms-client-request-id' = [guid]::NewGuid().ToString();
    }

    # URI builder for the blob storage
    try {
        $uriBuilderEndpoint = New-Object System.UriBuilder($endpoint)
        $uriBuilderEndpoint.Scheme = 'https'
        $uriBuilderEndpoint.Port = 443
    } catch {
        Write-Warning -Message "Error processing endpoint: $($endpoint)"
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
    $blobsFilePath = Join-Path -Path $containerFolderPath -ChildPath "pub-blobs.csv"
    if (-not (Test-Path -Path $blobsFilePath)) {
        Write-Verbose -Message "Creating containers file: $($blobsFilePath)"
        New-Item -ItemType File -Path $blobsFilePath | Out-Null
    } else {
        Clear-Content -Path $blobsFilePath
    }

    ### Get Container Properties
    $uriBuilderEndpoint.Query = "restype=container"
    $fileOutputPath = Join-Path -Path $containerFolderPath -ChildPath "container-properties-headers.txt"
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Headers | Format-Table | Out-File -FilePath $fileOutputPath
        }
    } catch {
        Write-Verbose -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Verbose -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    }

    ### Get Container Metadata
    $uriBuilderEndpoint.Query = "restype=container&comp=metadata"
    $fileOutputPath = Join-Path -Path $containerFolderPath -ChildPath "container-metadata-headers.txt"
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Headers | Format-Table | Out-File -FilePath $fileOutputPath
        }
    } catch {
        Write-Verbose -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Verbose -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    }

    ### List Blobs
    $uriBuilderEndpoint.Query = "restype=container&comp=list&include=versions"
    $fileOutputPath = Join-Path -Path $containerFolderPath -ChildPath "blobs-list.xml"
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Content | Out-File -FilePath $fileOutputPath
            $XmlDocument = New-Object System.XML.XMLDocument
            $XmlDocument.Load($fileOutputPath)
            $dataBlobs = @()
            $XmlDocument.EnumerationResults.Blobs.Blob | ForEach-Object {
                Write-Verbose -Message "Processing blob: $($_.Name); VersionId: $($_.VersionId)"
                $storAccount = $uriBuilderEndpoint.Host -split '\.' | Select-Object -First 1
                $dataBlobs += [PSCustomObject]@{
                    Value = $uriBuilderEndpoint.Uri
                    Endpoint = $uriBuilderEndpoint.Host
                    StorageAccount = $storAccount
                    Container = $containerName
                    BlobName = $_.Name
                    VersionId = $_.VersionId
                    ContentType = $_.Properties.'Content-Type'
                }
            }
            $dataBlobs | Export-Csv -Path $blobsFilePath -NoTypeInformation -Encoding UTF8
        }
    } catch {
        Write-Warning -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Warning -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
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
