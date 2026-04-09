# Getting Started

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **PowerShell 7.x** | Required. [Download here](https://github.com/PowerShell/PowerShell) |
| **FailoverClusters module** | Required. Available on cluster nodes or management machines with RSAT |
| **Storage module** | Required. Available on Windows Server and RSAT-enabled clients |
| **ImportExcel** | Required for Excel report generation: `Install-Module ImportExcel` |
| **WinRM access** | Required if running remotely. Port 5985/5986 open to cluster nodes |
| **Az.KeyVault** | Optional. Required only if using Key Vault credential retrieval |

## Installation

### From source

```powershell
git clone https://github.com/AzureLocal/azurelocal-S2DCartographer.git
Set-Location .\azurelocal-S2DCartographer
Import-Module .\S2DCartographer.psd1 -Force
```

### From PSGallery (planned for v1.0.0)

```powershell
Install-Module S2DCartographer -Scope CurrentUser
```

## First Run

### Step 1 — Connect to your cluster

```powershell
Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential (Get-Credential)
```

You can also reuse an existing session:

```powershell
$cim = New-CimSession -ComputerName "node01" -Credential $cred
Connect-S2DCluster -CimSession $cim
```

Or run locally on a cluster node:

```powershell
Connect-S2DCluster -Local
```

### Step 2 — Inventory physical disks

```powershell
Get-S2DPhysicalDiskInventory | Format-Table NodeName, FriendlyName, Role, Size, HealthStatus, WearPercentage
```

### Step 3 — Disconnect when done

```powershell
Disconnect-S2DCluster
```

## Capacity Unit Preference

S2DCartographer always shows both TiB (binary/Windows) and TB (decimal/drive label) in every output. This cannot be disabled — it is a core design principle of the tool.

To understand why this matters, see [TiB vs TB](tib-vs-tb.md).
