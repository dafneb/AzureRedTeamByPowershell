<#


.NOTES
    Ensure that the Az PowerShell module is installed before running the script.
    The script requires appropriate permissions to access resource data in Azure.
    The output is saved in a file located in a case-specific folder under the "case" directory.

    Author: David Burel (@dafneb)
    Date: April 23, 2025
    Version: 1.0.0
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = "Default")]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Default")]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName,

    [Parameter(Mandatory = $true, ParameterSetName = "Default")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true, ParameterSetName = "Default")]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccount,

    [Parameter(Mandatory = $true, ParameterSetName = "Default")]
    [ValidateNotNullOrEmpty()]
    [string]$Table
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Dumping table *********************************"
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

if (-not (Get-Module -Name AzTable -ListAvailable)) {
    Write-Verbose -Message "AzTable module not found ..."
    Write-Error -Message "AzTable module not found, please install it first" -Category NotInstalled
    exit
}

# Check if Az module is loaded
if (-not (Get-Module -Name Az)) {
    Write-Verbose -Message "Loading Az module ..."
    Import-Module Az -ErrorAction Stop
}

if (-not (Get-Module -Name AzTable)) {
    Write-Verbose -Message "Loading AzTable module ..."
    Import-Module AzTable -ErrorAction Stop
}

# Normalize case name to lowercase
$caseFolderName = $CaseName.ToLower()
$caseFolderName = $caseFolderName.Trim()
$caseFolderName = $caseFolderName -replace '[\\/:*?"<>|]', '_'

# Paths for logs
$baseFolderPath = Join-Path -Path (Get-Location) -ChildPath "case"
$caseFolderPath = Join-Path -Path $baseFolderPath -ChildPath "$($caseFolderName)"
$tabsFolderPath = Join-Path -Path $caseFolderPath -ChildPath "tables"

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
if (-not (Test-Path -Path $tabsFolderPath)) {
    Write-Verbose -Message "Table folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $tabsFolderPath | Out-Null
}

Write-Verbose -Message "CaseName: $($CaseName)"
Write-Verbose -Message "ResourceGroupName: $($ResourceGroupName)"
Write-Verbose -Message "StorageAccount: $($StorageAccount)"
Write-Verbose -Message "Table: $($Table)"

# Connect to Azure
Write-Verbose -Message "Connecting to Azure ..."

Connect-AzAccount
# Check if the connection was successful
$azContext = Get-AzContext
if ($null -eq $azContext) {
    Write-Verbose -Message "Failed to connect to Azure ..."
    Write-Error -Message "Failed to connect to Azure. Please check your credentials and permissions." -Category ConnectionError
    exit
}

Write-Verbose -Message "Getting tables from Azure ..."
Write-Verbose -Message "ParameterSetName: $($PSCmdlet.ParameterSetName)"

switch($PSCmdlet.ParameterSetName) {
    'Default' {
        # Get storage account context
        Write-Verbose -Message "Getting storage account context ..."
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccount -UseConnectedAccount
        # $storageContext = (Get-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroupName -DefaultProfile $azContext).Context

        if ($null -eq $storageContext) {
            Write-Error -Message "Storage context not found. Please check the storage account name." -Category ObjectNotFound
            exit
        }

        # Get the table's context
        Write-Verbose -Message "Getting table context ..."
        $storageTable = Get-AzStorageTable -Context $storageContext -Name $Table
        if ($null -eq $storageTable) {
            Write-Error -Message "Table not found. Please check the name" -Category ObjectNotFound
            exit
        }

        Write-Verbose -Message "Getting cloud table context ..."
        $cloudTable = $storageTable.CloudTable
        if ($null -eq $cloudTable) {
            Write-Error -Message "Cloud Table not found. Please check the name" -Category ObjectNotFound
            exit
        }

        # Retrieve all rows
        Write-Verbose -Message "Retrieve all rows ..."
        $rows = Get-AzTableRow -Table $cloudTable
        Write-Verbose -Message "Rows retrieved: $($rows.Count)"
        # $rows = Get-AzTableRow -Table $cloudTable
        # $rows
        # $rows | ForEach-Object {
        #     $row = $_
        #     $row
        # }

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
