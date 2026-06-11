Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -TenantId 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6' -Scopes 'AppCatalog.Read.All' -NoWelcome

# Search broader: also submitted/pending
$externals = @('c0a17050-7e34-4a5e-9b1d-1f3e1c8a4b22', '9d7c2a40-8b15-4d72-bf3a-2e6f9c7e1d44')
foreach ($e in $externals) {
    "=== externalId $e ==="
    $url = "https://graph.microsoft.com/beta/appCatalogs/teamsApps?`$filter=externalId eq '$e'&`$expand=appDefinitions"
    try {
        $r = Invoke-MgGraphRequest -Method GET -Uri $url -OutputType PSObject
        if ($r.value.Count -eq 0) {
            "  (not found in beta)"
        } else {
            $r.value | ForEach-Object {
                "  id=$($_.id) name=$($_.displayName) dist=$($_.distributionMethod)"
                foreach ($d in $_.appDefinitions) {
                    "    def: id=$($d.id) ver=$($d.version) state=$($d.publishingState)"
                }
            }
        }
    } catch { "  ERR $($_.Exception.Message)" }
}

"`n=== listing all apps with displayName matching Travel or Expense ==="
$url = "https://graph.microsoft.com/beta/appCatalogs/teamsApps?`$filter=distributionMethod eq 'organization'&`$expand=appDefinitions"
try {
    $r = Invoke-MgGraphRequest -Method GET -Uri $url -OutputType PSObject
    $r.value | Where-Object { $_.displayName -match 'Travel|Expense|Concierge|Buddy' } | ForEach-Object {
        "  id=$($_.id) name=$($_.displayName)"
        foreach ($d in $_.appDefinitions) {
            "    def: ver=$($d.version) state=$($d.publishingState)"
        }
    }
    "total org apps: $($r.value.Count)"
} catch { "ERR $($_.Exception.Message)" }
