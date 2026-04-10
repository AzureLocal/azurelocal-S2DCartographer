# Word (.docx) report exporter — generates Open XML without requiring Office

function Export-S2DWordReport {
    param(
        [Parameter(Mandatory)] [S2DClusterData] $ClusterData,
        [Parameter(Mandatory)] [string]          $OutputPath,
        [string] $Author  = '',
        [string] $Company = ''
    )

    $dir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $cn   = $ClusterData.ClusterName
    $nc   = $ClusterData.NodeCount
    $wf   = $ClusterData.CapacityWaterfall
    $pool = $ClusterData.StoragePool
    $vols = @($ClusterData.Volumes)
    $disks = @($ClusterData.PhysicalDisks)
    $hc   = @($ClusterData.HealthChecks)
    $oh   = $ClusterData.OverallHealth
    $date = Get-Date -Format 'MMMM d, yyyy'

    # ── Build document XML ────────────────────────────────────────────────────
    function local:P     { param([string]$text,[string]$style='Normal') "<w:p><w:pPr><w:pStyle w:val='$style'/></w:pPr><w:r><w:t xml:space='preserve'>$([System.Security.SecurityElement]::Escape($text))</w:t></w:r></w:p>" }
    function local:H1    { param([string]$t) "<w:p><w:pPr><w:pStyle w:val='Heading1'/></w:pPr><w:r><w:t>$([System.Security.SecurityElement]::Escape($t))</w:t></w:r></w:p>" }
    function local:H2    { param([string]$t) "<w:p><w:pPr><w:pStyle w:val='Heading2'/></w:pPr><w:r><w:t>$([System.Security.SecurityElement]::Escape($t))</w:t></w:r></w:p>" }
    function local:BR    { "<w:p/>" }
    function local:Bold  { param([string]$l,[string]$v) "<w:p><w:r><w:rPr><w:b/></w:rPr><w:t xml:space='preserve'>$([System.Security.SecurityElement]::Escape($l))</w:t></w:r><w:r><w:t xml:space='preserve'> $([System.Security.SecurityElement]::Escape($v))</w:t></w:r></w:p>" }
    function local:TRow  { param([string[]]$cells,[bool]$isHeader=$false)
        $rp = if ($isHeader) { "<w:trPr><w:tblHeader/></w:trPr>" } else { "" }
        $cs = $cells | ForEach-Object {
            $shd = if ($isHeader) { "<w:shd w:val='clear' w:color='auto' w:fill='0078D4'/>" } else { "" }
            $rp2 = if ($isHeader) { "<w:rPr><w:b/><w:color w:val='FFFFFF'/></w:rPr>" } else { "" }
            "<w:tc><w:tcPr><w:tcW w:w='0' w:type='auto'/>$shd</w:tcPr><w:p><w:r>$rp2<w:t>$([System.Security.SecurityElement]::Escape($_))</w:t></w:r></w:p></w:tc>"
        }
        "<w:tr>$rp$($cs -join '')</w:tr>"
    }
    function local:Table { param([string[]]$headers,[object[]]$rows,[string[]]$props)
        $hrow = TRow -cells $headers -isHeader $true
        $drows = $rows | ForEach-Object {
            $obj = $_
            $cells = $props | ForEach-Object { $v = $obj.$_; if ($null -eq $v) { '' } else { [string]$v } }
            TRow -cells $cells
        }
        "<w:tbl><w:tblPr><w:tblW w:w='0' w:type='auto'/><w:tblBorders><w:top w:val='single' w:sz='4' w:color='EDEBE9'/><w:left w:val='single' w:sz='4' w:color='EDEBE9'/><w:bottom w:val='single' w:sz='4' w:color='EDEBE9'/><w:right w:val='single' w:sz='4' w:color='EDEBE9'/><w:insideH w:val='single' w:sz='4' w:color='EDEBE9'/><w:insideV w:val='single' w:sz='4' w:color='EDEBE9'/></w:tblBorders></w:tblPr>$hrow$($drows -join '')</w:tbl>"
    }

    $body = @()

    # Cover page
    $body += H1 "S2D Cartographer — $cn"
    $body += P  "Storage Spaces Direct Analysis Report"
    $body += P  "Generated: $date"
    if ($Author)  { $body += P "Prepared by: $Author" }
    if ($Company) { $body += P "Organization: $Company" }
    $body += BR

    # Executive Summary
    $body += H1 "Executive Summary"
    $body += Bold "Cluster:" $cn
    $body += Bold "Nodes:" $nc
    $body += Bold "Overall Health:" $oh
    if ($wf) {
        $body += Bold "Raw Capacity:"    "$($wf.RawCapacity.TiB) TiB ($($wf.RawCapacity.TB) TB)"
        $body += Bold "Usable Capacity:" "$($wf.UsableCapacity.TiB) TiB ($($wf.UsableCapacity.TB) TB)"
        $body += Bold "Reserve Status:"  $wf.ReserveStatus
        $body += Bold "Resiliency Efficiency:" "$($wf.BlendedEfficiencyPercent)%"
    }
    $body += BR

    # Capacity Waterfall
    $body += H1 "Capacity Waterfall"
    $body += P  "The following table shows the 8-stage capacity reduction from raw physical disks to final usable storage."
    if ($wf) {
        $wfRows = $wf.Stages | ForEach-Object {
            [PSCustomObject]@{
                Stage = "Stage $($_.Stage)"; Name = $_.Name
                TiB = if ($_.Size) { "$($_.Size.TiB) TiB" } else { '0 TiB' }
                TB  = if ($_.Size) { "$($_.Size.TB) TB" }   else { '0 TB' }
                Status = $_.Status; Description = $_.Description
            }
        }
        $body += Table -headers @('Stage','Name','TiB','TB','Status','Description') -rows $wfRows -props @('Stage','Name','TiB','TB','Status','Description')
    }
    $body += BR

    # Physical Disk Inventory
    $body += H1 "Physical Disk Inventory"
    $diskRows = $disks | ForEach-Object {
        [PSCustomObject]@{
            Node = $_.NodeName; Model = $_.FriendlyName; Type = $_.MediaType
            Role = $_.Role; Size = if($_.Size){"$($_.Size.TiB) TiB"}else{'N/A'}
            Wear = if($null -ne $_.WearPercentage){"$($_.WearPercentage)%"}else{'N/A'}
            Health = $_.HealthStatus
        }
    }
    $body += Table -headers @('Node','Model','Type','Role','Size','Wear %','Health') -rows $diskRows -props @('Node','Model','Type','Role','Size','Wear','Health')
    $body += BR

    # Volume Map
    $body += H1 "Volume Map"
    $volRows = $vols | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.FriendlyName; Resiliency = "$($_.ResiliencySettingName) ($($_.NumberOfDataCopies)x)"
            Size = if($_.Size){"$($_.Size.TiB) TiB"}else{'N/A'}
            Footprint = if($_.FootprintOnPool){"$($_.FootprintOnPool.TiB) TiB"}else{'N/A'}
            Eff = "$($_.EfficiencyPercent)%"; Prov = $_.ProvisioningType; Health = $_.HealthStatus
        }
    }
    $body += Table -headers @('Volume','Resiliency','Size','Pool Footprint','Efficiency','Provisioning','Health') -rows $volRows -props @('Name','Resiliency','Size','Footprint','Eff','Prov','Health')
    $body += BR

    # Health Checks
    $body += H1 "Health Assessment"
    foreach ($check in $hc) {
        $body += H2 "$($check.CheckName) [$($check.Severity)] — $($check.Status)"
        $body += P  $check.Details
        if ($check.Status -ne 'Pass' -and $check.Remediation) {
            $body += Bold "Remediation:" $check.Remediation
        }
        $body += BR
    }

    # Appendix A: TiB vs TB
    $body += H1 "Appendix A — TiB vs TB Explanation"
    $body += P  "Drive manufacturers label storage in decimal terabytes (1 TB = 1,000,000,000,000 bytes). Windows and S2D report capacity in binary tebibytes (1 TiB = 1,099,511,627,776 bytes). This creates an apparent ~9% difference. All data is present and accounted for — the discrepancy is purely a unit conversion."
    $tibTable = @(
        [PSCustomObject]@{ Label='0.96 TB'; Windows='0.873 TiB'; Diff='-9.3%' }
        [PSCustomObject]@{ Label='1.92 TB'; Windows='1.747 TiB'; Diff='-9.0%' }
        [PSCustomObject]@{ Label='3.84 TB'; Windows='3.492 TiB'; Diff='-9.1%' }
        [PSCustomObject]@{ Label='7.68 TB'; Windows='6.986 TiB'; Diff='-9.0%' }
        [PSCustomObject]@{ Label='15.36 TB'; Windows='13.97 TiB'; Diff='-9.1%' }
    )
    $body += Table -headers @('Drive Label','Windows Reports','Difference') -rows $tibTable -props @('Label','Windows','Diff')
    $body += BR

    # Appendix B: Reserve Best Practices
    $body += H1 "Appendix B — S2D Reserve Space Best Practices"
    $body += P  "Microsoft recommends keeping at least min(NodeCount, 4) × (largest capacity drive size) of unallocated pool space. This reserve enables full rebuild after a drive or node failure. For a $nc-node cluster with $($wf ? "$($wf.ReserveRecommended.TB) TB" : 'N/A') largest drives, the recommended reserve is $($wf ? "$($wf.ReserveRecommended.TiB) TiB" : 'N/A')."

    $bodyXml = $body -join "`n"

    # ── Assemble DOCX (ZIP of XML) ────────────────────────────────────────────
    $contentTypesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml"  ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml"   ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
'@

    $relsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@

    $wordRelsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@

    $stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:sz w:val="22"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/>
    <w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="32"/><w:color w:val="0078D4"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/>
    <w:pPr><w:spacing w:before="160" w:after="80"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="26"/><w:color w:val="323130"/></w:rPr>
  </w:style>
</w:styles>
'@

    $documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
$bodyXml
<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr>
</w:body>
</w:document>
"@

    # Write to zip
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $ms = [System.IO.MemoryStream]::new()
    $zip = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Create, $true)

    function local:AddEntry { param([string]$name,[string]$content)
        $e = $zip.CreateEntry($name)
        $sw = [System.IO.StreamWriter]::new($e.Open())
        $sw.Write($content); $sw.Close()
    }

    AddEntry '[Content_Types].xml'       $contentTypesXml
    AddEntry '_rels/.rels'               $relsXml
    AddEntry 'word/_rels/document.xml.rels' $wordRelsXml
    AddEntry 'word/styles.xml'           $stylesXml
    AddEntry 'word/document.xml'         $documentXml
    $zip.Dispose()

    [System.IO.File]::WriteAllBytes($OutputPath, $ms.ToArray())
    $ms.Dispose()

    Write-Verbose "Word report written to $OutputPath"
    $OutputPath
}
