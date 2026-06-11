<#
.SYNOPSIS
  Pulls Copilot Studio interactions from the M365 Unified Audit Log (Purview).
  Includes RAI verdicts, prompts, responses, and tool calls.

.PREREQ
  - ExchangeOnlineManagement PS module: Install-Module ExchangeOnlineManagement -Scope CurrentUser
  - Tenant role: "Audit Logs" or "View-Only Audit Logs" (Exchange role group), OR
                 "Audit Reader" / "Compliance Administrator" in Entra
  - Audit logging enabled (on by default for M365 E3/E5; verify via Get-AdminAuditLogConfig)

.NOTES
  CopilotInteraction events have 1-2 hour ingestion lag from Purview.
  For real-time, wire the Microsoft 365 data connector in Sentinel (separate step).
#>

param(
  [int]$LookbackHours = 24,
  [string]$UserPrincipalName,   # optional filter (e.g. you@tenant.com)
  [switch]$RaiOnly,             # show only blocked / filtered interactions
  [int]$ResultSize = 200,
  [switch]$PushToSentinel,      # also POST rows into LAW custom table via Logs Ingestion API
  [string]$DceIngestionEndpoint = 'https://dce-wildpaws-rz9w.eastus-1.ingest.monitor.azure.com',
  [string]$DcrImmutableId       = 'dcr-5abac36b06e24a9aa54f673b722c008a',
  [string]$StreamName           = 'Custom-WildpawsCopilotAudit_CL'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
  Write-Host "Installing ExchangeOnlineManagement module..." -ForegroundColor Yellow
  Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop

# Search-UnifiedAuditLog lives in Exchange Online (NOT SCC/IPPSSession,
# despite older docs). Connect once per shell — cached session is reused.
$existing = Get-ConnectionInformation -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like 'ExchangeOnline*' -and $_.State -eq 'Connected' }
if (-not $existing) {
  Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
  Connect-ExchangeOnline -ShowBanner:$false
} else {
  Write-Host "Reusing existing Exchange Online session ($($existing.UserPrincipalName))" -ForegroundColor DarkGray
}

$end   = Get-Date
$start = $end.AddHours(-$LookbackHours)

$params = @{
  StartDate    = $start
  EndDate      = $end
  RecordType   = 'CopilotInteraction'
  ResultSize   = $ResultSize
  SessionId    = "wildpaws-$(Get-Date -Format 'yyyyMMddHHmmss')"
  SessionCommand = 'ReturnLargeSet'
}
if ($UserPrincipalName) { $params.UserIds = $UserPrincipalName }

Write-Host "Querying CopilotInteraction events $start -> $end ..." -ForegroundColor Cyan
$raw = Search-UnifiedAuditLog @params

if (-not $raw) {
  Write-Host "No CopilotInteraction events found in the window." -ForegroundColor Yellow
  Write-Host "Possible causes: ingestion lag (try again in 30-60 min), audit not enabled, or no Copilot Studio usage yet." -ForegroundColor Yellow
  return
}

# AuditData is JSON inside each row — flatten the interesting bits.
# NOTE: For Copilot *Studio* agents, Purview only captures invocation
# metadata (who/when/which agent/which thread). Prompt/response/tokens/RAI
# verdicts are NOT in the record by design — for those you need BYOM
# with Foundry diagnostic settings, or M365 Copilot Chat (not Studio).
$rows = foreach ($r in $raw) {
  $d = $r.AuditData | ConvertFrom-Json

  # AppIdentity looks like: Copilot.Studio.<envId>-<schemaName>_<displayName>
  # Parse out env id and friendly agent name when present.
  $envId = $null; $agentName = $null
  if ($d.AppIdentity -match '^Copilot\.Studio\.([0-9a-f-]+)-[^_]+_(.+)$') {
    $envId     = $matches[1]
    $agentName = $matches[2]
  } elseif ($d.AppIdentity) {
    $agentName = $d.AppIdentity
  }

  [pscustomobject]@{
    Time          = [datetime]$d.CreationTime
    User          = $d.UserId
    AppHost       = $d.CopilotEventData.AppHost     # 'Copilot Studio' | 'Microsoft Teams' | ...
    AgentName     = $agentName
    EnvId         = $envId
    ThreadId      = $d.CopilotEventData.ThreadId
    ClientIP      = $d.ClientIP
    Region        = $d.ClientRegion
    Operation     = $d.Operation
    AccessedItems = ($d.CopilotEventData.AccessedResources | ForEach-Object { $_.Name }) -join ', '
    Raw           = $d
  }
}

if ($RaiOnly) {
  Write-Host "Note: Copilot Studio agents do not emit RAI verdicts to Purview — -RaiOnly will be empty." -ForegroundColor Yellow
  $rows = @()
}

$rows | Sort-Object Time -Descending |
  Select-Object Time, User, AppHost, AgentName, Region, ThreadId |
  Format-Table -AutoSize

Write-Host "`nTotal Copilot Studio + Teams interactions: $($rows.Count)" -ForegroundColor Green

# By-channel breakdown
$rows | Group-Object AppHost | Select-Object @{n='Channel';e={$_.Name}}, Count |
  Format-Table -AutoSize

# By-agent breakdown
$rows | Where-Object AgentName | Group-Object AgentName |
  Select-Object @{n='Agent';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Host "ℹ  Purview CopilotInteraction for Studio agents is metadata-only:" -ForegroundColor Cyan
Write-Host "    captured: user, time, agent, channel, thread, client IP/region" -ForegroundColor Gray
Write-Host "    NOT captured: prompt text, response, tokens, RAI verdict" -ForegroundColor Gray
Write-Host "    For prompt/RAI/tokens you need BYOM + Foundry diagnostic settings." -ForegroundColor Gray

if ($PushToSentinel) {
  Write-Host "`n=== Pushing to Sentinel (WildpawsCopilotAudit_CL) ===" -ForegroundColor Cyan
  # Acquire token for Monitor Logs Ingestion API
  $tok = az account get-access-token --resource https://monitor.azure.com --query accessToken -o tsv
  if (-not $tok) { throw "Failed to acquire Monitor token via 'az account get-access-token'." }

  $payload = foreach ($r in $rows) {
    [pscustomobject]@{
      TimeGenerated     = $r.Time.ToUniversalTime().ToString('o')
      UserPrincipalName = [string]$r.User
      AppHost           = [string]$r.AppHost
      AgentName         = [string]$r.AgentName
      EnvironmentId     = [string]$r.EnvId
      ThreadId          = [string]$r.ThreadId
      ClientIP          = [string]$r.ClientIP
      ClientRegion      = [string]$r.Region
      Operation         = [string]$r.Operation
      AuditRecordId     = [string]$r.Raw.Id
    }
  }

  $url  = "$DceIngestionEndpoint/dataCollectionRules/$DcrImmutableId/streams/$StreamName" + '?api-version=2023-01-01'
  $body = $payload | ConvertTo-Json -Depth 5 -AsArray

  try {
    $resp = Invoke-WebRequest -Method POST -Uri $url `
      -Headers @{ Authorization = "Bearer $tok"; 'Content-Type' = 'application/json' } `
      -Body $body -UseBasicParsing
    Write-Host ("Pushed {0} rows, HTTP {1}" -f $payload.Count, $resp.StatusCode) -ForegroundColor Green
  } catch {
    Write-Host "Push failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Red }
  }
  Write-Host "Tip: data is queryable in ~3-5 min: WildpawsCopilotAudit_CL | take 10" -ForegroundColor Gray
}
