<#
.SYNOPSIS
  Dot-source this file, then call Rasterize-BcPdf to turn any PDF into
  page-N.png files, using Windows' own WinRT PDF renderer.

.DESCRIPTION
  Used for BOTH sides of the render loop: BcRender.cs's --format PNG mode
  (ReportViewer's native Image renderer) was tried as the primary path and
  rejected -- it measures text differently from ReportViewer's PDF renderer
  enough to change actual pagination (a fixture that's 2 pages as PDF came
  out 3 pages as direct PNG, with a column wrapping mid-value, confirmed by
  isolating the renderer backend from DPI/device-info settings -- tried
  explicit A4 page size and margins, none recovered 2-page parity, one made
  it worse). So render.ps1 always renders PDF (BcRender.cs's default,
  unchanged path) and rasterises it here, same as it rasterises a
  BC-produced "Send to > PDF Document" reference export for compare-bc.ps1.
  Both call this function; neither renders PNG directly. --format PNG stays
  in BcRender.cs as a capability, just not one anything in this loop uses by
  default -- see CLAUDE.md's Fidelity section before reaching for it.

  Either way, .NET Framework has no built-in PDF rasteriser. Rather than pull
  in a third-party dependency (or Python + pymupdf, which is exactly what
  this loop is trying to stop needing), this uses Windows.Data.Pdf.PdfDocument
  -- part of the Windows Runtime, built into every Windows 10/11 install, no
  package to install.

  PS 5.1 can't await a WinRT IAsyncOperation<T>/IAsyncAction directly (that's
  a C#/WinRT-projection convenience, not something the PowerShell parser
  understands) -- Await/AwaitAction below reflect out the
  WindowsRuntimeSystemExtensions.AsTask() extension method and block on the
  resulting .NET Task instead. This is the standard, if slightly obscure,
  pattern for driving WinRT APIs from Windows PowerShell.

  DPI math: PdfPage.Size is in 96-DPI device-independent pixels (WinRT/DIP
  convention), NOT 72-DPI points. Verified empirically against this repo's
  own fixture: bc-reference.pdf's PdfPage.Size is 793.70 x 1122.52, and
  Ceiling(793.70 / 96 * 110) x Ceiling(1122.52 / 96 * 110) = 910 x 1287 --
  exactly the page size pymupdf produced rasterising the same PDF at 110 DPI
  (the number recorded in CLAUDE.md's Conformance section). Round() undershoots
  by one pixel on both dimensions; Ceiling() is what matches. Don't change
  that to Round without re-verifying against a known-good rasterisation.

  Second DPI gotcha, worse than the first: PdfPage.RenderToStreamAsync does
  NOT honor PdfPageRenderOptions.DestinationWidth/DestinationHeight as literal
  output pixels. It silently rescales them by the *system* DPI scale factor
  (Settings > Display > Scale) -- verified on this machine at 125% scale:
  requesting 910x1287 actually produced a 1138x1609 PNG (1138/910 = 1.2505,
  matching 125% almost exactly). This reproduced identically whether or not
  the process called SetProcessDPIAware first -- it is not a process
  DPI-awareness issue, WinRT applies this scaling internally regardless.
  The fix is to pre-divide the desired output size by the system scale factor
  (queried via GetDpiForSystem, Windows 10 1607+) before setting
  DestinationWidth/Height, so the *actual* output lands on the desired size.
  Confirmed: on this 125%-scale machine, requesting 728x1030 (910/1.25,
  1287/1.25 rounded) produced a 910x1288 PNG -- within a pixel of the true
  target, which is the same order of jitter this loop already tolerates
  elsewhere (the header timestamp shifts a few hundred px run to run). Do not
  remove this compensation or assume DestinationWidth/Height are literal --
  they are not, on any machine with a non-100% display scale factor.

  Third gotcha, needed to even measure the second one: GetDpiForSystem()
  itself returns the *virtualized* 96 on a DPI-unaware process, despite MS's
  docs implying it's awareness-independent -- Windows applies compatibility
  virtualization to it too for legacy processes. powershell.exe has no
  DPI-awareness manifest, so without calling SetProcessDPIAware() first,
  GetDpiForSystem() silently lies and returns 96 (scale = 1.0, no
  compensation applied, and you're back to the 1138x1609 bug). Call
  SetProcessDPIAware() before anything DPI-related; verified it flips
  GetDpiForSystem()'s answer from 96 to the true 120 on this machine.
#>

$ErrorActionPreference = 'Stop'

Add-Type -Namespace BcRenderNative -Name Dpi -MemberDefinition '
    [DllImport("user32.dll")] public static extern uint GetDpiForSystem();
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
'
# Must happen before GetDpiForSystem() is trusted -- see third gotcha above.
[BcRenderNative.Dpi]::SetProcessDPIAware() | Out-Null

# --- WinRT async-await shim -------------------------------------------------
Add-Type -AssemblyName System.Runtime.WindowsRuntime

$script:AsTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
})[0]
$script:AsTaskAction = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction'
})[0]

function script:Await($WinRtOperation, $ResultType) {
    $asTask = $script:AsTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtOperation))
    $netTask.Wait(-1) | Out-Null
    return $netTask.Result
}

function script:AwaitAction($WinRtAction) {
    $netTask = $script:AsTaskAction.Invoke($null, @($WinRtAction))
    $netTask.Wait(-1) | Out-Null
}

[Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime] | Out-Null

function Rasterize-BcPdf {
    <#
    .SYNOPSIS
      Rasterize a PDF to page-N.png files in -OutDir, at -Dpi (default 110 --
      matches the DPI BcRender.cs's -Format PNG mode and this repo's whole
      conformance history uses; changing it here without changing the other
      side makes any diff meaningless).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string]$PdfPath,
        [Parameter(Mandatory = $true)] [string]$OutDir,
        [int]$Dpi = 110
    )

    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    $fullPath = (Resolve-Path $PdfPath).Path

    # System DPI scale factor -- see the "second DPI gotcha" in the module doc
    # comment. RenderToStreamAsync silently multiplies our requested
    # Destination size by this, so we pre-divide it out.
    $systemDpi = [BcRenderNative.Dpi]::GetDpiForSystem()
    $scale = $systemDpi / 96.0

    $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($fullPath)) ([Windows.Storage.StorageFile])
    $pdf = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])

    $written = @()
    for ($i = 0; $i -lt $pdf.PageCount; $i++) {
        $page = $pdf.GetPage($i)
        try {
            # Ceiling, not Round -- see module doc comment above. This is the
            # TRUE desired output size, in pixels, at $Dpi.
            $targetW = [Math]::Ceiling($page.Size.Width / 96.0 * $Dpi)
            $targetH = [Math]::Ceiling($page.Size.Height / 96.0 * $Dpi)

            # What we actually hand RenderToStreamAsync -- compensated so the
            # ACTUAL output lands on $targetW x $targetH, per the second DPI
            # gotcha above.
            $reqW = [Math]::Round($targetW / $scale)
            $reqH = [Math]::Round($targetH / $scale)

            $opts = New-Object Windows.Data.Pdf.PdfPageRenderOptions
            $opts.DestinationWidth = [uint32]$reqW
            $opts.DestinationHeight = [uint32]$reqH

            $stream = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
            try {
                AwaitAction ($page.RenderToStreamAsync($stream, $opts))
                $outPath = Join-Path $OutDir ("page-{0}.png" -f ($i + 1))
                $netStream = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($stream.GetInputStreamAt(0))
                try {
                    $fs = [System.IO.File]::Create($outPath)
                    try { $netStream.CopyTo($fs) } finally { $fs.Close() }
                }
                finally { $netStream.Close() }
                $written += $outPath
            }
            finally { $stream.Dispose() }
        }
        finally { $page.Dispose() }
    }
    return $written
}
