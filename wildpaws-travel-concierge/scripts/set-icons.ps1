# Generates branded color.png (192x192) + outline.png (32x32) for both apps.
# Run on Windows (System.Drawing only works there).

Add-Type -AssemblyName System.Drawing

function New-Icon {
    param(
        [string]$ColorPath,
        [string]$OutlinePath,
        [System.Drawing.Color]$BgColor,
        [string]$Letters,
        [string]$Tagline
    )
    # Color (192x192)
    $bmp = New-Object System.Drawing.Bitmap(192, 192)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAlias'
    $g.Clear($BgColor)
    $font = New-Object System.Drawing.Font('Segoe UI', 56, [System.Drawing.FontStyle]::Bold)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = 'Center'
    $sf.LineAlignment = 'Center'
    $g.DrawString($Letters, $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF(0, 15, 192, 100)), $sf)
    $font2 = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Regular)
    $g.DrawString($Tagline, $font2, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF(0, 120, 192, 50)), $sf)
    $bmp.Save($ColorPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()

    # Outline (32x32 transparent + white)
    $bmp2 = New-Object System.Drawing.Bitmap(32, 32)
    $g2 = [System.Drawing.Graphics]::FromImage($bmp2)
    $g2.SmoothingMode = 'AntiAlias'
    $g2.TextRenderingHint = 'AntiAlias'
    $g2.Clear([System.Drawing.Color]::Transparent)
    $font3 = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $g2.DrawString($Letters, $font3, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF(0, 6, 32, 26)), $sf)
    $bmp2.Save($OutlinePath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g2.Dispose(); $bmp2.Dispose()
    Write-Host "  wrote $ColorPath ($((Get-Item $ColorPath).Length) bytes) and $OutlinePath"
}

$root = Split-Path -Parent $PSScriptRoot
Write-Host "=== Travel Concierge icons (Microsoft blue) ==="
New-Icon `
    -ColorPath  (Join-Path $root 'travel-concierge-app\color.png') `
    -OutlinePath (Join-Path $root 'travel-concierge-app\outline.png') `
    -BgColor    ([System.Drawing.Color]::FromArgb(255, 0, 120, 212)) `
    -Letters    'TC' `
    -Tagline    'Travel'

Write-Host "=== Expense Buddy icons (Microsoft green) ==="
New-Icon `
    -ColorPath  (Join-Path $root 'expense-buddy-app\color.png') `
    -OutlinePath (Join-Path $root 'expense-buddy-app\outline.png') `
    -BgColor    ([System.Drawing.Color]::FromArgb(255, 16, 124, 16)) `
    -Letters    'EB' `
    -Tagline    'Expenses'
