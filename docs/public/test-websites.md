---
description: Visible resources in Azure
---

# test-websites.ps1

## Description

The script takes a list of websites either from the command line or from
a file, checks their accessibility, and extracts information about Azure
Storage Accounts if available. The results are saved in a CSV file.

Results could be found at files:
* Resources: "./case/$CaseName/pub-storageaccounts.csv"

## Requirements

This script requires PowerShell v7.4 or higher.

## Usage

```powershell
./scripts/public/test-websites.ps1 -CaseName "<case>" -FilePath "/path/to/websites.txt"
```

---

#### Changelog

*Version: 1.0.0*

- Initial version.
