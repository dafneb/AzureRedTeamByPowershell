

# Define the script's parameters
[CmdletBinding()]
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
$logFile = Join-Path -Path $logFolder2 -ChildPath "virtualmachines.txt"

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

# Get list of all virtual machines
$dataVMs = @()
$virtualMachines = Get-AzVM
$virtualMachines | ForEach-Object {
    $vmItem = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -UserData
    # Display the virtual machine details
    $dataVMs += "Name: $($vmItem.Name); ResourceGroupName: $($vmItem.ResourceGroupName); Location: $($vmItem.Location)"
    # Get VM's OS type
    if ($vmItem.StorageProfile.OsDisk.OsType -eq "Windows") {
        $dataVMs += "`tOS: Windows"
    } else {
        $dataVMs += "`tOS: Linux"
    }
    # Get VM's Tags
    if ($vmItem.Tags.Count -gt 0) {
        $dataVMs += "`tTags:"
        $vmItem.Tags.GetEnumerator() | ForEach-Object {
            $dataVMs += "`t`t$($_.Key): $($_.Value)"
        }
    } else {
        $dataVMs += "`tTags: None"
    }
    # Get VM's User data
    if ($vmItem.UserData -ne $null) {
        # Decode the UserData property
        $userData = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($vmItem.UserData))
        $dataVMs += "`tUserData:"
        $dataVMs += "$($userData)"
    }
}
$dataVMs | ForEach-Object { Add-Content -Path $logFile -Value $_ }

# Close connection
Disconnect-AzAccount | Out-Null
