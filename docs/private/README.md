---
description: Internal view of resources
---

# Internal Resources

## Connection to Azure/M365/Entra ID

| Script  | Description  |
| --- | --- |
| get-armconnectionasdevice.ps1 | Connects to Azure Resource Manager with DeviceCode flow. |
| get-armconnectionasuser.ps1 | Connects to Azure Resource Manager as user. |

## Reconnaissance

### Entra ID

| Script  | Description  |
| --- | --- |
| get-entrausers.ps1 | Enumerates users in Entra ID. |

### Azure

| Script  | Description  |
| --- | --- |
| get-visibleresources.ps1 | Enumerates visible resources in Azure. |
| get-rolesassignment.ps1 | Enumerates role assignments in Azure. |

---

* get-virtualmachines.ps1 - Enumerates virtual machines in Azure
* get-storageaccounts.ps1 - Enumerates storage accounts in Azure
* get-storageblob.ps1 - Downloads a blob from a storage account
* get-keyvaults.ps1 - Enumerates key vaults in Azure
* get-storagetable.ps1 - Enumerates storage tables in Azure
