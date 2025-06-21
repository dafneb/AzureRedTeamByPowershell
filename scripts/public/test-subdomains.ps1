<#
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = 'Base')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Base")]
    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Base')]
    [ValidateNotNullOrEmpty()]
    [string[]]$Base,

    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$FilePath,

    [Parameter(Mandatory = $false, ParameterSetName = "Base")]
    [Parameter(Mandatory = $false, ParameterSetName = 'File')]
    [ValidateNotNullOrEmpty()]
    [string]$PermutationFilePath = $null
)

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Subdomains enumeration ************************"
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
$subdomainFilePath = Join-Path -Path $caseFolderPath -ChildPath "pub-subdomains.txt"

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

# Create subdomain file if it doesn't exist
if (-not (Test-Path -Path $subdomainFilePath)) {
    Write-Verbose -Message "Subdomain file does not exist, creating it..."
    New-Item -ItemType File -Path $subdomainFilePath | Out-Null
} else {
    Write-Verbose -Message "Subdomain file already exists, clearing it..."
    Clear-Content -Path $subdomainFilePath
}

# Prepare list of bases to check
$baseList = @()
switch ($PSCmdlet.ParameterSetName) {
    'Base' {
        # Get bases from the command line
        Write-Verbose -Message "Reading bases from command line ..."
        $baseList = $Base
    }
    'File' {
        # Get bases from a file
        Write-Verbose -Message "Reading bases from file: $($FilePath) ..."
        if (Test-Path -Path $FilePath -PathType Leaf) {
            $baseList += Get-Content -Path $FilePath
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
    if (Test-Path -Path $PermutationFilePath -PathType Leaf) {
        $permutations = Get-Content -Path $PermutationFilePath
    } else {
        Write-Error -Message "Permutation file not found: $($PermutationFilePath)" -Category ObjectNotFound
        exit
    }
}

# Prepare hash table for services
# Reference: https://learn.microsoft.com/en-gb/azure/security/fundamentals/azure-domains
# Reference: https://github.com/yuyudhn/AzSubEnum/blob/main/azsubenum.py#L46
$services = @()
$services += [PSCustomObject]@{
    Id = 'sharepoint';
    Name = 'SharePoint';
    Suffixes = @('sharepoint.com')
}
$services += [PSCustomObject]@{
    Id = 'accesscontrol';
    Name = 'Azure Access Control Service (retired)';
    Suffixes = @('accesscontrol.windows.net')
}
$services += [PSCustomObject]@{
    Id = 'entra';
    Name = 'Microsoft Entra ID';
    Suffixes = @('graph.windows.net', 'onmicrosoft.com')
}
$services += [PSCustomObject]@{
    Id = 'apim';
    Name = 'Azure API Management';
    Suffixes = @('azure-api.net')
}
$services += [PSCustomObject]@{
    Id = 'biztalk';
    Name = 'Azure BizTalk Services (retired)';
    Suffixes = @('biztalk.windows.net')
}
$services += [PSCustomObject]@{
    Id = 'blob';
    Name = 'Azure Blob storage';
    Suffixes = @('blob.core.windows.net')
}
$services += [PSCustomObject]@{
    Id = 'cloudapp';
    Name = 'Azure Cloud Services and Azure Virtual Machines';
    Suffixes = @('cloudapp.net', 'cloudapp.azure.com')
}
$services += [PSCustomObject]@{
    Id = 'containerregistry';
    Name = 'Azure Container Registry';
    Suffixes = @('azurecr.io')
}
$services += [PSCustomObject]@{
    Id = 'container';
    Name = 'Azure Container Service (deprecated)';
    Suffixes = @('azurecontainer.io')
}
$services += [PSCustomObject]@{
    Id = 'redis';
    Name = 'Azure Redis Cache';
    Suffixes = @('redis.cache.windows.net')
}
# $services += [PSCustomObject]@{
#     Id = 'cdn';
#     Name = 'Azure Content Delivery Network (CDN)';
#     Suffixes = @('vo.msecnd.net')
# }
$services += [PSCustomObject]@{
    Id = 'cosmosdb';
    Name = 'Azure Cosmos DB';
    Suffixes = @('cosmos.azure.com', 'documents.azure.com')
}
$services += [PSCustomObject]@{
    Id = 'files';
    Name = 'Azure Files';
    Suffixes = @('file.core.windows.net')
}
# $services += [PSCustomObject]@{
#     Id = 'frontdoor';
#     Name = 'Azure Front Door';
#     Suffixes = @('azurefd.net')
# }
$services += [PSCustomObject]@{
    Id = 'keyvault';
    Name = 'Azure Key Vault';
    Suffixes = @('vault.azure.net')
}
$services += [PSCustomObject]@{
    Id = 'kubernetes';
    Name = 'Azure Kubernetes Service';
    Suffixes = @('azmk8s.io')
}
$services += [PSCustomObject]@{
    Id = 'management';
    Name = 'Azure Management Services';
    Suffixes = @('management.core.windows.net')
}
$services += [PSCustomObject]@{
    Id = 'media';
    Name = 'Azure Media Services';
    Suffixes = @('origin.mediaservices.windows.net')
}
$services += [PSCustomObject]@{
    Id = 'mobile';
    Name = 'Azure Mobile Apps';
    Suffixes = @('azure-mobile.net')
}
$services += [PSCustomObject]@{
    Id = 'queue';
    Name = 'Azure Queue Storage';
    Suffixes = @('queue.core.windows.net')
}
$services += [PSCustomObject]@{
    Id = 'servicebus';
    Name = 'Azure Service Bus';
    Suffixes = @('servicebus.windows.net')
}
$services += [PSCustomObject]@{
    Id = 'sqldatabase';
    Name = 'Azure SQL Database';
    Suffixes = @('database.windows.net')
}
$services += [PSCustomObject]@{
    Id = 'stack';
    Name = 'Azure Stack Edge and Azure IoT Edge';
    Suffixes = @('azureedge.net')
}
$services += [PSCustomObject]@{
    Id = 'table';
    Name = 'Azure Table Storage';
    Suffixes = @('table.core.windows.net')
}
$services += [PSCustomObject]@{
    Id = 'trafficmanager';
    Name = 'Azure Traffic Manager';
    Suffixes = @('trafficmanager.net')
}
$services += [PSCustomObject]@{
    Id = 'websites';
    Name = 'Azure Websites';
    Suffixes = @('azurewebsites.net', 'p.azurewebsites.net')
}
$services += [PSCustomObject]@{
    Id = 'websites-scm';
    Name = 'Azure Websites - Management';
    Suffixes = @('scm.azurewebsites.net')
}

# Check if the services are available
$results = @()
$services | ForEach-Object {
    $service = $_
    $service.Suffixes | ForEach-Object {
        $suffix = $_
        $baseList | ForEach-Object {
            $base = $_.Trim()
            Write-Output "Processing: $($base); $($suffix)"
            $tmpURL = @()
            $tmpURL += "$($base).$($suffix)"
            $permutations | ForEach-Object {
                $permutation = $_.Trim()
                $tmpURL += "$($base)$($permutation).$($suffix)"
                $tmpURL += "$($base)-$($permutation).$($suffix)"
                $tmpURL += "$($base)_$($permutation).$($suffix)"
                $tmpURL += "$($permutation)$($base).$($suffix)"
                $tmpURL += "$($permutation)-$($base).$($suffix)"
                $tmpURL += "$($permutation)_$($base).$($suffix)"
            }
            $tmpResultInner = $tmpURL | ForEach-Object -Parallel {
                $requestedURL = $_.Trim()
                try {
                    $dnsResult = Resolve-DnsName -Name $requestedURL -Type A -DnsOnly -NoHostsFile -QuickTimeout
                    if ($dnsResult -and ($dnsResult.Count -gt 0) -and ($dnsResult[0].RecordData -notlike '*communications error*') -and ($dnsResult[0].RecordData -notlike '*warning*')) {
                        [PSCustomObject]@{
                            ServiceId = $using:service.Id;
                            Value = $requestedURL;
                        }
                    }
                } catch {
                    Write-Warning -Message "Failed to resolve DNS for: $($requestedURL)"
                }
            } -ThrottleLimit 10
            if ($tmpResultInner) {
                $results += $tmpResultInner
            }
        }
    }
}

Write-Output ""
Write-Output "Results:"
Write-Output ""

if ($results.Count -eq 0) {
    Write-Output "No results found."
} else {
    $outputResults = @()
    $services | ForEach-Object {
        $service = $_

        $serviceResults = $results | Where-Object { $_.ServiceId -eq $service.Id }
        if ($serviceResults.Count -gt 0) {
            Write-Output "$($service.Name)"
            $outputResults += "$($service.Name)"
            $serviceResults | ForEach-Object {
                Write-Output "$($_.Value)"
                $outputResults += "$($_.Value)"
            }
            Write-Output ""
            $outputResults += ""
        }
    }
    $outputResults | Out-File -FilePath $subdomainFilePath -Encoding UTF8
}

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
