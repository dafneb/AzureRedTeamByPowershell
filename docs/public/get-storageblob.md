---
description: Download visible blobs
---

# get-storageblob.ps1

## Description

This script downloads visible blobs from Azure Storage Accounts that
are publicly accessible.

Results could be found at files:

- Blobs: "./case/\$CaseName/storage/\$Endpoint/\$Container/blobs[/\$VersionId]/\$Blob"

## Requirements

This script requires PowerShell v7.4 or higher.

## Parameters

### CaseName

*Type: `string`*

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

### ContainerEndpoints

*Type: `string`*

Specifies the endpoints of the Azure Storage Blobs Container to test.
This parameter is mandatory for ParameterSet "Blob".
This parameter is mandatory for ParameterSet "VersionId".

### Blob

*Type: `string`*

Specifies the name of the blob to download.
This parameter is mandatory for ParameterSet "Blob".
This parameter is mandatory for ParameterSet "VersionId".

### VersionId

*Type: `string`*

Specifies the version of the blob to download.
This parameter is mandatory for ParameterSet "VersionId".

### FilePath

*Type: `string`*

Specifies the path to the CSV file containing the list of storage blobs
to download.
This parameter is mandatory for ParameterSet "File".

This file should contain the endpoints in the format `https://<account>.blob.core.windows.net/<container>` at column `Value`, also including the `BlobName` and `VersionId` columns.
Or next option is to use columns `Endpoint`, `Container`, `BlobName`, and `VersionId` to specify the endpoint, container name, blob name, and version ID respectively. In this case, the script will construct the full endpoint URL as `https://<endpoint>/<container>/<blob>?versionId=<versionId>`.

### CommonParameters

*Supports common parameters: `-Verbose`, `-Debug`, `-ErrorAction`, `-WarningAction`, `-InformationAction`, `-OutVariable`, `-OutBuffer`.*

## Usage

```powershell
./scripts/public/get-storageblob.ps1 -CaseName "<case>" -FilePath "/path/to/blobs.csv"
```

---

### Changelog

#### Version: 1.0.0

- Initial version.
