<#
.SYNOPSIS
    This script enumerates subdomains for Azure services based on provided
    base domains and optional permutations.
    It resolves DNS names and saves the results in a structured format.

.DESCRIPTION
    The script allows you to specify a case name, a list of base domains, and an optional file containing permutations.
    It resolves DNS names for various Azure services and saves the results in a case-specific directory structure.

.PARAMETER CaseName
    The name of the case, which will be used to create a directory for storing results.

.PARAMETER Base
    An array of base domains to check for subdomains.

.PARAMETER FilePath
    A file containing base domains to check for subdomains.

.PARAMETER PermutationFilePath
    An optional file containing permutations to append to the base domains.

.NOTES
    Author: David Burel (@dafneb)
    Date: July 2, 2025
    Version: 1.0.0
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

# Check if Resolve-DnsName cmdlet is available
if (-not (Get-Command -Name 'Resolve-DnsName' -ErrorAction SilentlyContinue)) {
    Write-Error -Message "The Resolve-DnsName cmdlet is not available." -Category NotInstalled
    exit
}

# Normalize case name to lowercase
$caseFolderName = $CaseName.ToLower()
$caseFolderName = $caseFolderName.Trim()
$caseFolderName = $caseFolderName -replace '[\\/:*?"<>|]', '_'

# Paths for logs and case folders
$baseFolderPath = Join-Path -Path (Get-Location) -ChildPath "case"
$caseFolderPath = Join-Path -Path $baseFolderPath -ChildPath "$($caseFolderName)"
$dnsResultsFolderPath = Join-Path -Path $caseFolderPath -ChildPath "dns-results"
$servicesFolderPath = Join-Path -Path $caseFolderPath -ChildPath "services"
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

if (-not (Test-Path -Path $dnsResultsFolderPath)) {
    Write-Verbose -Message "DNS results folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $dnsResultsFolderPath | Out-Null
} else {
    Write-Verbose -Message "DNS results folder already exists, clearing it..."
    Get-ChildItem -Path $dnsResultsFolderPath | Remove-Item -Force
}

if (-not (Test-Path -Path $servicesFolderPath)) {
    Write-Verbose -Message "Services folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $servicesFolderPath | Out-Null
} else {
    Write-Verbose -Message "Services folder already exists, clearing it..."
    Get-ChildItem -Path $servicesFolderPath | Remove-Item -Force
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
            $baseList = Get-Content -Path $FilePath
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

# Prepare hash table for services
# Reference: https://learn.microsoft.com/en-gb/azure/security/fundamentals/azure-domains
# Reference: https://github.com/yuyudhn/AzSubEnum/blob/main/azsubenum.py#L46
$services = @()
$services += [PSCustomObject]@{
    Id = 'sharepoint';
    Name = 'SharePoint';
    Suffixes = @('sharepoint.com');
    OutputFile = 'pub-sharepoint.txt'
}
$services += [PSCustomObject]@{
    Id = 'accesscontrol';
    Name = 'Azure Access Control Service (retired)';
    Suffixes = @('accesscontrol.windows.net');
    OutputFile = 'pub-accesscontrol.txt'
}
$services += [PSCustomObject]@{
    Id = 'entra';
    Name = 'Microsoft Entra ID';
    Suffixes = @('graph.windows.net', 'onmicrosoft.com');
    OutputFile = 'pub-entra.txt'
}
$services += [PSCustomObject]@{
    Id = 'apim';
    Name = 'Azure API Management';
    Suffixes = @('azure-api.net');
    OutputFile = 'pub-apim.txt'
}
$services += [PSCustomObject]@{
    Id = 'biztalk';
    Name = 'Azure BizTalk Services (retired)';
    Suffixes = @('biztalk.windows.net');
    OutputFile = 'pub-biztalk.txt'
}
$services += [PSCustomObject]@{
    Id = 'storageblobs';
    Name = 'Azure Blob storage';
    Suffixes = @('blob.core.windows.net');
    OutputFile = 'pub-storageblobs.txt'
}
$services += [PSCustomObject]@{
    Id = 'cloudapp';
    Name = 'Azure Cloud Services and Azure Virtual Machines';
    Suffixes = @('cloudapp.net', 'cloudapp.azure.com');
    OutputFile = 'pub-cloudapp.txt'
}
$services += [PSCustomObject]@{
    Id = 'containerregistries';
    Name = 'Azure Container Registry';
    Suffixes = @('azurecr.io');
    OutputFile = 'pub-containerregistries.txt'
}
$services += [PSCustomObject]@{
    Id = 'containers';
    Name = 'Azure Container Service (deprecated)';
    Suffixes = @('azurecontainer.io');
    OutputFile = 'pub-containers.txt'
}
$services += [PSCustomObject]@{
    Id = 'redis';
    Name = 'Azure Redis Cache';
    Suffixes = @('redis.cache.windows.net');
    OutputFile = 'pub-redis.txt'
}
# $services += [PSCustomObject]@{
#     Id = 'cdn';
#     Name = 'Azure Content Delivery Network (CDN)';
#     Suffixes = @('vo.msecnd.net')
# }
$services += [PSCustomObject]@{
    Id = 'cosmosdbs';
    Name = 'Azure Cosmos DB';
    Suffixes = @('cosmos.azure.com', 'documents.azure.com');
    OutputFile = 'pub-cosmosdbs.txt'
}
$services += [PSCustomObject]@{
    Id = 'storagefiles';
    Name = 'Azure Files';
    Suffixes = @('file.core.windows.net');
    OutputFile = 'pub-storagefiles.txt'
}
# $services += [PSCustomObject]@{
#     Id = 'frontdoor';
#     Name = 'Azure Front Door';
#     Suffixes = @('azurefd.net')
# }
$services += [PSCustomObject]@{
    Id = 'keyvaults';
    Name = 'Azure Key Vault';
    Suffixes = @('vault.azure.net');
    OutputFile = 'pub-keyvaults.txt'
}
$services += [PSCustomObject]@{
    Id = 'kubernetes';
    Name = 'Azure Kubernetes Service';
    Suffixes = @('azmk8s.io');
    OutputFile = 'pub-kubernetes.txt'
}
$services += [PSCustomObject]@{
    Id = 'managementservices';
    Name = 'Azure Management Services';
    Suffixes = @('management.core.windows.net');
    OutputFile = 'pub-managementservices.txt'
}
$services += [PSCustomObject]@{
    Id = 'mediaservices';
    Name = 'Azure Media Services';
    Suffixes = @('origin.mediaservices.windows.net');
    OutputFile = 'pub-mediaservices.txt'
}
$services += [PSCustomObject]@{
    Id = 'mobileapps';
    Name = 'Azure Mobile Apps';
    Suffixes = @('azure-mobile.net');
    OutputFile = 'pub-mobileapps.txt'
}
$services += [PSCustomObject]@{
    Id = 'storagequeues';
    Name = 'Azure Queue Storage';
    Suffixes = @('queue.core.windows.net');
    OutputFile = 'pub-storagequeues.txt'
}
$services += [PSCustomObject]@{
    Id = 'servicebus';
    Name = 'Azure Service Bus';
    Suffixes = @('servicebus.windows.net');
    OutputFile = 'pub-servicebus.txt'
}
$services += [PSCustomObject]@{
    Id = 'sqldatabases';
    Name = 'Azure SQL Database';
    Suffixes = @('database.windows.net');
    OutputFile = 'pub-sqldatabases.txt'
}
$services += [PSCustomObject]@{
    Id = 'stacks';
    Name = 'Azure Stack Edge and Azure IoT Edge';
    Suffixes = @('azureedge.net');
    OutputFile = 'pub-stacks.txt'
}
$services += [PSCustomObject]@{
    Id = 'storagetables';
    Name = 'Azure Table Storage';
    Suffixes = @('table.core.windows.net');
    OutputFile = 'pub-storagetables.txt'
}
$services += [PSCustomObject]@{
    Id = 'trafficmanager';
    Name = 'Azure Traffic Manager';
    Suffixes = @('trafficmanager.net');
    OutputFile = 'pub-trafficmanager.txt'
}
$services += [PSCustomObject]@{
    Id = 'websites';
    Name = 'Azure Websites';
    Suffixes = @('azurewebsites.net', 'p.azurewebsites.net');
    OutputFile = 'pub-websites.txt'
}
$services += [PSCustomObject]@{
    Id = 'websites-scm';
    Name = 'Azure Websites - Management';
    Suffixes = @('scm.azurewebsites.net');
    OutputFile = 'pub-websites-scm.txt'
}

# Check if the services are available
$results = @()
$services | ForEach-Object {
    $service = $_
    $service.Suffixes | ForEach-Object {
        $suffix = $_
        $baseList | ForEach-Object {
            $base = $_.Trim()
            if (($base -eq '') -or ($base -eq $null) -or ($base.StartsWith('#'))) {
                return
            }
            Write-Output "Processing: $($base); $($suffix)"
            $tmpURL = @()
            $tmpURL += "$($base).$($suffix)"
            $permutations | ForEach-Object {
                $permutation = $_.Trim()
                if (($permutation -eq '') -or ($permutation -eq $null) -or ($permutation.StartsWith('#'))) {
                    return
                }
                $tmpURL += "$($base)$($permutation).$($suffix)"
                $tmpURL += "$($base)-$($permutation).$($suffix)"
                $tmpURL += "$($base)_$($permutation).$($suffix)"
                $tmpURL += "$($permutation)$($base).$($suffix)"
                $tmpURL += "$($permutation)-$($base).$($suffix)"
                $tmpURL += "$($permutation)_$($base).$($suffix)"
            }
            Write-Verbose "List of URLs to check contains $($tmpURL.Count) items"
            $tmpResultInner = $tmpURL | ForEach-Object -Parallel {
                $VerbosePreference = $using:VerbosePreference
                $DebugPreference = $using:DebugPreference
                $requestedURL = $_.Trim()
                try {
                    $meas = Measure-Command {
                        $dnsResult = Resolve-DnsName -Name $requestedURL -Type A -DnsOnly -NoHostsFile -QuickTimeout
                    }
                    Write-Verbose -Message "DNS resolution for: $($requestedURL) took $($meas.TotalSeconds) seconds"
                    Write-Debug -Message "DNS resolution for: $($requestedURL) took $($meas.TotalSeconds) seconds"
                    if ($dnsResult) {
                        Write-Verbose -Message "DNS resolved for: $($requestedURL):"
                        Write-Verbose -Message ($dnsResult | Out-String)
                        Write-Debug -Message "DNS resolved for: $($requestedURL):"
                        Write-Debug -Message ($dnsResult | Out-String)
                    } else {
                        Write-Verbose -Message "DNS resolution failed for: $($requestedURL)"
                        Write-Debug -Message "DNS resolution failed for: $($requestedURL)"
                    }
                    if ($dnsResult -and $DebugPreference -eq 'Continue') {
                        $dnsResult | Out-File -FilePath "$($using:dnsResultsFolderPath)\$($requestedURL)-dns.txt" -Append -Encoding UTF8
                    }
                    if ($dnsResult -and ($dnsResult.Count -gt 0) -and ($dnsResult[0].RecordData -notlike '*communications error*') -and ($dnsResult[0].RecordData -notlike '*warning*')) {
                        [PSCustomObject]@{
                            ServiceId = $using:service.Id;
                            Value = $requestedURL;
                        }
                    } elseif ($dnsResult -and ($dnsResult.Count -gt 0) -and ($dnsResult[0].RecordData -like '*communications error*')) {
                        Write-Warning -Message "Communications error for: $($requestedURL)"
                    }
                } catch {
                    Write-Warning -Message "Failed to resolve DNS for: $($requestedURL)"
                    Write-Warning -Message $_
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
            $tmpServiceResults = @()
            $serviceResults | ForEach-Object {
                Write-Output "$($_.Value)"
                $outputResults += "$($_.Value)"
                $tmpServiceResults += $_.Value
            }
            Write-Output ""
            $outputResults += ""
            if ($service.OutputFile) {
                $tmpServiceResults | Out-File -FilePath (Join-Path -Path $servicesFolderPath -ChildPath $service.OutputFile) -Encoding UTF8
            }
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
