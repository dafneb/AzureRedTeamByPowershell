---
description: Possible connections to Azure/M365/Entra ID
---

# Connections to Azure/M365/Entra ID

## Connections to Azure

Connections to Azure can be established using different methods depending on
the context and requirements. Below are the scripts available for connecting
to Azure Resource Manager (ARM).

### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Az* PowerShell module.

To install the *Az* PowerShell module, run the following command:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

### Scripts

- get-armconnectionasuser.ps1 -> Connects to Azure Resource Manager as a user.
- get-armconnectionasdevice.ps1 -> Connects to Azure Resource Manager as a device.
- get-armconnectionasservices.ps1 -> Connects to Azure Resource Manager as a service.

## Connections to M365/Entra ID

Connections to Microsoft 365 and Entra ID can be established using the
*Microsoft.Graph* PowerShell module. This module provides a unified way to
interact with Microsoft 365 services, including Entra ID.

### Requirements

This script requires PowerShell v7.4 or higher.
This script requires *Microsoft.Graph* PowerShell module.

To install the *Microsoft.Graph* PowerShell module, run the following command:

```powershell
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
```

### Scripts
