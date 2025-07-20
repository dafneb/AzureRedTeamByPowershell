<#
.SYNOPSIS
    This script tests Azure Storage Blob access using various methods.

.DESCRIPTION
    This script tests Azure Storage Blob access using various methods.
    It's designed to enumerate storage accounts, retrieve account information,
    service properties, and list containers.
    It's trying to find containers with Anonymous access enabled.

.PARAMETER CaseName
    The name of the case. This will be used to create a folder for storing
    results.

.PARAMETER BlobEndpoints
    The list of Blob Storage endpoints to check. This parameter is used when
    the 'Blob' parameter set is selected.

.PARAMETER FilePath
    The path to a file containing a list of Blob Storage endpoints. This
    parameter is used when the 'File' parameter set is selected.

.PARAMETER PermutationFilePath
    The path to a file containing permutations of container names to check.

.NOTES
    Author: David Burel (@dafneb)
    Date: July 4, 2025
    Version: 1.0.0
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Blob')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Blob")]
    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Blob')]
    [ValidateNotNullOrEmpty()]
    [string[]]$BlobEndpoints,

    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath,

    [Parameter(Mandatory = $false, ParameterSetName = "Blob")]
    [Parameter(Mandatory = $false, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$PermutationFilePath = $null
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Blob Storage Accounts checking ****************"
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
    'Blob' {
        # Get endpoints from the command line
        Write-Verbose -Message "Reading endpoints from command line ..."
        $endpoints = $BlobEndpoints
    }
    'File' {
        Write-Verbose -Message "Reading endpoints from file: $($FilePath) ..."
        if (Test-Path -Path $FilePath -PathType Leaf) {
            $endpoints = Get-Content -Path $FilePath
        } else {
            Write-Error -Message "File not found: $($FilePath)" -Category ObjectNotFound
            exit
        }
    }
}

# Prepare permutation file if provided
$permutations = @()
if ($PermutationFilePath) {
    Write-Verbose -Message "Reading permutations from file: $($PermutationFilePath) ..."
    if ($PermutationFilePath -ne $null -and (Test-Path -Path $PermutationFilePath -PathType Leaf)) {
        $permutations = Get-Content -Path $PermutationFilePath
    } else {
        Write-Error -Message "Permutation file not found: $($PermutationFilePath)" -Category ObjectNotFound
        exit
    }
}

$endpoints | ForEach-Object {
    $endpoint = $_.Trim()
    if (($endpoint -eq '') -or ($endpoint -eq $null) -or ($endpoint.StartsWith('#'))) {
        return
    }
    Write-Output "Processing: $($endpoint)"

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
    $containersFilePath = Join-Path -Path $endpointFolderPath -ChildPath "pub-storagecontainers.csv"
    if (-not (Test-Path -Path $containersFilePath)) {
        Write-Verbose -Message "Creating containers file: $($containersFilePath)"
        New-Item -ItemType File -Path $containersFilePath | Out-Null
    } else {
        Clear-Content -Path $containersFilePath
    }

    ### Get Account Information
    $uriBuilderEndpoint.Path = "/"
    $uriBuilderEndpoint.Query = "restype=account&comp=properties"
    $fileOutputPath = Join-Path -Path $endpointFolderPath -ChildPath "account-information.xml"
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Content | Out-File -FilePath $fileOutputPath
            Write-Output "Found: $($fileOutputPath)"
            $XmlDocument = New-Object System.XML.XMLDocument
            $XmlDocument.Load($fileOutputPath)
        }
    } catch {
        Write-Verbose -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Verbose -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    }

    ### Get Blob Service Properties
    $uriBuilderEndpoint.Path = "/"
    $uriBuilderEndpoint.Query = "restype=service&comp=properties"
    $fileOutputPath = Join-Path -Path $endpointFolderPath -ChildPath "service-properties.xml"
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Content | Out-File -FilePath $fileOutputPath
            Write-Output "Found: $($fileOutputPath)"
            $XmlDocument = New-Object System.XML.XMLDocument
            $XmlDocument.Load($fileOutputPath)
        }
    } catch {
        Write-Verbose -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Verbose -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    }

    ### Get Blob Service Stats
    $uriBuilderEndpoint.Path = "/"
    $uriBuilderEndpoint.Query = "restype=service&comp=stats"
    $fileOutputPath = Join-Path -Path $endpointFolderPath -ChildPath "service-stats.xml"
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Content | Out-File -FilePath $fileOutputPath
            Write-Output "Found: $($fileOutputPath)"
            $XmlDocument = New-Object System.XML.XMLDocument
            $XmlDocument.Load($fileOutputPath)
        }
    } catch {
        Write-Verbose -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Verbose -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    }

    ### List Containers
    $uriBuilderEndpoint.Path = "/"
    $uriBuilderEndpoint.Query = "comp=list"
    $fileOutputPath = Join-Path -Path $endpointFolderPath -ChildPath "list-containers.xml"
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Content | Out-File -FilePath $fileOutputPath
            Write-Output "Found: $($fileOutputPath)"
            $XmlDocument = New-Object System.XML.XMLDocument
            $XmlDocument.Load($fileOutputPath)
        }
    } catch {
        Write-Verbose -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Verbose -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    }

    # Trying to enumerate containers
    $tmpResultInner = $permutations | ForEach-Object -Parallel {
        $permutation = $_.Trim()
        if (($permutation -eq '') -or ($permutation -eq $null) -or ($permutation.StartsWith('#'))) {
            return
        }
        $VerbosePreference = $using:VerbosePreference
        $DebugPreference = $using:DebugPreference
        try {
            $uriBuilderEndpoint = New-Object System.UriBuilder($using:endpoint)
            $uriBuilderEndpoint.Scheme = 'https'
            $uriBuilderEndpoint.Port = 443
            $uriBuilderEndpoint.Path = "/$($permutation)"
            $uriBuilderEndpoint.Query = "restype=container"
            $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $using:requestHeaders
            if ($response.StatusCode -eq 200) {
                $storAccount = $uriBuilderEndpoint.Host -split '\.' | Select-Object -First 1
                [PSCustomObject]@{
                    Value = "$($uriBuilderEndpoint.Uri)";
                    Endpoint = "$($using:endpoint)";
                    StorageAccount = "$($storAccount)";
                    Container = "$($permutation)"
                }
            }
        } catch {
            Write-Verbose -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
            Write-Verbose -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
        }

    } -ThrottleLimit 10
    if ($tmpResultInner) {
        $tmpResultInner | Export-Csv -Path $containersFilePath -NoTypeInformation -Encoding UTF8 -Append
        Write-Output "Containers found: $($tmpResultInner.Count)"
    }
}

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
