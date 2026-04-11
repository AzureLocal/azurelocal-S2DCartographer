# Connecting to a Cluster

`Connect-S2DCluster` establishes the CIM and PowerShell sessions that every other collector and report command uses. All subsequent commands in the session reuse these sessions — you connect once and then call whatever collectors you need.

=== "Domain-Joined"

    The most common scenario. Your management machine is joined to the same domain (or a trusted domain) as the cluster nodes.

    ```powershell
    # Prompt for credentials
    Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential (Get-Credential)

    # Or pass a pre-built credential object
    $cred = New-Object PSCredential("CONTOSO\ClusterAdmin", $securePass)
    Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential $cred
    ```

    `ClusterName` accepts both short names (`c01-prd-bal`) and FQDNs (`c01-prd-bal.contoso.com`). When a short name is provided, S2DCartographer resolves the cluster IP via DNS and connects to the first available node.

    !!! tip "Use -Verbose for connection details"
        `Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential $cred -Verbose` shows which node was contacted, the CIM session protocol negotiated, and the S2D pool name discovered.

=== "Non-Domain-Joined"

    Management machines outside the cluster's domain — common in lab environments, customer site visits, or cross-domain management.

    ```powershell
    # Explicit FQDN resolves DNS without Kerberos
    Connect-S2DCluster -ClusterName "c01-prd-bal.contoso.com" -Credential (Get-Credential)
    ```

    !!! warning "NTLM required for non-domain-joined machines"
        WinRM defaults to Kerberos for domain accounts. From a non-domain-joined machine you need NTLM or CredSSP. Ensure the target cluster nodes have NTLM enabled on their WinRM listener, or pre-configure a trusted hosts entry:

        ```powershell
        # Run once on your management machine (elevated)
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*.contoso.com" -Force
        ```

    !!! note "Certificate-based WinRM"
        If the cluster uses HTTPS WinRM (port 5986), pass an existing `CimSessionOption` with `-CimSession`:
        ```powershell
        $opt = New-CimSessionOption -UseSsl
        $cim = New-CimSession -ComputerName "node01.contoso.com" -Credential $cred -SessionOption $opt
        Connect-S2DCluster -CimSession $cim
        ```

=== "Local Node"

    Run directly on a cluster node — no credentials needed, no network hops, no WinRM configuration required. Useful for automated scripts that run as scheduled tasks on a node.

    ```powershell
    Connect-S2DCluster -Local
    ```

    !!! info "What -Local does"
        Creates a loopback CIM session (no network) and sets `IsLocal = $true` in the module session. All collectors still execute the same code paths — only the session transport changes.

    !!! tip "Scheduled task pattern"
        ```powershell
        # Runs on a cluster node — no credential storage needed
        Import-Module S2DCartographer
        Connect-S2DCluster -Local
        Invoke-S2DCartographer -Format Html -OutputDirectory "\\fileserver\reports\"
        Disconnect-S2DCluster
        ```

=== "Key Vault (Unattended)"

    For automation pipelines and scheduled runs where storing credentials in scripts is not acceptable. Retrieves the cluster admin password from an Azure Key Vault secret.

    ```powershell
    # Requires: Az.KeyVault module + authenticated Az session (e.g., Managed Identity)
    Invoke-S2DCartographer -ClusterName "c01-prd-bal" `
        -KeyVaultName "kv-platform-prod" `
        -SecretName  "c01-prd-bal-admin-password" `
        -Format Html -OutputDirectory "C:\AutoReports\"
    ```

    !!! note "Secret format"
        The Key Vault secret value should be the **password only** as a plain string. The username defaults to `$ClusterName\Administrator`. To use a different username, retrieve the secret manually and build your own `PSCredential`:

        ```powershell
        $pw  = (Get-AzKeyVaultSecret -VaultName "kv-prod" -Name "cluster-pw").SecretValue
        $cred = New-Object PSCredential("CONTOSO\ClusterAdmin", $pw)
        Connect-S2DCluster -ClusterName "c01-prd-bal" -Credential $cred
        ```

    !!! tip "Azure Automation / Managed Identity"
        From an Azure Automation runbook or an Arc-enabled VM with a Managed Identity, call `Connect-AzAccount -Identity` before `Invoke-S2DCartographer`. The module will use the authenticated Az context to call Key Vault.

---

## Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `-ClusterName` | `string` | Cluster name or FQDN. Resolved via DNS. |
| `-Credential` | `PSCredential` | Username and password for authentication. |
| `-CimSession` | `CimSession` | Re-use an existing CIM session. |
| `-PSSession` | `PSSession` | Re-use an existing PS remoting session. |
| `-Local` | `switch` | Connect to the local machine (no credentials). |
| `-KeyVaultName` | `string` | Azure Key Vault name for unattended credential retrieval. |
| `-SecretName` | `string` | Key Vault secret containing the cluster admin password. |

---

## Disconnecting

Always disconnect when your session is complete to release CIM and PS sessions:

```powershell
Disconnect-S2DCluster
```

`Disconnect-S2DCluster` closes all open sessions and clears the module session cache. Calling it is safe even if no session is active.
