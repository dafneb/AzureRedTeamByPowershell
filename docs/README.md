---
description: Documentation website
---

# Red Team Toolings - M365 & Entra ID & Azure via PowerShell

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](https://github.com/dafneb/.github/blob/main/.github/CODE_OF_CONDUCT.md)
[![License](https://img.shields.io/badge/License-MIT-4baaaa.svg)](https://github.com/dafneb/.github/blob/main/LICENSE)
![GitHub Release](https://img.shields.io/github/v/release/dafneb/AzureRedTeamByPowershell)
![GitHub commit activity](https://img.shields.io/github/commit-activity/w/dafneb/AzureRedTeamByPowershell)
![GitHub contributors](https://img.shields.io/github/contributors/dafneb/AzureRedTeamByPowershell)

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/dafneb/AzureRedTeamByPowershell/powershell-analyzer.yml?label=PSScriptAnalyzer)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/dafneb/AzureRedTeamByPowershell/codeql.yml?label=CodeQL)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/dafneb/AzureRedTeamByPowershell/main.svg)](https://results.pre-commit.ci/latest/github/dafneb/AzureRedTeamByPowershell/main)
[![GitBook](https://img.shields.io/static/v1?message=Documented%20on%20GitBook&logo=gitbook&logoColor=ffffff&label=%20&labelColor=5c5c5c&color=3F89A1)](https://dafneb.gitbook.io/azureredteambypowershell)

This repository contains a set of PowerShell scripts to help red teamers and pentesters to enumerate and test Microsoft 365, Entra ID and Azure environments.

## Scripts organization

- ./scripts/private -> Scripts for usage when you have access to the target environment.
- ./scripts/public -> Scripts for usage against the target environment without access (e.g. from the internet via service's endpoints).

## Disclaimer

Scripts are provided for educational purposes only. Use them at your own risk.
The author is not responsible for any damage caused by the use of these scripts.
Please ensure you have permission to test the target environment before
using these scripts.

## Contributing
If you want to contribute to this project, please read the [Code_of_Conduct](https://github.com/dafneb/.github/blob/main/.github/CODE_OF_CONDUCT.md).
