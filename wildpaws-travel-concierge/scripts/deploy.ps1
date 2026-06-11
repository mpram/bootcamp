Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -TenantId 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6' -Scopes 'AppCatalog.ReadWrite.All','Directory.ReadWrite.All' -NoWelcome
"scopes: $((Get-MgContext).Scopes -join ',')"

# Bump externalIds again
$path = 'c:\contoso-travel-concierge\travel-concierge-app\manifest.json'
$m = Get-Content $path -Raw | ConvertFrom-Json
$m.id = [guid]::NewGuid().ToString()
$m | ConvertTo-Json -Depth 32 | Set-Content $path -Encoding UTF8 -NoNewline
"TC manifest id -> $($m.id)"

$path2 = 'c:\contoso-travel-concierge\expense-buddy-app\manifest.json'
$m2 = Get-Content $path2 -Raw | ConvertFrom-Json
$m2.id = [guid]::NewGuid().ToString()
$m2 | ConvertTo-Json -Depth 32 | Set-Content $path2 -Encoding UTF8 -NoNewline
"EB manifest id -> $($m2.id)"

# Repack
& 'c:\contoso-travel-concierge\scripts\package.ps1' | Out-Host

# Upload EB first
"=== POST EB with requiresReview=false ==="
$bytes = [System.IO.File]::ReadAllBytes('c:\contoso-travel-concierge\expense-buddy.zip')
try {
    $eb = Invoke-MgGraphRequest -Method POST `
        -Uri 'https://graph.microsoft.com/v1.0/appCatalogs/teamsApps?requiresReview=false' `
        -ContentType 'application/zip' -Body $bytes -OutputType PSObject
    $eb | ConvertTo-Json -Depth 4
}
catch {
    "EB ERR: $($_.Exception.Message)"
    "EB DETAILS: $($_.ErrorDetails.Message)"
    return
}

# Verify EB is visible
Start-Sleep -Seconds 10
$verify = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps?`$filter=externalId eq '$($m2.id)'&`$expand=appDefinitions" -OutputType PSObject
"verify EB: count=$($verify.value.Count)"
$verify.value | ForEach-Object {
    "  id=$($_.id) name=$($_.displayName)"
    $_.appDefinitions | ForEach-Object { "    state=$($_.publishingState)" }
}

if ($verify.value.Count -eq 0) {
    "EB not visible after publish — aborting"
    return
}

$ebId = $verify.value[0].id
"EB teamsAppId: $ebId"

# Patch TC declarativeAgent with EB id
$daPath = 'c:\contoso-travel-concierge\travel-concierge-app\declarativeAgent.json'
$da = Get-Content $daPath -Raw | ConvertFrom-Json
$da.worker_agents[0].id = $ebId
$da | ConvertTo-Json -Depth 32 | Set-Content $daPath -Encoding UTF8 -NoNewline
"patched TC worker_agents -> $ebId"

# Repack TC
& 'c:\contoso-travel-concierge\scripts\package.ps1' | Out-Host

# Upload TC
"=== POST TC with requiresReview=false ==="
$bytes2 = [System.IO.File]::ReadAllBytes('c:\contoso-travel-concierge\travel-concierge.zip')
try {
    $tc = Invoke-MgGraphRequest -Method POST `
        -Uri 'https://graph.microsoft.com/v1.0/appCatalogs/teamsApps?requiresReview=false' `
        -ContentType 'application/zip' -Body $bytes2 -OutputType PSObject
    $tc | ConvertTo-Json -Depth 4
}
catch {
    "TC ERR: $($_.Exception.Message)"
    "TC DETAILS: $($_.ErrorDetails.Message)"
    return
}

Start-Sleep -Seconds 10
$verify2 = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps?`$filter=externalId eq '$($m.id)'&`$expand=appDefinitions" -OutputType PSObject
"verify TC: count=$($verify2.value.Count)"
$verify2.value | ForEach-Object {
    "  id=$($_.id) name=$($_.displayName)"
    $_.appDefinitions | ForEach-Object { "    state=$($_.publishingState)" }
}
