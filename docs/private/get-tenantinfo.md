---
description: Get tenant information in Azure
---

# get-tenantinfo.ps1

## Description

This script retrieves tenant information in Azure.
It enumerates tenants, domains, provides a tree view of the tenant structure, and information about CSPM.

Results could be found at files:

- Tenants: "./case/\$CaseName/\$Upn/tenants.csv"
- Subscriptions: "./case/\$CaseName/\$Upn/subscriptions.csv"
- Domains: "./case/\$CaseName/\$Upn/domains.txt"
- Tree view: "./case/\$CaseName/\$Upn/tree-view.txt"
- CSPM: "./case/\$CaseName/\$Upn/defender-cspm.csv"

## Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

## Parameters

### CaseName

*Type: `string`*

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

### CommonParameters

*Supports common parameters: `-Verbose`, `-Debug`, `-ErrorAction`, `-WarningAction`, `-InformationAction`, `-OutVariable`, `-OutBuffer`.*

## Usage

```powershell
./scripts/private/get-tenantinfo.ps1 -CaseName "<case>"
```

---

### Changelog

#### Version: 1.0.0

- Initial version.
