param(
  [string]$OrgUrl = 'https://org79bc5c37.api.crm.dynamics.com'
)
$tok = az account get-access-token --resource $OrgUrl --query accessToken -o tsv
$h = @{
  Authorization = "Bearer $tok"
  Accept        = 'application/json'
  'OData-MaxVersion' = '4.0'
  'OData-Version'    = '4.0'
}
# Probe schema first - just get top 2
$uri = "$OrgUrl/api/data/v9.2/conversationtranscripts?`$top=2&`$orderby=createdon desc"
Write-Host "GET $uri" -ForegroundColor Cyan
try {
  $r = Invoke-RestMethod -Method GET -Uri $uri -Headers $h
  Write-Host "Rows returned: $($r.value.Count)" -ForegroundColor Green
  if ($r.value.Count -gt 0) {
    Write-Host "`n--- First row keys ---" -ForegroundColor Yellow
    $r.value[0].PSObject.Properties.Name | Sort-Object | ForEach-Object { Write-Host "  $_" }
    Write-Host "`n--- Sample (truncated) ---" -ForegroundColor Yellow
    $first = $r.value[0]
    [pscustomobject]@{
      conversationtranscriptid = $first.conversationtranscriptid
      name                     = $first.name
      schematype               = $first.schematype
      botid                    = $first.'_bot_botid_value'
      createdon                = $first.createdon
      contentLength            = if ($first.content) { $first.content.Length } else { 0 }
      contentPreview           = if ($first.content) { $first.content.Substring(0, [Math]::Min(500, $first.content.Length)) } else { '(null)' }
    } | Format-List
  }
} catch {
  Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
  if ($_.ErrorDetails) { Write-Host $_.ErrorDetails.Message }
}
