Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -TenantId 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6' -Scopes 'AppCatalog.Read.All' -NoWelcome

$ids = @('80f6aeb2-6777-4d77-b8ba-09b6d0f61794')
$exts = @('673f44d1-a8b9-4180-b1ac-bf96cb2ad6ee')

foreach ($i in 1..6) {
    "=== retry $i (wait $($i*15)s) ==="
    Start-Sleep -Seconds 15

    foreach ($id in $ids) {
        try {
            $a = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/$id?`$expand=appDefinitions" -OutputType PSObject
            "  GET-by-id ${id}: name=$($a.displayName)"
            $a.appDefinitions | ForEach-Object { "    def: ver=$($_.version) state=$($_.publishingState)" }
        } catch {
            "  GET-by-id ${id}: 404"
        }
    }
    foreach ($e in $exts) {
        $r = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps?`$filter=externalId eq '$e'&`$expand=appDefinitions" -OutputType PSObject
        "  filter externalId=$($e.Substring(0,8)): count=$($r.value.Count)"
        $r.value | ForEach-Object {
            "    id=$($_.id) name=$($_.displayName) dist=$($_.distributionMethod)"
            $_.appDefinitions | ForEach-Object { "      def: ver=$($_.version) state=$($_.publishingState)" }
        }
    }
}
