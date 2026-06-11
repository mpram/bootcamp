# Two-phase deploy:
#   1) Upload Expense Buddy first (so we know its teamsAppId)
#   2) Patch Travel Concierge's declarativeAgent.json worker_agents[0].id with that teamsAppId
#   3) Repack Travel Concierge, upload
#
# Requires Microsoft.Graph.Authentication module and AppCatalog.ReadWrite.All scope.
# Run set-icons.ps1 and package.ps1 first.

param(
    [string]$TenantId = 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -TenantId $TenantId -Scopes 'AppCatalog.ReadWrite.All' -NoWelcome

function Upload-TeamsApp {
    param([string]$ZipPath)
    $bytes = [System.IO.File]::ReadAllBytes($ZipPath)
    # Try POST first (create), fall back to PUT (update) on conflict
    try {
        $resp = Invoke-MgGraphRequest -Method POST `
            -Uri 'https://graph.microsoft.com/v1.0/appCatalogs/teamsApps?$select=id,displayName,externalId' `
            -ContentType 'application/zip' `
            -Body $bytes `
            -OutputType PSObject
        return $resp
    } catch {
        # If it already exists, find it by manifest id (externalId) and PUT-update
        $manifestPath = Join-Path $env:TEMP "manifest-$([guid]::NewGuid()).json"
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        try {
            $entry = $zip.Entries | Where-Object { $_.FullName -eq 'manifest.json' } | Select-Object -First 1
            $sr = New-Object System.IO.StreamReader($entry.Open())
            $manifestText = $sr.ReadToEnd()
            $sr.Close()
        } finally { $zip.Dispose() }
        $externalId = (ConvertFrom-Json $manifestText).id
        Write-Host "  POST failed, looking up existing app by externalId $externalId"
        $existing = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps?`$filter=externalId eq '$externalId'&`$select=id,displayName,externalId" `
            -OutputType PSObject
        $app = $existing.value | Select-Object -First 1
        if (-not $app) { throw "Cannot create or find Teams app for $ZipPath" }
        # Update the latest appDefinition
        $defs = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/$($app.id)/appDefinitions" `
            -OutputType PSObject
        $latest = $defs.value | Sort-Object version | Select-Object -Last 1
        $uri = "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/$($app.id)/appDefinitions/$($latest.id)?`$select=id,displayName,externalId"
        $resp = Invoke-MgGraphRequest -Method PUT `
            -Uri $uri `
            -ContentType 'application/zip' `
            -Body $bytes `
            -OutputType PSObject
        $resp | Add-Member -NotePropertyName 'id' -NotePropertyValue $app.id -Force -PassThru
        return $resp
    }
}

Write-Host ""
Write-Host "=== Phase 1: deploy Expense Buddy ==="
$ebZip = Join-Path $root 'expense-buddy.zip'
$eb = Upload-TeamsApp -ZipPath $ebZip
Write-Host "  Expense Buddy teamsAppId: $($eb.id)"
Write-Host "  Expense Buddy displayName: $($eb.displayName)"

Write-Host ""
Write-Host "=== Phase 2: patch Travel Concierge worker_agents with $($eb.id) ==="
$daPath = Join-Path $root 'travel-concierge-app\declarativeAgent.json'
$da = Get-Content $daPath -Raw | ConvertFrom-Json
$da.worker_agents[0].id = $eb.id
$da | ConvertTo-Json -Depth 32 | Set-Content $daPath -Encoding UTF8 -NoNewline
Write-Host "  patched $daPath"

Write-Host ""
Write-Host "=== Phase 3: repack Travel Concierge ==="
& (Join-Path $PSScriptRoot 'package.ps1') | Out-Host

Write-Host ""
Write-Host "=== Phase 4: deploy Travel Concierge ==="
$tcZip = Join-Path $root 'travel-concierge.zip'
$tc = Upload-TeamsApp -ZipPath $tcZip
Write-Host "  Travel Concierge teamsAppId: $($tc.id)"
Write-Host "  Travel Concierge displayName: $($tc.displayName)"

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Both apps are now in the tenant app catalog."
Write-Host "View in M365 admin: https://admin.cloud.microsoft/?/#/agents/all"
Write-Host "Try in M365 Copilot: https://m365.cloud.microsoft/"
