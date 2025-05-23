# Red Team Toolings - M365 & Entra ID & Azure via PowerShell

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](https://github.com/dafneb/.github/blob/main/.github/CODE_OF_CONDUCT.md)
[![License](https://img.shields.io/badge/License-MIT-4baaaa.svg)](https://github.com/dafneb/.github/blob/main/LICENSE)
![GitHub commit activity](https://img.shields.io/github/commit-activity/w/dafneb/AzureRedTeamByPowershell)
![GitHub contributors](https://img.shields.io/github/contributors/dafneb/AzureRedTeamByPowershell)

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/dafneb/AzureRedTeamByPowershell/codeql.yml?label=CodeQL)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/dafneb/AzureRedTeamByPowershell/powershell-analyzer.yml?label=PSScriptAnalyzer)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/dafneb/AzureRedTeamByPowershell/main.svg)](https://results.pre-commit.ci/latest/github/dafneb/AzureRedTeamByPowershell/main)

This repository contains a set of PowerShell scripts to help red teamers and pentesters to enumerate and test Microsoft 365, Entra ID and Azure environments.

## Scripts organization

- ./scripts/private -> Scripts for usage when you have access to the target environment.
- ./scripts/public -> Scripts for usage against the target environment without access (e.g. from the internet via service's endpoints).

## Disclaimer

Scripts are provided for educational purposes only. Use them at your own risk.
The author is not responsible for any damage caused by the use of these scripts.
Please ensure you have permission to test the target environment before
using these scripts.

## Scripts at "private" folder

### get-entrausers.ps1

This script will connect to Entra ID via Microsoft Graph. Then it will try to list all users at directory and save their UPN, Id and name at file.

It will also try to read *custom security attributes*.

Results could be found at file: "./case/$CaseName/entrausers.txt"

#### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Microsoft.Graph* PowerShell module.

To install the *Microsoft.Graph* PowerShell module, run the following command:

```powershell
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

```powershell
./scripts/private/get-entrausers.ps1 -CaseName "<case>"
```

#### Changelog

*Version: 1.0.0*

- Initial version.
- Added support to read *custom security attributes*.

### get-rolesassignment.ps1

This script will connect to Azure via Az PowerShell module. Then it will try to list all user's role assignment.

Results could be found at file: "./case/$CaseName/$Identity/rolesassignment.csv"

#### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

```powershell
./scripts/private/get-rolesassignment.ps1 -CaseName "<case>"
```

#### Changelog

*Version: 1.0.0*

- Initial version.

### get-visibleresources.ps1

This script will connect to Azure via Az PowerShell module. Then it will try to list all visible resources.

Results could be found at file: "./case/$CaseName/$Identity/resources.csv"

#### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

```powershell
./scripts/private/get-visibleresources.ps1 -CaseName "<case>"
```

#### Changelog

*Version: 1.0.0*

- Initial version.

### get-virtualmachines.ps1

This script will connect to Azure via Az PowerShell module. Then it will try to list all visible virtual machines.

Results could be found at file: "./case/$CaseName/$Identity/virtualmachines.csv"

#### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

```powershell
./scripts/private/get-virtualmachines.ps1 -CaseName "<case>"
```

#### Changelog

*Version: 1.0.0*

- Initial version.

### get-storageaccounts.ps1

This script will connect to Azure via Az PowerShell module. Then it will try to list all visible storage accounts, containers and blobs.

Results could be found at file: "./case/$CaseName/$Identity/storageaccounts.txt"

#### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

```powershell
./scripts/private/get-storageaccounts.ps1 -CaseName "<case>"
```

#### Changelog

*Version: 1.0.0*

- Initial version.

### get-storageblob.ps1

This script will connect to Azure via Az PowerShell module. Then it will try to download a blob from a storage account.

Results could be found at file: "./case/$CaseName/blobs/$Blob"

#### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

```powershell
./scripts/private/get-storageblob.ps1 -CaseName "<case>" -StorageAccount "<storage-account>" -Container "<container-name>" -Blob "<blob-name>" [-VersionId "<version-id>"]
```

#### Changelog

*Version: 1.0.0*

- Initial version.

### get-keyvaults.ps1

This script will connect to Azure via Az PowerShell module. Then it will try to list all visible keyvaults.

Results could be found at file: "./case/$CaseName/$Identity/keyvaults.txt"

#### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

```powershell
./scripts/private/get-keyvaults.ps1 -CaseName "<case>"
```

#### Changelog

*Version: 1.0.0*

- Initial version.

### get-storagetable.ps1

It's not working at this [moment](https://github.com/paulomarquesc/AzureRmStorageTable/issues/76).

After this issue is fixed, this script will be finished and tested on [Pwned Labs](https://pwnedlabs.io/labs/unlock-access-with-azure-key-vault)

Instead of this you can use Azure CLI

```bash
az storage entity query --table-name <table> --account-name <account> --output table --auth-mode login
```

#### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.
This script requires *AzTable* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

To install the *AzTable* PowerShell module, run the following command:

```powershell
Install-Module -Name AzTable -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

#### Changelog

### xxx

#### Requirements

#### Usage

#### Changelog

### xxx

#### Requirements

#### Usage

#### Changelog

### xxx

#### Requirements

#### Usage

#### Changelog

## Scripts at "public" folder

### test-websites.ps1

This script will test websites given as parameter $Uri or as content of file located at $FilePath.
It will also try to read the content of the website and check if it contains any references to storage accounts or blob containers.

Results could be found at file: "./case/$CaseName/storageaccounts.csv"
Results could be used as input for the script [test-storageaccounts.ps1](#test-storageaccountsps1).

#### Requirements

This script requires PowerShell v7.4 or higher.

#### Usage

**This script will test websites given as parameter $Uri**

```powershell
./scripts/public/test-websites.ps1 -CaseName "<case>" -Uri "<website-uri>"
```

**This script will test websites given as content of file located at $FilePath**

Each line of the file will be treated as a website to test.
The file should contain one website per line.
It's usable as batch testing of websites.
The file should be in UTF-8 format.

```powershell
./scripts/public/test-websites.ps1 -CaseName "<case>" -FilePath "<path-to-file>"
```

#### Changelog

*Version: 1.0.0*

- Initial version.

### test-storageaccounts.ps1

This script will test storage accounts given as parameters $StorageAccount and $Container or as content of file located at $FilePath.
It will try to list all blobs in the container.

Results could be found at file: "./case/$CaseName/blobs.csv"
Partial results could be found at file: "./case/$CaseName/$Endpoint/$Container/blobs.xml"

#### Requirements

This script requires PowerShell v7.4 or higher.

#### Usage

**This script will test storage account given as parameters**

```powershell
./scripts/public/test-storageaccounts.ps1 -CaseName "case" -StorageAccount "storage-account" -Container "container"
```

**This script will test storage accounts as content of file located at $FilePath**

File has to be "comma-separated" values file.
This should have at least 2 columns: *StorageAccount* and *Container*.
The file should contain one storage account and container per line.
It's usable as batch testing of storage accounts.
The file should be in UTF-8 format.
Usable as input file could be results from [test-websites.ps1](#test-websitesps1).

```powershell
./scripts/public/test-storageaccounts.ps1 -CaseName "case" -FilePath "path-to-file"
```

#### Changelog

*Version: 1.0.0*

- Initial version.

### get-storageblob.ps1

Script for downloading a blob from a storage account.
It's downloading publicly accessible blobs.

Results could be found at folder: "./case/$CaseName/$Endpoint/$Container[/$VersionId]/$Blob"

#### Requirements

This script requires PowerShell v7.4 or higher.

#### Usage

**This script will download blob given as parameters**

```powershell
./scripts/public/get-storageblob.ps1 -CaseName "case" -StorageAccount "storage-account" -Container "container-name" -Blob "blob-name" [-VersionId "version-id"]
```

**This script will download blobs as content of file located at $FilePath**

File has to be "comma-separated" values file.
This should have at least 4 columns: *StorageAccount*, *Container*, *Blob* and *VersionId*.
It's usable as batch downloading of blobs.
The file should be in UTF-8 format.
Usable as input file could be results from [test-storageaccounts.ps1](#test-storageaccountsps1).

```powershell
./scripts/public/get-storageblob.ps1 -CaseName "case" -FilePath "path-to-file"
```

#### Changelog

*Version: 1.0.0*

- Initial version.

### xxx

#### Requirements

#### Usage

#### Changelog

### xxx

#### Requirements

#### Usage

#### Changelog
