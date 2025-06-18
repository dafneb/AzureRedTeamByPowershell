---
description: Visible resources in Azure
---

# get-visibleresources.ps1

## Description

This script enumerates resources in Azure that are visible to the authenticated
user. It retrieves information about various Azure resources such as virtual
machines, storage accounts, key vaults, and more.

The script is going through tenants and subscriptions, collecting information
about resources.

Results could be found at files:
* Resources: "./case/$CaseName/$Identity/resources.csv"
* Domains: "./case/$CaseName/domains.txt"

## Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

## Parameters

### CaseName

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

## Usage

```powershell
./scripts/private/get-visibleresources.ps1 -CaseName "<case>"
```

---

#### Changelog

*Version: 1.0.0*

- Initial version.

*Version: 1.1.0*

- Added support for multiple tenants.
- Added support for multiple subscriptions.
