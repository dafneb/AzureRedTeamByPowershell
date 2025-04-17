
# Define the script's parameters
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Domain = "your-domain"
)

# Paths for logs
$basePath = Join-Path -Path (Get-Location) -ChildPath "case"
$logFolder = Join-Path -Path $basePath -ChildPath $Domain

# Create case folder if it doesn't exist
if (-not (Test-Path -Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
}
# Create domain folder if it doesn't exist
if (-not (Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
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

$azContext = Get-AzContext

$logFolder2 = Join-Path -Path $logFolder -ChildPath "$($azContext.Account)"
$logFile = Join-Path -Path $logFolder2 -ChildPath "resources.csv"

# Create entity folder if it doesn't exist
if (-not (Test-Path -Path $logFolder2)) {
    New-Item -ItemType Directory -Path $logFolder2 | Out-Null
}
# Create log file if it doesn't exist
if (-not (Test-Path -Path $logFile)) {
    New-Item -ItemType File -Path $logFile | Out-Null
}
else {
    # Clear the log file if it already exists
    Clear-Content -Path $logFile
}

# Get list of all visible resources
$dataResources = @()
$resources = Get-AzResource -ApiVersion '2024-11-01'
$resources | ForEach-Object {
    $resource = $_
    $dataResources += [PSCustomObject]@{
        ResourceName = "$($resource.Name)";
        ResourceType = "$($resource.ResourceType)";
        ResourceGroupName = "$($resource.ResourceGroupName)";
        Location = "$($resource.Location)";
        ResourceId = "$($resource.ResourceId)"
        Tags = "$($resource.Tags | Out-String)"
    }
}
# Export the resource details to a CSV file
$dataResources | Export-Csv -Path $logFile -NoTypeInformation

# Close connection
Disconnect-AzAccount | Out-Null
