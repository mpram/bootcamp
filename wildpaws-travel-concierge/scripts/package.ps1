# Zips both Teams app packages into deployable .zip files.

$root = Split-Path -Parent $PSScriptRoot

function Compress-AppPackage {
    param([string]$AppDir, [string]$OutZip)

    if (-not (Test-Path (Join-Path $AppDir 'color.png'))) {
        throw "Missing color.png in $AppDir — run set-icons.ps1 first."
    }
    if (Test-Path $OutZip) { Remove-Item $OutZip -Force }

    # Top-level files
    $top = @(
        (Join-Path $AppDir 'manifest.json'),
        (Join-Path $AppDir 'color.png'),
        (Join-Path $AppDir 'outline.png'),
        (Join-Path $AppDir 'declarativeAgent.json')
    ) | Where-Object { Test-Path $_ }

    # Sub-folder (apiPlugins) — only for travel concierge
    $sub = Get-ChildItem (Join-Path $AppDir 'apiPlugins') -ErrorAction SilentlyContinue
    $all = @($top) + @($sub | ForEach-Object { $_.FullName })

    Compress-Archive -Path $all -DestinationPath $OutZip -Force
    # Compress-Archive flattens directories — recreate apiPlugins/ folder inside the zip
    if ($sub) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $tmp = Join-Path $env:TEMP "pkg-$([guid]::NewGuid())"
        Expand-Archive -Path $OutZip -DestinationPath $tmp -Force
        Remove-Item $OutZip -Force
        # Move plugin files into apiPlugins/
        $pluginsDir = Join-Path $tmp 'apiPlugins'
        New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
        foreach ($f in $sub) { Move-Item (Join-Path $tmp $f.Name) (Join-Path $pluginsDir $f.Name) -Force }
        # Repack
        [System.IO.Compression.ZipFile]::CreateFromDirectory($tmp, $OutZip)
        Remove-Item $tmp -Recurse -Force
    }
    $bytes = (Get-Item $OutZip).Length
    Write-Host "  wrote $OutZip ($bytes bytes)"
}

Write-Host "=== Packaging Travel Concierge ==="
Compress-AppPackage `
    -AppDir (Join-Path $root 'travel-concierge-app') `
    -OutZip (Join-Path $root 'travel-concierge.zip')

Write-Host "=== Packaging Expense Buddy ==="
Compress-AppPackage `
    -AppDir (Join-Path $root 'expense-buddy-app') `
    -OutZip (Join-Path $root 'expense-buddy.zip')
