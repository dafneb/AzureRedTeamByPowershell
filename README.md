# Red Team Toolings - M365 & Entra ID & Azure via PowerShell

This repository contains a set of PowerShell scripts to help red teamers and pentesters to enumerate and test Microsoft 365, Entra ID and Azure environments.

## Scripts organization

- ./scripts/private -> Scripts for usage when you have access to the target environment.
- ./scripts/public -> Scripts for usage against the target environment without access (e.g. from the internet via service's endpoints).

## Scripts at "private" folder

### get-entrausers.ps1

This script will connect to Entra ID via Microsoft Graph. Then it will try to list all users at directory and save their UPN, Id and name at file.

It will also try to read *custom security attributes*.

Results could be found at file: "./case/$CaseName/entrausers.txt"

#### Requirements

This script requires *Microsoft.Graph* PowerShell module.

To install the *Microsoft.Graph* PowerShell module, run the following command:

```powershell
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

```powershell
./scripts/private/get-entrausers.ps1 -CaseName "<domain>"
```

#### Changelog

*Version: 1.0.0*

- Initial version.
- Added support to read *custom security attributes*.

### get-rolesassignment.ps1

Results could be found at file: "./case/<domain>/<account>/rolesassignment.csv"

#### Requirements

#### Usage

```powershell
./scripts/private/get-rolesassignment.ps1 -Domain "<domain>"
```

#### Changelog

### get-visibleresources.ps1

#### Requirements

#### Usage

#### Changelog

### get-virtualmachines.ps1

#### Requirements

#### Usage

#### Changelog

### get-storageaccounts.ps1

#### Requirements

#### Usage

#### Changelog

### get-storageblob.ps1

#### Requirements

#### Usage

#### Changelog

## Scripts at "public" folder

### test-websites.ps1

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

### xxx

#### Requirements

#### Usage

#### Changelog

### xxx

#### Requirements

#### Usage

#### Changelog
