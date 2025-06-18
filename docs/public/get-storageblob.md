---
description: Download visible blobs
---

# get-storageblob.ps1

## Description

This script downloads visible blobs from Azure Storage Accounts that
are publicly accessible.

Results could be found at files:
* Blobs: "./case/$CaseName/$StorageAccount/$Container/blobs[/$VersionId]/$Blob"

## Requirements

This script requires PowerShell v7.4 or higher.

## Parameters

### CaseName

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

### StorageAccount

Specifies the name of the storage account to test.
This parameter is mandatory for ParameterSet "Blob".
This parameter is mandatory for ParameterSet "VersionId".

### Container

Specifies the name of the container within the storage account to test.
This parameter is mandatory for ParameterSet "Blob".
This parameter is mandatory for ParameterSet "VersionId".

### Blob

Specifies the name of the blob to download.
This parameter is mandatory for ParameterSet "Blob".
This parameter is mandatory for ParameterSet "VersionId".

### VersionId

Specifies the version of the blob to download.
This parameter is mandatory for ParameterSet "VersionId".

### FilePath

Specifies the path to the CSV file containing the list of storage blobs
to download.
This parameter is mandatory for ParameterSet "File".

Required columns in the CSV file:
* `StorageAccount`: The name of the storage account.
* `Container`: The name of the container within the storage account.
* `BlobName`: The name of the blob to download.
* `VersionId`: The version of the blob to download.

## Usage

```powershell
./scripts/public/get-storageblob.ps1 -CaseName "<case>" -StorageAccount "<storage>" -Container "<container>" -Blob "<blob>" -VersionId "<version>"
```

```powershell
./scripts/public/get-storageblob.ps1 -CaseName "<case>" -FilePath "/path/to/blobs.csv"
```

---

#### Changelog

*Version: 1.0.0*

- Initial version.
