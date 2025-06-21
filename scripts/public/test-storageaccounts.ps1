<#
.SYNOPSIS
    This script checks the accessibility of Azure Storage Accounts and extracts
    information about them.

.DESCRIPTION
    The script takes a list of storage accounts either from the command line
    or from a file, checks their accessibility, and extracts information about
    them. The results are saved in a CSV file.

.PARAMETER CaseName
    The name of the case. This will be used to create a folder for storing
    results.

.PARAMETER StorageAccount
    The name of the Azure Storage Account to check. This parameter is used
    when the 'Account' parameter set is selected.

.PARAMETER Container
    The name of the Azure Storage Account container to check. This parameter
    is used when the 'Account' parameter set is selected.

.PARAMETER FilePath
    The path to a file containing a list of storage accounts and containers.
    This parameter is used when the 'File' parameter set is selected.

.EXAMPLE
    ./test-storageaccounts.ps1 -CaseName "example-case" -StorageAccount "storage-account" -Container "container-name"
    This command checks the accessibility of the specified storage account
    and container and extracts information about them.

.EXAMPLE
    ./test-storageaccounts.ps1 -CaseName "example-case" -FilePath "/path/to/storageaccounts.csv"
    This command checks the accessibility of the storage accounts and
    containers listed in the specified file and extracts information about
    them.

.NOTES
    The output is saved in a csv file located in a case-specific folder
    under the "case" directory.

    Author: David Burel (@dafneb)
    Date: June 18, 2025
    Version: 1.0.1
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Account')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Account')]
    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Account')]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccount,

    [Parameter(Mandatory = $true, ParameterSetName = 'Account')]
    [ValidateNotNullOrEmpty()]
    [string]$Container,

    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Test Storage Accounts *************************"
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
$blobFilePath = Join-Path -Path $caseFolderPath -ChildPath "pub-blobs.csv"

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

# Create log file if it doesn't exist
if (-not (Test-Path -Path $blobFilePath)) {
    Write-Verbose -Message "Log file does not exist, creating it..."
    New-Item -ItemType File -Path $blobFilePath | Out-Null
} else {
    Clear-Content -Path $blobFilePath
}

# Prepare list of storage accounts to check
$storages = @()
switch ($PSCmdlet.ParameterSetName) {
    'Account' {
        # Create a custom object for the storage account and container
        Write-Verbose -Message "Creating custom object for storage account and container from command line ..."
        $storages += [PSCustomObject]@{
            StorageAccount = $StorageAccount
            Container = $Container
        }
    }

    'File' {
        # Read the CSV file and create a custom object for each row
        Write-Verbose -Message "Reading storage accounts from CSV file ..."
        if (Test-Path -Path $FilePath) {
            try {
                $import = Import-Csv -Path $FilePath
                $import | ForEach-Object {
                    # Create a custom object for each storage account and container
                    $storages += [PSCustomObject]@{
                        StorageAccount = $_.StorageAccount
                        Container = $_.Container
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

# Let's check the storage accounts ....
Write-Verbose -Message "Checking storage accounts ..."
$dataBlobs = @()
$requestHeaders = @{
    "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
    "Accept-Language" = "en-US,en;q=0.5";
}
$requestHeadersVersion = @{
    "x-ms-version" = "2019-12-12";
    "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
    "Accept-Language" = "en-US,en;q=0.5";
}
$storages | ForEach-Object {
    $storageItem = $_
    Write-Verbose -Message "Processing storage account: $($storageItem)"
    $endpoint = "https://$($storageItem.StorageAccount).blob.core.windows.net/"
    Write-Output "Endpoint: $($endpoint)"
    # URI builder for the blob storage
    try {
        $uriBuilderEndpoint = New-Object System.UriBuilder($endpoint)
    } catch {
        Write-Warning -Message "Error processing endpoint: $($endpoint)"
        return
    }
    $storFolderPath = Join-Path -Path $caseFolderPath -ChildPath $uriBuilderEndpoint.Host
    # Create storage folder if it doesn't exist
    if (-not (Test-Path -Path $storFolderPath)) {
        Write-Verbose -Message "Storage folder does not exist, creating it..."
        New-Item -ItemType Directory -Path $storFolderPath | Out-Null
    }

    # Get Account Information
    # /wo x-ms-version
    $uriBuilderEndpoint.Path = "/"
    $uriBuilderEndpoint.Query = "restype=account&comp=properties"
    $fileOutputPath = Join-Path -Path $storFolderPath -ChildPath "account-information.xml"
    Write-Verbose -Message "Get Account Information: $($uriBuilderEndpoint.Uri)"
    # TODO: Ready for next feature - add account information to the CSV file
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Content | Out-File -FilePath $fileOutputPath
            Write-Warning "Found: $($fileOutputPath)"
            $XmlDocument = New-Object System.XML.XMLDocument
            $XmlDocument.Load($fileOutputPath)
        }
    } catch {
        Write-Warning -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Warning -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    }

    # Get Blob Service Properties
    # /wo x-ms-version
    $uriBuilderEndpoint.Path = "/"
    $uriBuilderEndpoint.Query = "restype=service&comp=properties"
    $fileOutputPath = Join-Path -Path $storFolderPath -ChildPath "service-properties.xml"
    Write-Verbose -Message "Get Blob Service Properties: $($uriBuilderEndpoint.Uri)"
    # TODO: Ready for next feature - add service properties to the CSV file
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Content | Out-File -FilePath $fileOutputPath
            Write-Warning "Found: $($fileOutputPath)"
            $XmlDocument = New-Object System.XML.XMLDocument
            $XmlDocument.Load($fileOutputPath)
        }
    } catch {
        Write-Warning -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Warning -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    }

    # List Containers
    # /wo x-ms-version
    $uriBuilderEndpoint.Path = "/"
    $uriBuilderEndpoint.Query = "comp=list"
    $fileOutputPath = Join-Path -Path $storFolderPath -ChildPath "containers.xml"
    Write-Verbose -Message "Listing containers: $($uriBuilderEndpoint.Uri)"
    # TODO: Ready for next feature - add containers to the CSV file
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeaders
        if ($response.StatusCode -eq 200) {
            $response.Content | Out-File -FilePath $fileOutputPath
            Write-Warning "Found: $($fileOutputPath)"
            $XmlDocument = New-Object System.XML.XMLDocument
            $XmlDocument.Load($fileOutputPath)
        }
    } catch {
        Write-Warning -Message "Error processing endpoint: $($uriBuilderEndpoint.Uri)"
        Write-Warning -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    }

    # List Blobs
    # /w x-ms-version
    $uriBuilderEndpoint.Path = "/$($storageItem.Container)"
    $uriBuilderEndpoint.Query = "restype=container&comp=list&include=versions"
    $contFolderPath = Join-Path -Path $storFolderPath -ChildPath $storageItem.Container
    # Create container folder if it doesn't exist
    if (-not (Test-Path -Path $contFolderPath)) {
        Write-Verbose -Message "Container folder does not exist, creating it..."
        New-Item -ItemType Directory -Path $contFolderPath | Out-Null
    }
    $fileOutputPath = Join-Path -Path $contFolderPath -ChildPath "blobs.xml"
    Write-Output "Listing blobs: $($uriBuilderEndpoint.Uri)"
    try {
        $response = Invoke-WebRequest -Uri $uriBuilderEndpoint.Uri -Headers $requestHeadersVersion
        if ($response.StatusCode -eq 200) {
            $response.Content | Out-File -FilePath $fileOutputPath
            $XmlDocument = New-Object System.XML.XMLDocument
            $XmlDocument.Load($fileOutputPath)
            $XmlDocument.EnumerationResults.Blobs.Blob | ForEach-Object {
                Write-Verbose -Message "Processing blob: $($_.Name); VersionId: $($_.VersionId)"
                $dataBlobs += [PSCustomObject]@{
                    StorageAccount = $storageItem.StorageAccount
                    Container = $storageItem.Container
                    BlobName = $_.Name
                    VersionId = $_.VersionId
                    ContentType = $_.Properties.'Content-Type'
                }
            }
        }
    } catch {
        Write-Warning -Message "Error processing endpoint: $($endpoint)"
        Write-Warning -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
        return
    }

}

# Export the storage account details to a CSV file
Write-Output "Saving data ..."
$dataBlobs | Export-Csv -Path $blobFilePath -NoTypeInformation

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
