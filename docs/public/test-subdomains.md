---
description: Enumerate subdomains and recognize Azure resources
---

# test-subdomains.ps1

## Description

The script was designed to enumerate subdomains and recognize Azure resources.
It takes a list of bases either from the command line or from a file,
checks their accessibility.

You are able to enrich the list of subdomains with the list of words for
permutations.

Results could be found at files:
* Subdomains: "./case/$CaseName/pub-subdomains.txt"

{% hint style="warning" %}
**Warning:** This script does not perform any brute-force attacks or
dictionary attacks. It simply checks the accessibility of the provided
subdomains via DNS request. It is intended for legitimate use only,
such as security assessments, penetration testing, or reconnaissance.
Results has to be confirmed with owner before next steps.
{% endhint %}

This script is inspired by the [AzSubEnum](https://github.com/yuyudhn/AzSubEnum) which was used as a reference for the
implementation of the subdomain enumeration logic.

## Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Resolve-DnsName* PowerShell cmdlet.

To install the *Resolve-DnsName* cmdlet, run the following command which
will find the exact module that contains the cmdlet:

```powershell
Find-Command -Repository PSGallery -Name Resolve-DnsName
```

## Parameters

### CaseName

Specifies the case's name for which the user data will be retrieved.
This parameter is mandatory for all ParameterSets.

### Base

Specifies a base subdomain to test.
This parameter is mandatory for ParameterSet "Base".

### FilePath

Specifies the path to the file containing the list of bases.
This parameter is mandatory for ParameterSet "File".

### PermutationFilePath

Specifies the path to the file containing the list of words for permutations.
This parameter is optional for all ParameterSets.

## Usage

```powershell
./scripts/public/test-subdomains.ps1 -CaseName "<case>" -FilePath "/path/to/bases.txt"
```

```powershell
./script/public/test-subdomains.ps1 -CaseName "<case>" -FilePath "/path/to/bases.txt" -PermutationFilePath "/path/to/permutations.txt"
```

---

#### Changelog

*Version: 1.0.0*

- Initial version.
