<#
.SYNOPSIS
  Pulls Copilot Studio conversation transcripts (full prompt + response content)
  from Dataverse and optionally pushes parsed messages into the
  WildpawsConversationContent_CL custom table in Sentinel/LAW.

.PREREQ
  - Logged into az CLI as a user with at least System User access to the
    target Dataverse environment(s) and Monitoring Metrics Publisher on the
    DCR (dcr-wildpaws-transcripts).
  - Copilot Studio conversation transcript logging enabled per agent
    (Settings -> Security -> Authentication / Advanced -> "Enable conversation
    transcript storage in Dataverse").

.NOTES
  Schema:  https://learn.microsoft.com/dataverse/conversationtranscript
  content  field is a JSON Bot-Framework activity log; we flatten it to one
  row per activity (message / event / trace) so KQL can search the text.
#>

param(
  [string[]]$OrgUrl = @(
    'https://wildpawsprod.api.crm.dynamics.com',
    'https://org79bc5c37.api.crm.dynamics.com'
  ),
  [int]$LookbackHours = 24,
  [int]$MaxTranscripts = 200,
  [switch]$PushToSentinel,
  [string]$DceIngestionEndpoint = 'https://dce-wildpaws-rz9w.eastus-1.ingest.monitor.azure.com',
  [string]$DcrImmutableId       = 'dcr-3d2f752de47c4c53bcf26d08f0573909',
  [string]$StreamName           = 'Custom-WildpawsConversationContent_CL',
  [int]$MaxTextChars            = 8000   # truncate long messages to keep payload sane
)

# Resolve env display names for the rows we emit
$ppTok  = az account get-access-token --resource 'https://service.powerapps.com/' --query accessToken -o tsv
$ppHdr  = @{ Authorization = "Bearer $ppTok" }
$envMap = @{}
try {
  $envs = Invoke-RestMethod -Method GET -Headers $ppHdr -Uri 'https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments?api-version=2021-04-01'
  foreach ($e in $envs.value) {
    $iu = $e.properties.linkedEnvironmentMetadata.instanceApiUrl
    if ($iu) { $envMap[$iu.TrimEnd('/')] = @{ Id=$e.name; Name=$e.properties.displayName } }
  }
} catch {
  Write-Host "WARN: could not list PP envs ($($_.Exception.Message))" -ForegroundColor Yellow
}

$cutoff = (Get-Date).ToUniversalTime().AddHours(-$LookbackHours)
$cutoffIso = $cutoff.ToString('o')

$allRows = New-Object System.Collections.Generic.List[object]

foreach ($org in $OrgUrl) {
  $org = $org.TrimEnd('/')
  $envInfo = $envMap[$org]
  $envId   = if ($envInfo) { $envInfo.Id }   else { $null }
  $envName = if ($envInfo) { $envInfo.Name } else { $org }

  Write-Host "`n=== $envName ($org) ===" -ForegroundColor Cyan

  $dvTok = az account get-access-token --resource $org --query accessToken -o tsv
  $hdr = @{
    Authorization       = "Bearer $dvTok"
    Accept              = 'application/json'
    'OData-MaxVersion'  = '4.0'
    'OData-Version'     = '4.0'
    Prefer              = 'odata.maxpagesize=200'
  }

  $filter = "createdon gt $cutoffIso"
  $select = 'conversationtranscriptid,name,schematype,createdon,conversationstarttime,content,metadata,_bot_conversationtranscriptid_value'
  $uri = "$org/api/data/v9.2/conversationtranscripts?`$filter=$filter&`$select=$select&`$orderby=createdon desc&`$top=$MaxTranscripts"
  Write-Host "GET $uri" -ForegroundColor DarkGray
  try {
    $resp = Invoke-RestMethod -Method GET -Uri $uri -Headers $hdr -ErrorAction Stop
  } catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) { Write-Host "  $($_.ErrorDetails.Message)" -ForegroundColor Red }
    continue
  }

  Write-Host "  transcripts fetched: $($resp.value.Count)" -ForegroundColor Green
  if ($resp.value.Count -eq 0) { continue }

  foreach ($t in $resp.value) {
    if (-not $t.content) { continue }
    try { $parsed = $t.content | ConvertFrom-Json -ErrorAction Stop } catch { continue }
    $activities = $parsed.activities
    if (-not $activities) { continue }

    # Try to pull a friendly agent name out of metadata, fall back to env name
    $agent = $null
    if ($t.metadata) {
      try {
        $meta = $t.metadata | ConvertFrom-Json
        $agent = $meta.botName
      } catch {}
    }

    foreach ($a in $activities) {
      $role = switch ($a.from.role) {
        0       { 'bot' }
        1       { 'user' }
        2       { 'skill' }
        default { "$($a.from.role)" }
      }

      $text = $a.text
      if (-not $text -and $a.value) {
        try { $text = ($a.value | ConvertTo-Json -Compress -Depth 6) } catch { $text = "$($a.value)" }
      }
      if (-not $text) { $text = '' }
      $orig = $text.Length
      if ($text.Length -gt $MaxTextChars) {
        $text = $text.Substring(0, $MaxTextChars) + " ...[truncated $($orig - $MaxTextChars) chars]"
      }

      $ts = if ($a.timestampMs) {
              ([DateTimeOffset]::FromUnixTimeMilliseconds([int64]$a.timestampMs)).UtcDateTime
            } elseif ($a.timestamp -is [int64] -or $a.timestamp -is [int]) {
              ([DateTimeOffset]::FromUnixTimeSeconds([int64]$a.timestamp)).UtcDateTime
            } elseif ($a.timestamp) {
              [datetime]$a.timestamp
            } else {
              [datetime]$t.createdon
            }

      $allRows.Add([pscustomobject]@{
        TimeGenerated         = $ts.ToString('o')
        TranscriptId          = "$($t.conversationtranscriptid)"
        ConversationStartTime = ([datetime]$t.conversationstarttime).ToUniversalTime().ToString('o')
        AgentName             = if ($agent) { $agent } else { '(unknown)' }
        EnvironmentId         = "$envId"
        EnvironmentName       = "$envName"
        FromRole              = $role
        FromId                = "$($a.from.id)"
        UserAadId             = "$($a.from.aadObjectId)"
        MessageType           = "$($a.type)"
        ActivityId            = "$($a.id)"
        ChannelId             = "$($a.channelId)"
        Text                  = $text
        TextLength            = $orig
      })
    }
  }
}

if ($allRows.Count -eq 0) {
  Write-Host "`nNo transcript activities to emit." -ForegroundColor Yellow
  return
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$allRows | Group-Object FromRole | Select-Object @{n='Role';e={$_.Name}}, Count | Format-Table -AutoSize
$allRows | Group-Object MessageType | Select-Object @{n='Type';e={$_.Name}}, Count | Format-Table -AutoSize
Write-Host "Activities to push: $($allRows.Count)" -ForegroundColor Green

# Show a few user prompts + bot replies for sanity
Write-Host "`n--- Sample (last 6 user/bot messages) ---" -ForegroundColor Cyan
$allRows |
  Where-Object { $_.MessageType -eq 'message' -and ($_.FromRole -eq 'user' -or $_.FromRole -eq 'bot') } |
  Sort-Object TimeGenerated -Descending |
  Select-Object -First 6 TimeGenerated, FromRole, @{n='Text';e={ if ($_.Text.Length -gt 120) { $_.Text.Substring(0,120)+'...' } else { $_.Text } }} |
  Format-Table -AutoSize -Wrap

if (-not $PushToSentinel) {
  Write-Host "`nDry run. Add -PushToSentinel to ship to LAW." -ForegroundColor Yellow
  return
}

Write-Host "`n=== Pushing to Sentinel ($StreamName) ===" -ForegroundColor Cyan
$ingTok = az account get-access-token --resource 'https://monitor.azure.com' --query accessToken -o tsv
$ingHdr = @{ Authorization = "Bearer $ingTok"; 'Content-Type' = 'application/json' }
$ingUri = "$DceIngestionEndpoint/dataCollectionRules/$DcrImmutableId/streams/$StreamName`?api-version=2023-01-01"

# Batch in chunks of 200 to keep payload <1MB
$batchSize = 200
$pushed = 0
for ($i = 0; $i -lt $allRows.Count; $i += $batchSize) {
  $chunk = $allRows[$i..([Math]::Min($i+$batchSize-1, $allRows.Count-1))]
  $body  = $chunk | ConvertTo-Json -Depth 5 -AsArray
  $resp  = Invoke-WebRequest -Method POST -Uri $ingUri -Headers $ingHdr -Body $body -UseBasicParsing
  $pushed += $chunk.Count
  Write-Host "  batch $($i / $batchSize + 1): $($chunk.Count) rows -> HTTP $($resp.StatusCode)" -ForegroundColor DarkGray
}
Write-Host "Pushed $pushed activities, OK" -ForegroundColor Green
Write-Host "Tip: queryable in ~3-5 min: WildpawsConversationContent_CL | take 10" -ForegroundColor DarkGray
