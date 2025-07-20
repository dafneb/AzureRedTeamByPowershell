---
description: Test Azure Storage Blob containers for visible blobs
---

# test-storagecontainers.ps1

## Description

...

Results could be found at files:

- Blobs: "./case/\$CaseName/storage/\$Endpoint/\$Container/pub-blobs.csv"

Helping files (if results received):

- BlobContainer - List of blobs:  "./case/\$CaseName/storage/\$Endpoint/\$Container/blobs-list.xml"
- BlobContainer - Metadata: "./case/\$CaseName/storage/\$Endpoint/\$Container/container-metadata-headers.txt"
- BlobContainer -  Properties: "./case/\$CaseName/storage/\$Endpoint/\$Container/container-properties-headers.txt"

## Requirements

This script requires PowerShell v7.4 or higher.

## Parameters

### CaseName

*Type: `string`*

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

### ContainerEndpoints

*Type: `string[]`*

Specifies the endpoints of the Azure Storage Blobs Container to test.
This parameter is mandatory for ParameterSet "Container".

### FilePath

*Type: `string`*

Specifies the path to the CSV file containing the list of endpoints.
This parameter is mandatory for ParameterSet "File".

This file should contain the endpoints in the format `https://<account>.blob.core.windows.net/<container>` at column `Value`.
Or next option is to use columns `Endpoint` and `Container` to specify the endpoint and container name respectively. In this case, the script will construct the full endpoint URL as `https://<endpoint>/<container>`.

### CommonParameters

*Supports common parameters: `-Verbose`, `-Debug`, `-ErrorAction`, `-WarningAction`, `-InformationAction`, `-OutVariable`, `-OutBuffer`.*

## Usage

```powershell
./scripts/public/test-storagecontainers.ps1 -CaseName "<case>" -FilePath "./path/to/storage-containers.csv"
```

---

### Changelog

#### Version: 1.0.0

- Initial version.
