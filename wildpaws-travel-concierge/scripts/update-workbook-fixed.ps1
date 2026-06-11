$sub='a3ac2636-e819-4d0a-ba76-32e6645f2b85'
$rg='rg-wildpaws-telemetry'
$id='a390c0a1-8f2b-5bf8-a4f0-52b34f6fe760'
$url = "https://management.azure.com/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.Insights/workbooks/$id`?api-version=2023-06-01"
$current = (az rest --method GET --url $url) | ConvertFrom-Json
$serialized = Get-Content scripts/workbook-serialized.json -Raw -Encoding utf8
$put = @{
  location   = $current.location
  kind       = $current.kind
  properties = @{
    displayName    = $current.tags.'hidden-title'
    category       = $current.properties.category
    sourceId       = $current.properties.sourceId
    serializedData = $serialized
    version        = '1.0'
  }
  tags       = $current.tags
} | ConvertTo-Json -Depth 20
$tmp = New-TemporaryFile
[System.IO.File]::WriteAllText($tmp.FullName, $put, [System.Text.UTF8Encoding]::new($false))
az rest --method PUT --url $url --body "@$($tmp.FullName)" --headers "Content-Type=application/json" --query "{name:name,displayName:properties.displayName,modified:properties.timeModified}" -o json
Remove-Item $tmp.FullName -Force
