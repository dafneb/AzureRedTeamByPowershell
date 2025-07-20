---
description: Test Azure Storage Blob Accounts for visible containers
---

# test-storageblobs.ps1

## Description

This script tests Azure Storage Blob Accounts for visible containers and retrieves information about them. It's trying to reach list of containers from the specified endpoints and saves the results in a CSV file.

You are also able to try permutations of the endpoints with a list of words from a file, which can be useful for testing various combinations of endpoints and container names. This option could be used also for guessing names of containers.

Results could be found at files:

- BlobContainers: "./case/\$CaseName/storage/\$Endpoint/pub-storagecontainers.csv"

Helping files (if results received):

- BlobStorage - Account Information:  "./case/\$CaseName/storage/\$Endpoint/account-information.xml"
- BlobStorage - Service Properties: "./case/\$CaseName/storage/\$Endpoint/service-properties.xml"
- BlobStorage - Service Stats: "./case/\$CaseName/storage/\$Endpoint/service-stats.xml"
- BlobStorage - List Containers: "./case/\$CaseName/storage/\$Endpoint/list-containers.xml"

## Requirements

This script requires PowerShell v7.4 or higher.

## Parameters

### CaseName

*Type: `string`*

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

### BlobEndpoints

*Type: `string[]`*

Specifies the endpoints of the Azure Storage Blobs to test.
This parameter is mandatory for ParameterSet "Blob".

### FilePath

*Type: `string`*

Specifies the path to the file containing the list of endpoints.
Each line is handled as a separate value.
This parameter is mandatory for ParameterSet "File".

### PermutationFilePath

*Type: `string`*

Specifies the path to the file containing the list of words for permutations.
This parameter is mandatory for all ParameterSets.

### CommonParameters

*Supports common parameters: `-Verbose`, `-Debug`, `-ErrorAction`, `-WarningAction`, `-InformationAction`, `-OutVariable`, `-OutBuffer`.*

## Usage

```powershell
./scripts/public/test-storageblobs.ps1 -CaseName "<case>" -FilePath "/path/to/storage-blobs.txt"
```

---

### Changelog

#### Version: 1.0.0

- Initial version.
