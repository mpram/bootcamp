Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -TenantId 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6' -Scopes 'AppCatalog.Read.All' -NoWelcome

# Probe the original Travel Concierge externalId (the one that conflicted)
$exts = @(
  'c0a17050-7e34-4a5e-9b1d-1f3e1c8a4b21',  # original TC
  'c0a17050-7e34-4a5e-9b1d-1f3e1c8a4b22',  # 2nd TC
  '4512e07e-b48b-453a-bcd1-a62c3689493c',  # 3rd TC (new guid)
  '9d7c2a40-8b15-4d72-bf3a-2e6f9c7e1d44',  # original EB
  '673f44d1-a8b9-4180-b1ac-bf96cb2ad6ee'   # 2nd EB
)
foreach ($e in $exts) {
    "=== externalId $e ==="
    foreach ($base in @('https://graph.microsoft.com/v1.0', 'https://graph.microsoft.com/beta')) {
        $url = "$base/appCatalogs/teamsApps?`$filter=externalId eq '$e'&`$expand=appDefinitions"
        try {
            $r = Invoke-MgGraphRequest -Method GET -Uri $url -OutputType PSObject
            "  $base count=$($r.value.Count)"
            $r.value | ForEach-Object {
                "    id=$($_.id) name=$($_.displayName) dist=$($_.distributionMethod)"
                $_.appDefinitions | ForEach-Object { "      ver=$($_.version) state=$($_.publishingState)" }
            }
        } catch { "  $base ERR: $($_.Exception.Message)" }
    }
}
