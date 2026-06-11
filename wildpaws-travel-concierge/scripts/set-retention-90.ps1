$tables = @(
  'WildpawsRaiBlocks_CL',
  'WildpawsPbiAudit_CL',
  'WildpawsAgentActivity_CL',
  'WildpawsCopilotAudit_CL',
  'WildpawsConversationContent_CL'
)
foreach ($t in $tables) {
  Write-Host "-> $t" -ForegroundColor Cyan
  az monitor log-analytics workspace table update `
    -g rg-wildpaws-telemetry --workspace-name law-wildpaws-dev `
    -n $t --retention-time 90 --total-retention-time 90 `
    --query "{name:name, retention:retentionInDays, total:totalRetentionInDays}" -o tsv
}
Write-Host "`n=== Final ===" -ForegroundColor Yellow
az monitor log-analytics workspace table list -g rg-wildpaws-telemetry --workspace-name law-wildpaws-dev --query "[?starts_with(name, 'Wildpaws')].{name:name, retention:retentionInDays, total:totalRetentionInDays}" -o table
