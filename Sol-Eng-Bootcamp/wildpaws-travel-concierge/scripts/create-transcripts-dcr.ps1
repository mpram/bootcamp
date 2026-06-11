$sub = 'a3ac2636-e819-4d0a-ba76-32e6645f2b85'
$rg  = 'rg-wildpaws-telemetry'
$dcr = 'dcr-wildpaws-transcripts'
$url = "https://management.azure.com/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.Insights/dataCollectionRules/$dcr`?api-version=2023-03-11"
Write-Host "PUT $url" -ForegroundColor Cyan
$body = Get-Content -Raw scripts/dcr-transcripts.json
$tmp = New-TemporaryFile
$body | Set-Content -Path $tmp.FullName -Encoding utf8
az rest --method PUT --url $url --body "@$($tmp.FullName)" --headers "Content-Type=application/json" --query "{id:id, state:properties.provisioningState, immutableId:properties.immutableId}" -o json
Remove-Item $tmp.FullName -Force
