Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -TenantId 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6' -Scopes 'AppCatalog.Read.All' -NoWelcome
$externals = @('c0a17050-7e34-4a5e-9b1d-1f3e1c8a4b22', '9d7c2a40-8b15-4d72-bf3a-2e6f9c7e1d44')
foreach ($e in $externals) {
    "=== externalId $e ==="
    try {
        $r = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps?`$filter=externalId eq '$e'" -OutputType PSObject
        if ($r.value.Count -eq 0) {
            "  not found via filter"
        } else {
            $r.value | ForEach-Object { "  id=$($_.id) name=$($_.displayName) dist=$($_.distributionMethod)" }
        }
    } catch {
        "  ERR $($_.Exception.Message)"
    }
}
"=== full list of org apps ==="
$apps = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps?`$filter=distributionMethod eq 'organization'&`$top=100" -OutputType PSObject).value
$apps | ForEach-Object { "  $($_.id) | $($_.displayName) | ext=$($_.externalId)" }
"total: $($apps.Count)"
