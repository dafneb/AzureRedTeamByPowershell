---
description: Test websites for Azure Storage Accounts
---

# test-websites.ps1

## Description

The script takes a list of websites either from the command line or from
a file, checks their accessibility, and extracts information about Azure
Storage Accounts if available. The results are saved in a CSV file.

Results could be found at files:
* StorageAccounts: "./case/$CaseName/pub-storageaccounts.csv"

## Requirements

This script requires PowerShell v7.4 or higher.

## Parameters

### CaseName

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

### Uri

Specifies the URI of the website to test.
Value could be a URL or a domain name defined as a strings array.
This parameter is mandatory for ParameterSet "Uri".

### FilePath

Specifies the path to the text file containing the list of websites to test.
Each line is handled as a separate website URL or domain.
This parameter is mandatory for ParameterSet "File".

## Usage

```powershell
./scripts/public/test-websites.ps1 -CaseName "<case>" -FilePath "/path/to/websites.txt"
```

---

#### Changelog

*Version: 1.0.0*

- Initial version.
