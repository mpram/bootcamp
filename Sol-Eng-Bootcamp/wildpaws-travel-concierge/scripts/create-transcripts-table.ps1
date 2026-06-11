$sub = 'a3ac2636-e819-4d0a-ba76-32e6645f2b85'
$rg  = 'rg-wildpaws-telemetry'
$ws  = 'law-wildpaws-dev'
$url = "https://management.azure.com/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.OperationalInsights/workspaces/$ws/tables/WildpawsConversationContent_CL?api-version=2023-09-01"
Write-Host "PUT $url" -ForegroundColor Cyan
az rest --method PUT --url $url --body '@scripts/custom-table-transcripts.json' --headers "Content-Type=application/json"
