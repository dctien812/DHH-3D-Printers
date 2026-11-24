param([string]$SrcDir, [string]$OutDir)
# Draws numbered markers and a legend on the Monolith gantry renders (1600x1200 working size).
Add-Type -AssemblyName System.Drawing
$cfg = Get-Content (Join-Path $PSScriptRoot 'annot.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$purple = [System.Drawing.Color]::FromArgb(190, 90, 255); $orange = [System.Drawing.Color]::FromArgb(255, 150, 40); $white = [System.Drawing.Color]::White
# n, x, y, radius, colour
$marks = @(
    @('1', 345, 215, 95, $purple), @('2', 1255, 210, 95, $orange),
    @('3', 290, 565, 75, $white), @('4', 1300, 560, 75, $white),
    @('5', 405, 1010, 105, $white), @('6', 1195, 1010, 105, $white),
    @('7', 800, 568, 55, $white))
foreach ($k in 'v24', 'trident') {
    $c = $cfg.$k
    $img = [System.Drawing.Image]::FromFile((Join-Path $SrcDir $c.src))
    $bm = New-Object System.Drawing.Bitmap 1600, 1510
    $g = [System.Drawing.Graphics]::FromImage($bm); $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.TextRenderingHint = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::FromArgb(28, 28, 32)); $g.DrawImage($img, 0, 0, 1600, 1200); $img.Dispose()
    $fNum = New-Object System.Drawing.Font 'Segoe UI', 26, ([System.Drawing.FontStyle]::Bold)
    $fTitle = New-Object System.Drawing.Font 'Segoe UI', 17, ([System.Drawing.FontStyle]::Bold)
    $fLeg = New-Object System.Drawing.Font 'Segoe UI', 13
    $fLegB = New-Object System.Drawing.Font 'Segoe UI', 13, ([System.Drawing.FontStyle]::Bold)
    foreach ($m in $marks) {
        $pen = New-Object System.Drawing.Pen $m[4], 6
        $g.DrawEllipse($pen, $m[1] - $m[3], $m[2] - $m[3], 2 * $m[3], 2 * $m[3])
        $bx = $m[1] + [int]($m[3] * 0.72); $by = $m[2] - [int]($m[3] * 0.72) - 46
        $g.FillEllipse((New-Object System.Drawing.SolidBrush $m[4]), $bx - 4, $by, 50, 50)
        $sz = $g.MeasureString($m[0], $fNum)
        $g.DrawString($m[0], $fNum, [System.Drawing.Brushes]::Black, $bx + 21 - $sz.Width / 2, $by + 25 - $sz.Height / 2)
    }
    # title bar
    $g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(225, 20, 20, 24))), 0, 0, 1600, 44)
    $ts = $g.MeasureString($c.title, $fTitle); $g.DrawString($c.title, $fTitle, [System.Drawing.Brushes]::White, (1600 - $ts.Width) / 2, 6)
    # legend in the empty middle of the render
    $lx = 40; $ly = 1208; $lw = 1520; $lh = 30 * $c.legend.Count + 20
    $g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 20, 20, 24))), $lx, $ly, $lw, $lh)
    $g.DrawRectangle((New-Object System.Drawing.Pen ([System.Drawing.Color]::Gray), 1), $lx, $ly, $lw, $lh)
    $y = $ly + 10; $i = 0
    foreach ($line in $c.legend) {
        $font = $fLeg; $brush = [System.Drawing.Brushes]::White
        if ($i -ge $c.legend.Count - 2) { $font = $fLegB; $brush = [System.Drawing.Brushes]::Gold }
        if ($i -lt 2) { $brush = [System.Drawing.Brushes]::LightGray }
        $g.DrawString($line, $font, $brush, $lx + 12, $y); $y += 30; $i++
    }
    $out = Join-Path $OutDir $c.out
    $bm.Save($out, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bm.Dispose()
    Write-Output $out
}
