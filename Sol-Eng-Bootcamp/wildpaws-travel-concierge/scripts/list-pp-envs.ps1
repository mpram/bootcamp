$tok = az account get-access-token --resource 'https://service.powerapps.com/' --query accessToken -o tsv
$h = @{ Authorization = "Bearer $tok" }
$envs = Invoke-RestMethod -Method GET -Uri 'https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments?api-version=2021-04-01' -Headers $h
$envs.value | ForEach-Object {
  [pscustomobject]@{
    Name        = $_.name
    DisplayName = $_.properties.displayName
    InstanceUrl = $_.properties.linkedEnvironmentMetadata.instanceApiUrl
    UniqueName  = $_.properties.linkedEnvironmentMetadata.uniqueName
    OrgId       = $_.properties.linkedEnvironmentMetadata.resourceId
  }
} | Format-Table -AutoSize -Wrap
