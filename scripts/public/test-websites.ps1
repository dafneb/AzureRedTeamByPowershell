<#
.SYNOPSIS
    This script checks the accessibility of websites and extracts information about Azure Storage Accounts.

.DESCRIPTION
    The script takes a list of websites either from the command line or from a file, checks their accessibility,
    and extracts information about Azure Storage Accounts if available. The results are saved in a CSV file.

.PARAMETER CaseName
    The name of the case. This will be used to create a folder for storing results.

.PARAMETER Uri
    The list of website URIs to check. This parameter is used when the 'Uri' parameter set is selected.

.PARAMETER FilePath
    The path to a file containing a list of website URIs. This parameter is used when the 'File' parameter set is selected.

.EXAMPLE
    ./test-websites.ps1 -CaseName "example-case" -Uri "https://example.com", "https://another-example.com"
    This command checks the accessibility of the specified websites and extracts information about Azure Storage Accounts.

.EXAMPLE
    ./test-websites.ps1 -CaseName "example-case" -FilePath "/path/to/websites.txt"
    This command checks the accessibility of the websites listed in the specified file and extracts information about Azure Storage Accounts.

.NOTES
    The output is saved in a text file located in a case-specific folder under the "case" directory.

    Author: David Burel (@dafneb)
    Date: April 18, 2025
    Version: 1.0.0
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Uri')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Uri")]
    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName = "case-name",

    [Parameter(Mandatory = $true, ParameterSetName = 'Uri')]
    [ValidateNotNullOrEmpty()]
    [string[]]$Uri = "website-uri",

    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Websites scraping *****************************"
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
$storFilePath = Join-Path -Path $caseFolderPath -ChildPath "storageaccounts.csv"

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
if (-not (Test-Path -Path $storFilePath)) {
    Write-Verbose -Message "Log file does not exist, creating it..."
    New-Item -ItemType File -Path $storFilePath | Out-Null
} else {
    Clear-Content -Path $storFilePath
}

# Prepare list of websites to check
$websites = @()
switch ($PSCmdlet.ParameterSetName) {
    'Uri' {
        # Get websites from the command line
        Write-Verbose -Message "Reading websites from command line ..."
        $websites += $Uri
    }

    'File' {
        # Get websites from a file
        Write-Verbose -Message "Reading websites from file $($FilePath) ..."
        if (Test-Path -Path $FilePath -PathType Leaf) {
            $websites += Get-Content -Path $FilePath
        } else {
            Write-Error -Message "File not found: $($FilePath)" -Category ObjectNotFound
            exit
        }
    }
}

# Let's check the websites ....
Write-Verbose -Message "Checking websites ..."
$dataStorages = @()
$websites | ForEach-Object {
    $address = $_.Trim()
    Write-Verbose -Message "Processing address: $($address)"
    try {
        $websiteUri = New-Object System.UriBuilder($address)
    } catch {
        Write-Warning -Message "Error processing address: $($address)"
        continue
    }

    # Let's check if the website is accessible
    try {
        $response = Invoke-WebRequest -Uri $websiteUri.Uri
        Write-Verbose -Message "StatusCode: $($response.StatusCode)"
        Write-Verbose -Message "StatusDescription: $($response.StatusDescription)"
    } catch {
        Write-Warning -Message "Failed to access the website: $($address)"
        Write-Warning -Message "StatusCode: $($_.Exception.Response.StatusCode.value__)"
        continue
    }

    # Check headers 
    Write-Verbose -Message "Headers:"
    $response.Headers.Keys | ForEach-Object {
        $key = $_
        Write-Verbose -Message "$($key): $($response.Headers[$key] -Join ', ')"
    }

    # Check content and try find if it's a blob storage
    Write-Verbose -Message "Checking for blob storage ..."
    if ($response.StatusCode -eq 200) {
        # Check if the website contains any link to a blob storage
        # Pattern for all services under StorageAccount 'https://([0-9a-z]{3,24})\.(blob|web|dfs|file|queue|table)\.core\.windows\.net/([0-9a-z-_$]{3,63})/'
        Write-Verbose -Message "Checking for regular expression against context:"    
        Write-Verbose -Message "Pattern: (?<endpoint>https://(?<storageacc>[0-9a-z]{3,24})\.blob\.core\.windows\.net)/(?<container>[0-9a-z-_$]{3,63})/"    
        $results = $response.Content | Select-String -Pattern '(?<endpoint>https://(?<storageacc>[0-9a-z]{3,24})\.blob\.core\.windows\.net)/(?<container>[0-9a-z-_$]{3,63})/' -AllMatches
        # We want to get unique matches
        $uniqueMatches = $results.Matches | Select-Object -Unique
        Write-Verbose -Message "Unique Matches:"
        $uniqueMatches | ForEach-Object {
            Write-Verbose -Message "Value: $($_.Value)"
            Write-Verbose -Message "Endpoint: $($_.Groups['endpoint'].Value)"
            Write-Verbose -Message "StorageAccount: $($_.Groups['storageacc'].Value)"
            Write-Verbose -Message "Container: $($_.Groups['container'].Value)"
            $dataStorages += [PSCustomObject]@{
                Value = "$($_.Value)"; 
                Endpoint = "$($_.Groups['endpoint'].Value)"; 
                StorageAccount = "$($_.Groups['storageacc'].Value)"; 
                Container = "$($_.Groups['container'].Value)" 
            }
        }

    } else {
        Write-Warning -Message "Failed to access the website: $($address)"
        Write-Warning -Message "StatusCode: $($response.StatusCode)"
        continue
    }

}

# Export the storage account details to a CSV file
Write-Verbose -Message "Saving data ..."
$dataStorages | Export-Csv -Path $storFilePath -NoTypeInformation

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
