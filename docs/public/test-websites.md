---
description: Test websites for Azure Storage Accounts
---

# test-websites.ps1

## Description

The script takes a list of websites either from the command line or from
a file, checks their accessibility, and extracts information about Azure
Storage Accounts if available. The results are saved in a TXT and CSV file.

Results could be found at files:

- BlobStorageAccounts: "./case/\$CaseName/services/pub-storageblobs.txt"
- BlobContainers: "./case/\$CaseName/storage/\$Endpoint/pub-storagecontainers.csv"

## Requirements

This script requires PowerShell v7.4 or higher.

## Parameters

### CaseName

*Type: `string`*

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

### Uri

*Type: `string[]`*

Specifies the URI of the website to test.
Value could be a URL or a domain name defined as a strings array.
This parameter is mandatory for ParameterSet "Uri".

### FilePath

*Type: `string`*

Specifies the path to the text file containing the list of websites to test.
Each line is handled as a separate website URL or domain.
This parameter is mandatory for ParameterSet "File".

### CommonParameters

*Supports common parameters: `-Verbose`, `-Debug`, `-ErrorAction`, `-WarningAction`, `-InformationAction`, `-OutVariable`, `-OutBuffer`.*

## Usage

```powershell
./scripts/public/test-websites.ps1 -CaseName "<case>" -FilePath "/path/to/websites.txt"
```

---

### Changelog

#### Version: 1.0.0

- Initial version.

#### Version: 1.0.2

- Improved error handling and logging.
- Small adjustments in logic to ensure better performance and reliability.
