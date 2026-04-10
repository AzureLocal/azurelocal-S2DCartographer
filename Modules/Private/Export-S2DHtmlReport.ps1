# HTML report exporter — self-contained single-file dashboard with Chart.js

function Export-S2DHtmlReport {
    param(
        [Parameter(Mandatory)] [S2DClusterData] $ClusterData,
        [Parameter(Mandatory)] [string]          $OutputPath,
        [string] $Author  = '',
        [string] $Company = ''
    )

    $generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm'
    $cn   = $ClusterData.ClusterName
    $nc   = $ClusterData.NodeCount
    $pool = $ClusterData.StoragePool
    $wf   = $ClusterData.CapacityWaterfall
    $hc   = @($ClusterData.HealthChecks)
    $oh   = $ClusterData.OverallHealth
    $vols = @($ClusterData.Volumes)
    $disks = @($ClusterData.PhysicalDisks)
    $cache = $ClusterData.CacheTier

    $overallBg = switch ($oh) { 'Healthy'{'#dff6dd'} 'Warning'{'#fff4ce'} 'Critical'{'#fde7e9'} default{'#f3f2f1'} }
    $overallFg = switch ($oh) { 'Healthy'{'#107c10'} 'Warning'{'#d47a00'} 'Critical'{'#d13438'} default{'#323130'} }

    # ── Waterfall chart data ──────────────────────────────────────────────────
    $wfLabels = ''
    $wfValues = ''
    if ($wf) {
        $wfLabels = ($wf.Stages | ForEach-Object { "'Stage $($_.Stage): $($_.Name)'" }) -join ','
        $wfValues = ($wf.Stages | ForEach-Object { if ($_.Size) { [math]::Round($_.Size.TiB, 2) } else { 0 } }) -join ','
    }

    # ── Disk inventory table rows ─────────────────────────────────────────────
    $diskRows = ($disks | ForEach-Object {
        $hw = if ($_.WearPercentage -gt 80) { ' style="color:#d13438"' } else { '' }
        $hs = if ($_.HealthStatus -eq 'Healthy') { '<span class="badge ok">Healthy</span>' } else { "<span class='badge fail'>$($_.HealthStatus)</span>" }
        "<tr><td>$($_.NodeName)</td><td>$($_.FriendlyName)</td><td>$($_.MediaType)</td><td>$($_.Role)</td><td>$(if($_.Size){"$($_.Size.TiB) TiB ($($_.Size.TB) TB)"}else{'N/A'})</td><td$hw>$(if($null -ne $_.WearPercentage){"$($_.WearPercentage)%"}else{'N/A'})</td><td>$hs</td></tr>"
    }) -join "`n"

    # ── Volume table rows ─────────────────────────────────────────────────────
    $volRows = ($vols | ForEach-Object {
        $infraTag = if ($_.IsInfrastructureVolume) { ' <span class="badge info">Infra</span>' } else { '' }
        $hs = if ($_.HealthStatus -eq 'Healthy') { '<span class="badge ok">Healthy</span>' } else { "<span class='badge fail'>$($_.HealthStatus)</span>" }
        "<tr><td>$($_.FriendlyName)$infraTag</td><td>$($_.ResiliencySettingName) ($($_.NumberOfDataCopies) copies)</td><td>$(if($_.Size){"$($_.Size.TiB) TiB"}else{'N/A'})</td><td>$(if($_.FootprintOnPool){"$($_.FootprintOnPool.TiB) TiB"}else{'N/A'})</td><td>$($_.EfficiencyPercent)%</td><td>$($_.ProvisioningType)</td><td>$hs</td></tr>"
    }) -join "`n"

    # ── Health check cards ────────────────────────────────────────────────────
    $hcCards = ($hc | ForEach-Object {
        $cls = switch ($_.Status) { 'Pass'{'hc-pass'} 'Warn'{'hc-warn'} 'Fail'{'hc-fail'} default{'hc-info'} }
        $icon = switch ($_.Status) { 'Pass'{'✔'} 'Warn'{'⚠'} 'Fail'{'✖'} default{'ℹ'} }
        "<div class='hc-card $cls'><span class='hc-icon'>$icon</span><div class='hc-body'><strong>$($_.CheckName)</strong> <em>[$($_.Severity)]</em><p>$([System.Net.WebUtility]::HtmlEncode($_.Details))</p>$(if($_.Status -ne 'Pass'){"<p class='remediation'><strong>Remediation:</strong> $([System.Net.WebUtility]::HtmlEncode($_.Remediation))</p>"})</div></div>"
    }) -join "`n"

    # ── Cache tier summary ────────────────────────────────────────────────────
    $cacheSummary = if ($cache) {
        $allFlashTag = if ($cache.IsAllFlash) { '<span class="badge info">All-Flash</span>' } else { '' }
        "<p><strong>Cache Mode:</strong> $($cache.CacheMode) $allFlashTag &nbsp; <strong>State:</strong> $($cache.CacheState) &nbsp; <strong>Disks:</strong> $($cache.CacheDiskCount)</p>"
    } else { '<p>Cache data not available.</p>' }

    $poolSummary = if ($pool) {
        "<p><strong>Pool:</strong> $($pool.FriendlyName) &nbsp; <strong>Health:</strong> $($pool.HealthStatus) &nbsp; <strong>Total:</strong> $($pool.TotalSize.TiB) TiB &nbsp; <strong>Allocated:</strong> $($pool.AllocatedSize.TiB) TiB &nbsp; <strong>Free:</strong> $($pool.RemainingSize.TiB) TiB &nbsp; <strong>Overcommit:</strong> $($pool.OvercommitRatio)x</p>"
    } else { '<p>Pool data not available.</p>' }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>S2D Cartographer — $cn</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<style>
:root{--blue:#0078d4;--teal:#008272;--green:#107c10;--amber:#e8a218;--red:#d13438;--bg:#faf9f8;--card:#ffffff;--border:#edebe9;--text:#201f1e;--muted:#605e5c}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',Arial,sans-serif;background:var(--bg);color:var(--text);font-size:14px}
header{background:var(--blue);color:white;padding:20px 32px;display:flex;justify-content:space-between;align-items:center}
header h1{font-size:22px;font-weight:600}
header .meta{font-size:12px;opacity:.85;text-align:right}
.container{max-width:1200px;margin:0 auto;padding:24px}
.section{background:var(--card);border:1px solid var(--border);border-radius:6px;margin-bottom:20px;padding:20px}
.section h2{font-size:16px;font-weight:600;margin-bottom:12px;padding-bottom:8px;border-bottom:2px solid var(--blue);color:var(--blue)}
.overview-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px;margin-bottom:16px}
.kpi{background:var(--bg);border:1px solid var(--border);border-radius:6px;padding:14px;text-align:center}
.kpi .val{font-size:22px;font-weight:700;color:var(--blue)}
.kpi .lbl{font-size:11px;color:var(--muted);margin-top:4px}
.health-banner{border-radius:6px;padding:12px 20px;margin-bottom:16px;font-weight:600;font-size:15px;background:$overallBg;color:$overallFg}
table{width:100%;border-collapse:collapse;font-size:13px}
th{background:#f3f2f1;text-align:left;padding:8px 10px;font-weight:600;border-bottom:2px solid var(--border)}
td{padding:7px 10px;border-bottom:1px solid var(--border)}
tr:hover{background:#f3f2f1}
.badge{display:inline-block;border-radius:4px;padding:2px 7px;font-size:11px;font-weight:600}
.badge.ok{background:#dff6dd;color:#107c10}.badge.fail{background:#fde7e9;color:#d13438}.badge.info{background:#eff6fc;color:#0078d4}
.hc-card{display:flex;align-items:flex-start;gap:12px;border-radius:6px;padding:12px 16px;margin-bottom:8px;border-left:4px solid}
.hc-pass{background:#dff6dd;border-color:#107c10}.hc-warn{background:#fff4ce;border-color:#e8a218}.hc-fail{background:#fde7e9;border-color:#d13438}.hc-info{background:#eff6fc;border-color:#0078d4}
.hc-icon{font-size:20px;min-width:24px}.hc-body strong{font-size:13px}.hc-body p{font-size:12px;color:var(--muted);margin-top:4px}.remediation{color:#323130 !important;font-style:italic}
.toggle-row{display:flex;align-items:center;gap:10px;margin-bottom:12px;font-size:13px}
.toggle-btn{background:var(--blue);color:white;border:none;border-radius:4px;padding:5px 14px;cursor:pointer;font-size:12px}
.chart-wrap{position:relative;height:300px}
.tib-tb-table{font-size:13px}
.tib-tb-table th,.tib-tb-table td{padding:6px 14px}
@media print{.toggle-row{display:none}}
</style>
</head>
<body>
<header>
  <div>
    <h1>S2D Cartographer Report</h1>
    <div style="font-size:13px;opacity:.9">$cn &nbsp;|&nbsp; $nc nodes</div>
  </div>
  <div class="meta">
    Generated: $generatedAt<br>
    $(if($Author){"By: $Author<br>"})$(if($Company){"$Company"})
  </div>
</header>
<div class="container">

<div class="section">
  <h2>Executive Summary</h2>
  <div class="health-banner">Overall Health: $oh</div>
  <div class="overview-grid">
    <div class="kpi"><div class="val">$nc</div><div class="lbl">Nodes</div></div>
    <div class="kpi"><div class="val">$(if($wf){"$($wf.RawCapacity.TiB) TiB"}else{'N/A'})</div><div class="lbl">Raw Capacity</div></div>
    <div class="kpi"><div class="val">$(if($wf){"$($wf.UsableCapacity.TiB) TiB"}else{'N/A'})</div><div class="lbl">Usable Capacity</div></div>
    <div class="kpi"><div class="val">$(if($pool){"$($pool.RemainingSize.TiB) TiB"}else{'N/A'})</div><div class="lbl">Pool Free</div></div>
    <div class="kpi"><div class="val">$($disks.Count)</div><div class="lbl">Physical Disks</div></div>
    <div class="kpi"><div class="val">$(@($vols | Where-Object { -not $_.IsInfrastructureVolume }).Count)</div><div class="lbl">Workload Volumes</div></div>
    <div class="kpi"><div class="val">$(if($wf){"$($wf.ReserveStatus)"}else{'N/A'})</div><div class="lbl">Reserve Status</div></div>
    <div class="kpi"><div class="val">$(if($wf){"$($wf.BlendedEfficiencyPercent)%"}else{'N/A'})</div><div class="lbl">Resiliency Efficiency</div></div>
  </div>
  $poolSummary
  $cacheSummary
</div>

<div class="section">
  <h2>Capacity Waterfall</h2>
  <div class="toggle-row">
    <span>Display unit:</span>
    <button class="toggle-btn" onclick="toggleUnit()">Toggle TiB / TB</button>
    <span id="unitLabel" style="font-weight:600">TiB</span>
  </div>
  <div class="chart-wrap"><canvas id="waterfallChart"></canvas></div>
</div>

<div class="section">
  <h2>Physical Disk Inventory</h2>
  <table id="diskTable">
    <thead><tr><th>Node</th><th>Model</th><th>Media</th><th>Role</th><th>Size</th><th>Wear %</th><th>Health</th></tr></thead>
    <tbody>$diskRows</tbody>
  </table>
</div>

<div class="section">
  <h2>Volume Map</h2>
  <table>
    <thead><tr><th>Volume</th><th>Resiliency</th><th>Size</th><th>Pool Footprint</th><th>Efficiency</th><th>Provisioning</th><th>Health</th></tr></thead>
    <tbody>$volRows</tbody>
  </table>
</div>

<div class="section">
  <h2>Health Checks</h2>
  $hcCards
</div>

<div class="section">
  <h2>Understanding Storage Units — TiB vs TB</h2>
  <p style="margin-bottom:12px;color:var(--muted)">Hard drive manufacturers use decimal (1 TB = 1,000,000,000,000 bytes). Windows reports in binary (1 TiB = 1,099,511,627,776 bytes). This creates an apparent ~9% discrepancy — the data is all there, it's just expressed in different units.</p>
  <table class="tib-tb-table">
    <thead><tr><th>Drive Label (TB)</th><th>Windows Reports (TiB)</th><th>Difference</th></tr></thead>
    <tbody>
      <tr><td>0.96 TB</td><td>0.873 TiB</td><td style="color:var(--red)">-9.3%</td></tr>
      <tr><td>1.92 TB</td><td>1.747 TiB</td><td style="color:var(--red)">-9.0%</td></tr>
      <tr><td>3.84 TB</td><td>3.492 TiB</td><td style="color:var(--red)">-9.1%</td></tr>
      <tr><td>7.68 TB</td><td>6.986 TiB</td><td style="color:var(--red)">-9.0%</td></tr>
      <tr><td>15.36 TB</td><td>13.97 TiB</td><td style="color:var(--red)">-9.1%</td></tr>
    </tbody>
  </table>
</div>

</div>
<script>
const tibValues = [$wfValues];
const tbValues  = tibValues.map(v => Math.round(v * 1.0995 * 100) / 100);
const labels    = [$wfLabels];
let useTiB = true;

const ctx = document.getElementById('waterfallChart').getContext('2d');
const chart = new Chart(ctx, {
  type: 'bar',
  data: {
    labels: labels,
    datasets: [{
      label: 'Capacity (TiB)',
      data: tibValues,
      backgroundColor: ['#0078d4','#005a9e','#106ebe','#e8a218','#d47a00','#107c10','#0e6e0e','#054b05'],
      borderRadius: 4
    }]
  },
  options: {
    responsive: true, maintainAspectRatio: false,
    indexAxis: 'y',
    plugins: { legend: { display: false }, tooltip: { callbacks: { label: ctx => ctx.raw + (useTiB ? ' TiB' : ' TB') } } },
    scales: { x: { beginAtZero: true, title: { display: true, text: 'TiB' } } }
  }
});

function toggleUnit() {
  useTiB = !useTiB;
  document.getElementById('unitLabel').textContent = useTiB ? 'TiB' : 'TB';
  chart.data.datasets[0].data = useTiB ? tibValues : tbValues;
  chart.data.datasets[0].label = useTiB ? 'Capacity (TiB)' : 'Capacity (TB)';
  chart.options.scales.x.title.text = useTiB ? 'TiB' : 'TB';
  chart.update();
}
</script>
</body>
</html>
"@

    $dir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $html | Set-Content -Path $OutputPath -Encoding UTF8 -Force
    Write-Verbose "HTML report written to $OutputPath"
    $OutputPath
}
