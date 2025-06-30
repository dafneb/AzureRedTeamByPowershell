<#
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

    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath,

    [Parameter(Mandatory = $false, ParameterSetName = "Account")]
    [Parameter(Mandatory = $false, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$WordlistFilePath = $null
)
