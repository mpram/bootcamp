Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -TenantId 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6' -Scopes 'AppCatalog.Read.All' -NoWelcome
$ids = @('fa1de6e3-2d9b-42b2-bb86-5680b7b77061', '58025b61-8c3a-42ae-a621-b56ea6ceeeda')
foreach ($id in $ids) {
    try {
        $a = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/$id" -OutputType PSObject
        "{0,-40} {1,-25} dist={2}" -f $a.id, $a.displayName, $a.distributionMethod
        $defs = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/$id/appDefinitions" -OutputType PSObject
        $defs.value | ForEach-Object { "  ver=$($_.version) state=$($_.publishingState) name=$($_.displayName)" }
    } catch {
        "$id : $($_.Exception.Message)"
    }
}
