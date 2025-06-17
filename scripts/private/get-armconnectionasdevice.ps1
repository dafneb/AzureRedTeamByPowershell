<#
.SYNOPSIS
    Connects to Azure Resource Manager using the Az module.

.NOTES
    Ensure that the Microsoft Az PowerShell module is installed before running the script.

    Author: David Burel (@dafneb)
    Date: June 15, 2025
    Version: 1.0.0
#>

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Sign-in to Azure Resource Manager *************"
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

# Check if Az module is loaded
if (-not (Get-Module -Name Az)) {
    Write-Verbose -Message "Loading Az module ..."
    Import-Module Az -ErrorAction Stop
}

# Connect to Azure
Write-Verbose -Message "Connecting to Azure ..."

# Note: The -UseDeviceAuthentication parameter is used to authenticate as a device, which is suitable for scenarios where you cannot use interactive login.
Connect-AzAccount -UseDeviceAuthentication

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
