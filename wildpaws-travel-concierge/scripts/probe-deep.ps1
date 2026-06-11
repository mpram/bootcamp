Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -TenantId 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6' -Scopes 'AppCatalog.Read.All' -NoWelcome
# Try beta with the returned id
$id = '80f6aeb2-6777-4d77-b8ba-09b6d0f61794'
foreach ($base in @('https://graph.microsoft.com/v1.0','https://graph.microsoft.com/beta')) {
    "=== $base ==="
    try {
        $a = Invoke-MgGraphRequest -Method GET -Uri "$base/appCatalogs/teamsApps/$id" -OutputType PSObject
        "  OK: $($a | ConvertTo-Json -Depth 5)"
    } catch {
        "  ERR: $($_.Exception.Message)"
    }
}
# Search for the displayName + externalId via beta
"=== beta filter on displayName Expense Buddy ==="
$url = "https://graph.microsoft.com/beta/appCatalogs/teamsApps?`$filter=displayName eq 'Expense Buddy'&`$expand=appDefinitions"
$r = Invoke-MgGraphRequest -Method GET -Uri $url -OutputType PSObject
"  count: $($r.value.Count)"
$r.value | ForEach-Object {
    "  id=$($_.id) ext=$($_.externalId) dist=$($_.distributionMethod)"
    $_.appDefinitions | ForEach-Object { "    def: ver=$($_.version) state=$($_.publishingState)" }
}
