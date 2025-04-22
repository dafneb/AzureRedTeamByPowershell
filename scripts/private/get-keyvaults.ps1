


# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = "Default")]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Default")]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName = "case-name"
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** KeyVaults *************************************"
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

# Normalize case name to lowercase
$caseFolderName = $CaseName.ToLower()
$caseFolderName = $caseFolderName.Trim()
$caseFolderName = $caseFolderName -replace '[\\/:*?"<>|]', '_'

# Paths for logs (1/2)
$baseFolderPath = Join-Path -Path (Get-Location) -ChildPath "case"
$caseFolderPath = Join-Path -Path $baseFolderPath -ChildPath "$($caseFolderName)"
$keysFolderPath = Join-Path -Path $caseFolderPath -ChildPath "keys"
$certsFolderPath = Join-Path -Path $caseFolderPath -ChildPath "certs"

Write-Verbose -Message "Checking folders (1/2) ..."

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

# Create keys folder if it doesn't exist
if (-not (Test-Path -Path $keysFolderPath)) {
    Write-Verbose -Message "Keys folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $keysFolderPath | Out-Null
}

# Create certs folder if it doesn't exist
if (-not (Test-Path -Path $certsFolderPath)) {
    Write-Verbose -Message "Certs folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $certsFolderPath | Out-Null
}

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

$azAccount = $azContext.Account.Id
# Normalize account name to lowercase
$accountFolderName = $azAccount.ToLower()
$accountFolderName = $accountFolderName.Trim()
$accountFolderName = $accountFolderName -replace '[\\/:*?"<>|]', '_'

# Paths for logs (2/2)
$accountFolderPath = Join-Path -Path $caseFolderPath -ChildPath "$($accountFolderName)"
$logFilePath = Join-Path -Path $accountFolderPath -ChildPath "keyvaults.txt"

Write-Verbose -Message "Checking folders (2/2) ..."

# Create account folder if it doesn't exist
if (-not (Test-Path -Path $accountFolderPath)) {
    Write-Verbose -Message "Case folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $accountFolderPath | Out-Null
}

# Create log file if it doesn't exist
if (-not (Test-Path -Path $logFilePath)) {
    Write-Verbose -Message "File for logs does not exist, creating it..."
    New-Item -ItemType File -Path $logFilePath | Out-Null
} else {
    # Clear the log file if it already exists
    Clear-Content -Path $logFilePath
}

Write-Verbose -Message "Getting data from Azure ..."

$dataKeyVaults = @()
$keyVaults = Get-AzKeyVault
$keyVaults | ForEach-Object {
    $keyVaultItem = Get-AzKeyVault -VaultName $_.VaultName -ResourceGroupName $_.ResourceGroupName
    Write-Verbose -Message "Processing key vault: $($keyVaultItem.VaultName) ..."
    $dataKeyVaults += "Name: $($keyVaultItem.VaultName); ResourceGroup: $($keyVaultItem.ResourceGroupName); Location: $($keyVaultItem.Location); SKU: $($keyVaultItem.Sku)"
    # Get keyvault's Tags
    if ($keyVaultItem.Tags.Count -gt 0) {
        $dataKeyVaults += "`tTags:"
        $keyVaultItem.Tags.GetEnumerator() | ForEach-Object {
            $dataKeyVaults += "`t`t$($_.Key): $($_.Value)"
        }
    } else {
        $dataKeyVaults += "`tTags: None"
    }
    $dataKeyVaults += "`tURI: $($keyVaultItem.VaultUri)"
    $dataKeyVaults += "`tPublicNetworkAccess: $($keyVaultItem.PublicNetworkAccess)"
    $dataKeyVaults += "`tEnabledForDeployment: $($keyVaultItem.EnabledForDeployment)"
    $dataKeyVaults += "`tEnabledForDiskEncryption: $($keyVaultItem.EnabledForDiskEncryption)"
    $dataKeyVaults += "`tEnabledForTemplateDeployment: $($keyVaultItem.EnabledForTemplateDeployment)"
    $dataKeyVaults += "`tEnableRbacAuthorization: $($keyVaultItem.EnableRbacAuthorization)"
    $dataKeyVaults += "`tEnablePurgeProtection: $($keyVaultItem.EnablePurgeProtection)"
    $dataKeyVaults += "`tEnableSoftDelete: $($keyVaultItem.EnableSoftDelete)"
    $dataKeyVaults += "`tNetwork Rule Set:"
    $dataKeyVaults += "`t`tDefault action: $($keyVaultItem.NetworkAcls.DefaultAction)"
    $dataKeyVaults += "`t`tBypass: $($keyVaultItem.NetworkAcls.Bypass)"
    $dataKeyVaults += "`t`tvNet Rules:"
    $keyVaultItem.NetworkAcls.VirtualNetworkResourceIds | ForEach-Object {
        $rule = $_
        if ($rule.Length -gt 0) {
            $dataKeyVaults += "`t`t`t$($rule)"
        }
    }
    $dataKeyVaults += "`t`tIP Rules:"
    $keyVaultItem.NetworkAcls.IpAddressRanges | ForEach-Object {
        $rule = $_
        if ($rule.Length -gt 0) {
            $dataKeyVaults += "`t`t`t$($rule)"
        }
    }
    $dataKeyVaults += "`tSecrets:"
    $keyVaultSecrets = Get-AzKeyVaultSecret -VaultName $keyVaultItem.VaultName
    $keyVaultSecrets | ForEach-Object {
        $secretCommon = $_
        $secretValue = Get-AzKeyVaultSecret -VaultName $keyVaultItem.VaultName -Name $secretCommon.Name -AsPlainText
        $dataKeyVaults += "`t`tName: $($secretCommon.Name)"
        $dataKeyVaults += "`t`t`tValue: $($secretValue)"
        $dataKeyVaults += "`t`t`tId: $($secretCommon.Id)"
        $dataKeyVaults += "`t`t`tEnabled: $($secretCommon.Enabled)"
    }
    $dataKeyVaults += "`tKeys:"
    $keyVaultKeys = Get-AzKeyVaultKey -VaultName $keyVaultItem.VaultName
    $keyVaultKeys | ForEach-Object {
        $keyCommon = $_
        $dataKeyVaults += "`t`tName: $($keyCommon.Name)"
        $dataKeyVaults += "`t`t`tId: $($keyCommon.Id)"
        $dataKeyVaults += "`t`t`tEnabled: $($keyCommon.Enabled)"
        $dataKeyVaults += "`t`t`tExpires: $($keyCommon.Expires)"
        $keyFilePath = Join-Path -Path $keysFolderPath -ChildPath "$($keyCommon.Name).pem"
        Get-AzKeyVaultKey -VaultName $keyVaultItem.VaultName -Name $keyCommon.Name -OutputFile $keyFilePath
    }
    $dataKeyVaults += "`tCertificates:"
    $keyVaultCertificates = Get-AzKeyVaultCertificate -VaultName $keyVaultItem.VaultName
    $keyVaultCertificates | ForEach-Object {
        $certCommon = $_
        $dataKeyVaults += "`t`tName: $($certCommon.Name)"
        $certDetails = Get-AzKeyVaultCertificate -VaultName $keyVaultItem.VaultName -Name $certCommon.Name
        $dataKeyVaults += "`t`t`tEnabled: $($certDetails.Enabled)"
        $dataKeyVaults += "`t`t`tKeyId: $($certDetails.KeyId)"
        $dataKeyVaults += "`t`t`tSecretId: $($certDetails.SecretId)"
        $dataKeyVaults += "`t`t`tThumbprint: $($certDetails.Thumbprint)"
        $certBase64 = Get-AzKeyVaultSecret -VaultName $keyVaultItem.VaultName -Name $certCommon.Name -AsPlainText
        $certBytes = [Convert]::FromBase64String($certBase64)
        $certFilePath = Join-Path -Path $certsFolderPath -ChildPath "$($certCommon.Name).pfx"
        Set-Content -Path $certFilePath -Value $CertBytes -AsByteStream
    }

}

# Export the keyvaults details to a text file
Write-Verbose -Message "Saving data ..."
$dataKeyVaults | ForEach-Object { Add-Content -Path $logFilePath -Value $_ }

# Close connection
Disconnect-AzAccount | Out-Null

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
