---
description: Publicly available resources
---

# Public Resources

| Script  | Description  |
| :--- | :--- |
| test-subdomains.ps1 | Creates list of possible subdomains for a given bases. It's possible also add custom wordlist for permutations. |
| test-websites.ps1 | Tests a list of websites for accessibility and try to find and extracts Azure Storage Containers' endpoints. |
| test-storageblobs.ps1 | Tests a list of Azure Storage Blobs for accessibility and extracts information about the storage blob. Including metadata and content. |
| test-storagecontainers.ps1 | Tests a list of Azure Storage Containers for accessibility and extracts information about the container. Including blobs. |
| get-storageblob.ps1 | Downloads a publicly accessible blob from a storage account. |

## Recommendation

If you want to use these scripts, you can follow these steps:

*1.* ...

*2.* Test possible subdomains with `test-subdomains.ps1`.

*3.* Test websites with `test-websites.ps1`. You could use the output of
`test-subdomains.ps1` *("./case/\$CaseName/services/pub-websites.txt")* as input.

*4.* Test blob storage accounts with `test-storageblobs.ps1`. You could use
the output of `test-websites.ps1` or `test-subdomains.ps1`
*("./case/\$CaseName/services/pub-storageblobs.txt")* as input. You could
also use custom wordlist for enumeration.

*5.* Test storage containers with `test-storagecontainers.ps1`. You could use
the output of `test-websites.ps1` or `test-storageblobs.ps1` as input.

*6.* Download blobs with `get-storageblob.ps1`. You could use the output of
`test-storagecontainers.ps1` as input.
