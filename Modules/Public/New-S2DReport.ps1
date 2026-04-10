function New-S2DReport {
    <#
    .SYNOPSIS
        Generates HTML, Word, PDF, or Excel reports from S2D cluster data.

    .DESCRIPTION
        Accepts an S2DClusterData object (from Invoke-S2DCartographer -PassThru or pipeline)
        and renders publication-quality reports. Supports single or multiple formats in one call.

        Output files are written to OutputDirectory (default: C:\S2DCartographer).

    .PARAMETER InputObject
        S2DClusterData object from Invoke-S2DCartographer -PassThru. Accepts pipeline input.

    .PARAMETER Format
        One or more output formats: Html, Word, Pdf, Excel, All.

    .PARAMETER OutputDirectory
        Destination folder for report files. Created if it does not exist.

    .PARAMETER Author
        Author name embedded in the report header.

    .PARAMETER Company
        Company or organization name embedded in the report header.

    .EXAMPLE
        Invoke-S2DCartographer -ClusterName tplabs-clus01 -PassThru | New-S2DReport -Format Html

    .EXAMPLE
        $data = Invoke-S2DCartographer -ClusterName tplabs-clus01 -PassThru
        New-S2DReport -InputObject $data -Format Html, Excel -Author "Kris Turner" -Company "TierPoint"

    .OUTPUTS
        string[] — paths to generated report files
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [ValidateSet('Html', 'Word', 'Pdf', 'Excel', 'All')]
        [string[]] $Format,

        [Parameter()]
        [string] $OutputDirectory = 'C:\S2DCartographer',

        [Parameter()]
        [string] $Author = '',

        [Parameter()]
        [string] $Company = ''
    )

    process {
        if ($InputObject -isnot [S2DClusterData]) {
            throw "InputObject must be an S2DClusterData object. Use Invoke-S2DCartographer -PassThru to obtain one."
        }

        $effectiveFormats = if ('All' -in $Format) { @('Html', 'Word', 'Pdf', 'Excel') } else { $Format }

        $cn       = $InputObject.ClusterName -replace '[^\w\-]', '_'
        $stamp    = Get-Date -Format 'yyyyMMdd-HHmm'
        $baseName = "S2DCartographer_${cn}_${stamp}"

        $outputFiles = @()

        foreach ($fmt in $effectiveFormats) {
            $ext  = switch ($fmt) { 'Html'{'html'} 'Word'{'docx'} 'Pdf'{'pdf'} 'Excel'{'xlsx'} }
            $path = Join-Path $OutputDirectory "$baseName.$ext"

            Write-Verbose "Generating $fmt report → $path"
            try {
                $result = switch ($fmt) {
                    'Html'  { Export-S2DHtmlReport  -ClusterData $InputObject -OutputPath $path -Author $Author -Company $Company }
                    'Word'  { Export-S2DWordReport  -ClusterData $InputObject -OutputPath $path -Author $Author -Company $Company }
                    'Pdf'   { Export-S2DPdfReport   -ClusterData $InputObject -OutputPath $path -Author $Author -Company $Company }
                    'Excel' { Export-S2DExcelReport -ClusterData $InputObject -OutputPath $path -Author $Author -Company $Company }
                }
                if ($result) { $outputFiles += $result }
            }
            catch {
                Write-Warning "$fmt report failed: $_"
            }
        }

        $outputFiles
    }
}
