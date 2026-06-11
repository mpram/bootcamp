Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -TenantId 'fb860ff3-f0dc-4d1f-990f-ec4c91451ea6' -Scopes 'AppCatalog.ReadWrite.All' -NoWelcome

$appId = 'c223805e-1c33-4b50-8cee-38fd837b8b11'  # from Conflict error
$bytes = [System.IO.File]::ReadAllBytes('c:\contoso-travel-concierge\travel-concierge.zip')

try {
    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/$appId/appDefinitions" `
        -ContentType 'application/zip' `
        -Body $bytes `
        -OutputType PSObject | ConvertTo-Json -Depth 8
}
catch {
    "=== EXCEPTION ==="
    $_.Exception.Message
    "=== ERROR DETAILS ==="
    $_.ErrorDetails.Message
}
