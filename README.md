# Red Team Toolings - Entra ID & Azure

## Scripts organization

- ./scripts/private -> Scripts for usage when you have access to the target environment.
- ./scripts/public -> Scripts for usage against the target environment without access (e.g. from the internet via service's endpoints).

## Scripts at "private" folder

### get-entrausers.ps1

This script will connect to Entra ID via Microsoft Graph. Then it will try to list all users at directory and save their UPN, Id and name at file.

It will also try to read *custom security attributes*.

Results could be found at file: "./case/<domain>/entrausers.txt"

#### Requirements

This script require *Microsoft.Graph* PowerShell module.

To install the *Microsoft.Graph* PowerShell module, run the following command:

```powershell
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
```

#### Usage

```powershell
./scripts/private/get-entrausers.ps1 -Domain "<domain>"
```

#### Changelog

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
