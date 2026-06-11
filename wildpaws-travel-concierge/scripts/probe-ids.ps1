Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -TenantId 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6' -Scopes 'AppCatalog.Read.All' -NoWelcome
Start-Sleep -Seconds 25
foreach ($id in @('fa1de6e3-2d9b-42b2-bb86-5680b7b77061', '58025b61-8c3a-42ae-a621-b56ea6ceeeda')) {
    try {
        $a = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/$id" -OutputType PSObject
        $name = $a.displayName
        $dist = $a.distributionMethod
        "OK $id | $name | $dist"
    } catch {
        "ERR $id : $($_.Exception.Message)"
    }
}
