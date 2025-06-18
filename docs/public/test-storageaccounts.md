---
description: Test Azure Storage Accounts for visible blobs
---

# test-storageaccounts.ps1

## Description

This script checks the accessibility of Azure Storage Accounts from public
and extracts information about them.

## Requirements

This script requires PowerShell v7.4 or higher.

## Parameters

### CaseName

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

### StorageAccount

Specifies the name of the storage account to test.
This parameter is mandatory for ParameterSet "Account".

### Container

Specifies the name of the container within the storage account to test.
This parameter is mandatory for ParameterSet "Account".

### FilePath

Specifies the path to the CSV file containing the list of storage accounts
to test.
This parameter is mandatory for ParameterSet "File".

Required columns in the CSV file:
* `StorageAccount`: The name of the storage account.
* `Container`: The name of the container within the storage account.

## Usage

```powershell
./scripts/public/test-storageaccounts.ps1 -CaseName "<case>" -FilePath "/path/to/storageaccounts.csv"
```

---

#### Changelog

*Version: 1.0.0*

- Initial version.
