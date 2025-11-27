<#
.NOTES
    Author: David Burel (@dafneb)
    Date: August 25, 2025
    Version: 1.0.0
#>

# Define the script's parameters
[CmdletBinding(DefaultParameterSetName = "Default")]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Default")]
    [ValidateNotNullOrEmpty()]
    [string]$CaseName
)

# -------------- [ Functions ] ------------------------------------------
function Get-ManagementGroupDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        HelpMessage="Management group name.")]
        [ValidateNotNullOrEmpty()]
        [string] $ManagementGroupName,

        [Parameter(Mandatory=$true,
        HelpMessage="String prefix.")]
        [ValidateNotNullOrEmpty()]
        [string] $StringPrefix
    )

    $strReturn = @()
    $strPrefix = $StringPrefix
    $strPrefixNext = "$($strPrefix)`t"

    $mg = Get-AzManagementGroup -GroupName $ManagementGroupName -Expand -ErrorAction SilentlyContinue

    if ($mg) {
        $strReturn += "$($strPrefix)Management Group: $($mg.Name) ($($mg.Id))"

        $mg.Children | ForEach-Object {
            if ($_.Type -eq "Microsoft.Management/managementGroups") {
                $strReturn += Get-ManagementGroupDetails -ManagementGroupName $_.Name -Prefix $strPrefixNext
            } elseif ($_.Type -eq "Microsoft.Management/managementGroups/subscriptions") {
                $strReturn += "$($strPrefixNext)Subscription: $($_.DisplayName) ($($_.Name))"
            } else {
                $strReturn += "$($strPrefixNext)Unknown Type: $($_.Type) - Name: $($_.Name) - DisplayName: $($_.DisplayName)"
            }
        }
    }

    return $strReturn
}
# -----------------------------------------------------------------------

$timeStart = Get-Date

Write-Output "***********************************************************"
Write-Output "*********** Get information about tenants *****************"
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
$tenantsFilePath = Join-Path -Path $accountFolderPath -ChildPath "tenants.csv"
$subscriptionsFilePath = Join-Path -Path $accountFolderPath -ChildPath "subscriptions.csv"
$domainsFilePath = Join-Path -Path $accountFolderPath -ChildPath "domains.txt"
$treeViewFilePath = Join-Path -Path $accountFolderPath -ChildPath "tree-view.txt"
$cspmFilePath = Join-Path -Path $accountFolderPath -ChildPath "defender-cspm.csv"

Write-Verbose -Message "Checking folders (2/2) ..."

# Create account folder if it doesn't exist
if (-not (Test-Path -Path $accountFolderPath)) {
    Write-Verbose -Message "Case folder does not exist, creating it..."
    New-Item -ItemType Directory -Path $accountFolderPath | Out-Null
}

# Create tenants file if it doesn't exist
if (-not (Test-Path -Path $tenantsFilePath)) {
    Write-Verbose -Message "Tenants file does not exist, creating it..."
    New-Item -ItemType File -Path $tenantsFilePath | Out-Null
} else {
    Write-Verbose -Message "Tenants file already exists, clearing it..."
    Clear-Content -Path $tenantsFilePath
}

# Create domains file if it doesn't exist
if (-not (Test-Path -Path $domainsFilePath)) {
    Write-Verbose -Message "Domains file does not exist, creating it..."
    New-Item -ItemType File -Path $domainsFilePath | Out-Null
} else {
    Write-Verbose -Message "Domains file already exists, clearing it..."
    Clear-Content -Path $domainsFilePath
}

# Create subscriptions file if it doesn't exist
if (-not (Test-Path -Path $subscriptionsFilePath)) {
    Write-Verbose -Message "Subscriptions file does not exist, creating it..."
    New-Item -ItemType File -Path $subscriptionsFilePath | Out-Null
} else {
    Write-Verbose -Message "Subscriptions file already exists, clearing it..."
    Clear-Content -Path $subscriptionsFilePath
}

# Create tree view file if it doesn't exist
if (-not (Test-Path -Path $treeViewFilePath)) {
    Write-Verbose -Message "Tree view file does not exist, creating it..."
    New-Item -ItemType File -Path $treeViewFilePath | Out-Null
} else {
    Write-Verbose -Message "Tree view file already exists, clearing it..."
    Clear-Content -Path $treeViewFilePath
}

# Create CSPM file if it doesn't exist
if (-not (Test-Path -Path $cspmFilePath)) {
    Write-Verbose -Message "CSPM file does not exist, creating it..."
    New-Item -ItemType File -Path $cspmFilePath | Out-Null
} else {
    Write-Verbose -Message "CSPM file already exists, clearing it..."
    Clear-Content -Path $cspmFilePath
}

Write-Verbose -Message "Getting data from Azure ..."

# Prepare data containers
$dataTenants = @()
$dataSubscriptions = @()
$dataDomains = @()
$dataTreeView = @()
$dataCspm = @()

# Get information about the tenants, subscriptions, domains, and management groups
$tenants = Get-AzTenant -ErrorAction SilentlyContinue
if (-not $tenants) {
    Write-Warning -Message "No tenants found, please check your connection"
}
$tenants | ForEach-Object {
    $tenant = Get-AzTenant -TenantId $_.Id
    Write-Output "Tenant ID: $($tenant.Id); Tenant Name: $($tenant.Name)"
    $dataTreeView += "Tenant: $($tenant.Name) ($($tenant.Id))"

    $tenantExtendedProperties = @()
    if ($tenant.ExtendedProperties) {
        $tenant.ExtendedProperties.GetEnumerator() | ForEach-Object {
            if (($_.Key -eq "Domains") -or ($_.Key -eq "TenantBrandingLogoUrl") -or ($_.Key -eq "TenantCategory") -or ($_.Key -eq "TenantType") -or ($_.Key -eq "DefaultDomain")) {
                return
            }
            $tenantExtendedProperties += "$($_.Key): $($_.Value)"
        }
    }

    $dataTenants += [PSCustomObject]@{
        Id = $tenant.Id;
        Name = $tenant.Name;
        Country = $tenant.Country;
        CountryCode = $tenant.CountryCode;
        DefaultDomain = $tenant.DefaultDomain;
        ExtendedProperties = $tenantExtendedProperties -join '; ';
        TenantBrandingLogoUrl = $tenant.TenantBrandingLogoUrl;
        TenantCategory = $tenant.TenantCategory;
        TenantType = $tenant.TenantType;
    }

    $tenant.Domains | ForEach-Object {
        $dataDomains += $_
    }

    $subscriptions = Get-AzSubscription -TenantId $tenant.Id -ErrorAction SilentlyContinue
    if (-not $subscriptions) {
        Write-Warning -Message "No subscriptions found for tenant: $($tenant.Name)"
    } else {

        $tenantSubscriptions = @()
        $subscriptions | ForEach-Object {
            $subscription = $_
            Write-Output "Subscription ID: $($subscription.Id); Subscription Name: $($subscription.Name); Subscription State: $($subscription.State)"
            $tenantSubscriptions += "`tSubscription: $($subscription.Name) ($($subscription.Id)) - State: $($subscription.State)"

            $subscriptionTags = @()
            if ($subscription.Tags) {
                $subscription.Tags.GetEnumerator() | ForEach-Object {
                    $subscriptionTags += "$($_.Key): $($_.Value)"
                }
            }
            $subscriptionExtended = @()
            if ($subscription.ExtendedProperties) {
                $subscription.ExtendedProperties.GetEnumerator() | ForEach-Object {
                    if (($_.Key -eq "SubscriptionPolices") -or ($_.Key -eq "Tags") -or ($_.Key -eq "Account")) {
                        return
                    }
                    $subscriptionExtended += "$($_.Key): $($_.Value)"
                }
            }
            $subscriptionPolicies = @()
            if ($subscription.SubscriptionPolicies) {
                $subscriptionPolicies += "LocationPlacementId: $($subscription.SubscriptionPolicies.LocationPlacementId)"
                $subscriptionPolicies += "QuotaId: $($subscription.SubscriptionPolicies.QuotaId)"
                $subscriptionPolicies += "SpendingLimit: $($subscription.SubscriptionPolicies.SpendingLimit)"
            }
            $dataSubscriptions += [PSCustomObject]@{
                Id = $subscription.Id;
                Name = $subscription.Name;
                State = $subscription.State;
                Tags = $subscriptionTags -join '; ';
                ExtendedProperties = $subscriptionExtended -join '; ';
                Policies = $subscriptionPolicies -join '; ';
                TenantId = $tenant.Id;
                TenantName = $tenant.Name;
            }

            # Skip if the subscription is disabled
            if ($subscription.State -eq "Disabled") {
                Write-Warning -Message "Subscription $($subscription.Name) ($($subscription.Id)) is Disabled, skipping ..."
                return
            }

            # Switch to subscription context for getting more details ... 
            Set-AzContext -SubscriptionId $subscription.Id -TenantId $tenant.Id | Out-Null
            if (-not (Get-AzContext)) {
                Write-Warning -Message "Failed to set context for subscription $($subscription.Name) ($($subscription.Id))"
                return
            }

            # Get CSPM details
            # Get Defender CSPM settings for the subscription
            $cspmSettings = Get-AzSecurityPricing -ErrorAction SilentlyContinue
            $cspmSettings | ForEach-Object {
                $cspmSetting = $_
                $dataCspm += [PSCustomObject]@{
                    TenantId = "$($tenant.Id)";
                    TenantName = "$($tenant.Name)";
                    SubscriptionId = "$($subscription.Id)";
                    SubscriptionName = "$($subscription.Name)";
                    PricingId = "$($cspmSetting.Id)";
                    PricingTier = "$($cspmSetting.PricingTier)";
                    PricingSubPlan = "$($cspmSetting.SubPlan)";
                    PricingExtensions = "$(($cspmSetting.Extensions | Out-String).Trim())";
                }
            }

        }

        # Check if Tenant is using management groups and get 'Root Tenant Group'
        # This one has to be after checking of subscriptions!!
        Write-Output "Checking management groups for tenant ..."
        $rootGroup = Get-AzManagementGroup -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "$($tenant.Id)" } | Select-Object Id, Name
        if ($rootGroup) {
            $dataTreeView += Get-ManagementGroupDetails -ManagementGroupName $rootGroup.Name -Prefix "`t"
        } else {
            $dataTreeView += "`tManagement Group: Not Found (or no access)"
            $dataTreeView += $tenantSubscriptions
        }

    }

}

# Export the resource details to a CSV file
Write-Output "Saving data ..."

$dataTenants | Export-Csv -Path $tenantsFilePath -NoTypeInformation -Encoding UTF8
$dataSubscriptions | Export-Csv -Path $subscriptionsFilePath -NoTypeInformation -Encoding UTF8
$dataDomains | Out-File -FilePath $domainsFilePath -Encoding UTF8
$dataTreeView | Out-File -FilePath $treeViewFilePath -Encoding UTF8
$dataCspm | Export-Csv -Path $cspmFilePath -NoTypeInformation -Encoding UTF8

# Get actual date and time ...
$timeEnd = Get-Date

# Printout date&times ...
Write-Output "***********************************************************"
Write-Output "Started: $($timeStart)"
Write-Output "Finished: $($timeEnd)"
Write-Output "Elapsed time: $($timeEnd - $timeStart)"
