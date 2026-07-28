<#
.SYNOPSIS
  Per-page pixel diff between two directories of page-N.png. Pure PowerShell
  + System.Drawing -- no Python, no pymupdf/pillow. Replaces `pdfdiff.py diff`.

.DESCRIPTION
  Same contract as pdfdiff.py's diff subcommand: writes <Out>/page-N.png
  (changed pixels painted red over an exact copy of the candidate image --
  not GetPixel-dimmed, just red where different) and <Out>/summary.txt (a
  changed-pixel count per page, plus NEW PAGE / MISSING PAGE warnings when
  the page count itself differs between the two directories -- those pages
  contribute 0 to the pixel total, so a changed-page-count edit can otherwise
  look smaller than a harmless font tweak. Always check summary.txt for those
  lines, not just the total.

  The actual per-pixel comparison is a small compiled C# helper (via
  Add-Type -TypeDefinition, using the same in-box compiler BcRender.cs is
  built with -- no SDK needed), not GetPixel (a per-pixel interop call, ~a
  minute a page) and not a raw PowerShell foreach over a multi-megapixel
  byte array (slow interpreter loop). LockBits + Marshal.Copy hands the
  compiled code a plain managed byte[] to walk at JIT speed.

.PARAMETER BaselineDir
  Directory of page-N.png to compare against.

.PARAMETER CandidateDir
  Directory of page-N.png being checked.

.PARAMETER Out
  Directory to write page-N.png (highlighted) + summary.txt into.

.EXAMPLE
  .\diff.ps1 render\baseline render\pages -Out render\diff
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$BaselineDir,
    [Parameter(Mandatory = $true, Position = 1)] [string]$CandidateDir,
    [Parameter(Mandatory = $true)] [string]$Out
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class PngDiff
{
    // Returns the changed-pixel count; writes the highlighted diff (an exact
    // copy of the candidate image, changed pixels painted opaque red) to
    // diffPath.
    public static int DiffAndHighlight(string baselinePath, string candidatePath, string diffPath)
    {
        using (Bitmap rawA = new Bitmap(baselinePath))
        using (Bitmap rawB = new Bitmap(candidatePath))
        {
            int width = Math.Max(rawA.Width, rawB.Width);
            int height = Math.Max(rawA.Height, rawB.Height);

            // Pad to the union size on a white canvas -- same as pdfdiff.py --
            // so mismatched page sizes still produce a visual diff instead of
            // throwing. Also normalizes both to the same pixel format
            // (Format32bppArgb): our own renderer and the WinRT PDF
            // rasteriser don't necessarily agree on source PNG pixel format.
            using (Bitmap a = new Bitmap(width, height, PixelFormat.Format32bppArgb))
            using (Bitmap b = new Bitmap(width, height, PixelFormat.Format32bppArgb))
            {
                using (Graphics g = Graphics.FromImage(a)) { g.Clear(Color.White); g.DrawImage(rawA, 0, 0); }
                using (Graphics g = Graphics.FromImage(b)) { g.Clear(Color.White); g.DrawImage(rawB, 0, 0); }

                Rectangle rect = new Rectangle(0, 0, width, height);
                BitmapData da = a.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
                BitmapData db = b.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
                try
                {
                    // Stride is NOT Width * 4 -- it's padded to a 4-byte
                    // boundary and can be larger. Index using Stride, never
                    // assume tight packing.
                    int strideA = da.Stride, strideB = db.Stride;
                    byte[] bytesA = new byte[strideA * height];
                    byte[] bytesB = new byte[strideB * height];
                    Marshal.Copy(da.Scan0, bytesA, 0, bytesA.Length);
                    Marshal.Copy(db.Scan0, bytesB, 0, bytesB.Length);

                    int changed = 0;
                    byte[] outBytes = new byte[strideB * height];
                    Array.Copy(bytesB, outBytes, bytesB.Length);

                    for (int y = 0; y < height; y++)
                    {
                        int rowA = y * strideA;
                        int rowB = y * strideB;
                        for (int x = 0; x < width; x++)
                        {
                            int ia = rowA + x * 4;
                            int ib = rowB + x * 4;
                            bool diff = bytesA[ia] != bytesB[ib] || bytesA[ia + 1] != bytesB[ib + 1] ||
                                        bytesA[ia + 2] != bytesB[ib + 2] || bytesA[ia + 3] != bytesB[ib + 3];
                            if (diff)
                            {
                                changed++;
                                // Format32bppArgb is stored B,G,R,A in memory
                                // (little-endian) -- this paints opaque red.
                                outBytes[ib] = 0; outBytes[ib + 1] = 0; outBytes[ib + 2] = 255; outBytes[ib + 3] = 255;
                            }
                        }
                    }

                    using (Bitmap outBmp = new Bitmap(width, height, PixelFormat.Format32bppArgb))
                    {
                        BitmapData dOut = outBmp.LockBits(rect, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
                        try { Marshal.Copy(outBytes, 0, dOut.Scan0, outBytes.Length); }
                        finally { outBmp.UnlockBits(dOut); }
                        outBmp.Save(diffPath, ImageFormat.Png);
                    }
                    return changed;
                }
                finally
                {
                    a.UnlockBits(da);
                    b.UnlockBits(db);
                }
            }
        }
    }
}
'@ -ReferencedAssemblies System.Drawing.dll

function Get-PageNumber([string]$fileName) {
    if ($fileName -match '^page-(\d+)\.png$') { return [int]$Matches[1] }
    return [int]::MaxValue
}

function Get-PageFileNames([string]$dir) {
    if (-not (Test-Path $dir)) { return @() }
    Get-ChildItem -Path $dir -Filter 'page-*.png' -File |
        Where-Object { $_.Name -match '^page-\d+\.png$' } |
        ForEach-Object { $_.Name }
}

$baselineNames = @{}
foreach ($n in (Get-PageFileNames $BaselineDir)) { $baselineNames[$n] = $true }
$candidateNames = @{}
foreach ($n in (Get-PageFileNames $CandidateDir)) { $candidateNames[$n] = $true }

$allNames = @($baselineNames.Keys) + @($candidateNames.Keys) |
    Select-Object -Unique | Sort-Object { Get-PageNumber $_ }

New-Item -ItemType Directory -Force -Path $Out | Out-Null

$summaryLines = New-Object System.Collections.Generic.List[string]
$totalChanged = 0
$anyPage = $false
$pageCountChanged = $false

foreach ($name in $allNames) {
    $anyPage = $true
    if (-not $baselineNames.ContainsKey($name)) {
        $summaryLines.Add("WARNING: NEW PAGE $name (not in baseline -- contributes 0 to the pixel total below, but is not a clean diff)")
        $pageCountChanged = $true
        continue
    }
    if (-not $candidateNames.ContainsKey($name)) {
        $summaryLines.Add("WARNING: MISSING PAGE $name (present in baseline, not in candidate -- contributes 0 to the pixel total below, but is not a clean diff)")
        $pageCountChanged = $true
        continue
    }
    $baselinePath = Join-Path $BaselineDir $name
    $candidatePath = Join-Path $CandidateDir $name
    $diffPath = Join-Path $Out $name
    $changed = [PngDiff]::DiffAndHighlight($baselinePath, $candidatePath, $diffPath)
    $totalChanged += $changed
    # Format into a variable first -- inside a method-call arg list like
    # .Add(...), a bare `-f $a, $b` splits at the comma as two arguments to
    # Add() instead of one array argument to -f, so -f only ever sees $a.
    $line = "{0,10} changed px  <- {1}" -f $changed, $name
    $summaryLines.Add($line)
}

$totalLine = "{0,10} changed px  <- TOTAL" -f $totalChanged
$summaryLines.Add($totalLine)
if ($pageCountChanged) {
    $summaryLines.Add("WARNING: page count differs between baseline and candidate -- the pixel total above does NOT reflect the full change. See the NEW PAGE / MISSING PAGE lines.")
}

$summaryText = ($summaryLines -join "`n") + "`n"
[System.IO.File]::WriteAllText((Join-Path $Out 'summary.txt'), $summaryText, (New-Object System.Text.UTF8Encoding($false)))
Write-Host $summaryText -NoNewline

if (-not $anyPage) {
    Write-Error "no pages found in either directory"
    exit 1
}
