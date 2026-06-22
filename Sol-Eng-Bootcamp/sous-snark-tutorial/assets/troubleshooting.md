# Troubleshooting Sous Snark tutorial

## Project / model creation

### ❌ "You don't have permission to create a Foundry project"
**Fix:** You need `Cognitive Services Contributor` on the subscription or resource group. Ask your Azure admin, or use an RG you own.

### ❌ "No quota available for gpt-4o in this region"
**Fix:** Pick another region in the deploy dialog (Sweden Central, West US 3 usually have spare). Or pick `gpt-4o-mini` Sous Snark works fine on it.

### ❌ Model deployment stuck on "Provisioning"
**Fix:** Wait 5 min. If still stuck, delete the deployment and recreate. Capacity allocation can race.

---

## Agent designer

### ❌ "Save failed" / changes disappear
**Fix:** The designer auto-saves but can race with browser refresh. After every change, wait for the green "Saved" indicator before navigating. Hard refresh (Ctrl+F5) if state seems stale.

### ❌ Agent answers without using tools
Causes (in order of likelihood):
1. **Instructions don't mention the tool by name** the model decides based on instructions + tool descriptions. Update the prompt to say `CALL the Bing grounding tool` etc.
2. **Tool not actually attached** check the agent's Tools panel; it should list each tool with a green dot.
3. **MCP server unreachable** see MCP section below.

### ❌ Empty / hallucinated response
**Fix:** Check **Tracing** in the left nav. Open the latest span; look for tool-call errors. Most common: model called a tool with bad args.

---

## Bing grounding

### ❌ "Grounding with Bing Search" not in the +Add menu
**Fix:** Feature is region-restricted. Move project to East US, or skip this tool. Sous Snark still works.

### ❌ Bing connection won't save
**Fix:** The Bing resource and the Foundry project must be in subscriptions your account can read from. Sign out / in to refresh tokens.

### ❌ Bing returns no results
**Fix:** G1 free tier has 3 calls/sec rate limit. Wait 10 sec and retry. Upgrade to S1 if demoing live.

---

## Code Interpreter

### ❌ Code Interpreter never fires
**Fix:** Your prompt isn't quantitative enough. Try one with explicit numbers ("scale from 8 to 5", "convert 350F"). The model only calls it when arithmetic is clearly required.

### ❌ "Code Interpreter execution timed out"
**Fix:** 60s per call. Don't ask it to web-scrape (no network from the sandbox). Keep tasks to pure math / pandas.

---

## MCP server

### ❌ "MCP Server" not in the +Add menu
**Fix:** MCP support rolled out region-by-region in 2025–2026. Confirm your Foundry resource is in East US, Sweden Central, or West US 3. If not, recreate in a supported region.

### ❌ MCP server URL won't connect
**Test from your laptop first:**
```pwsh
curl -i https://learn.microsoft.com/api/mcp
```
Should return 200 or 405. If your corporate proxy blocks it, ask IT to allow `learn.microsoft.com`.

### ❌ MCP tool listed but never called
**Fix:** Same as agent-doesn't-use-tools above explicitly reference the server label in the system prompt (we use `microsoft_learn`).

### ❌ MCP call returns "approval required"
**Fix:** You set **Require approval** to "Always" in Step 6. Either approve each call in the playground, or change setting to "Never" for demos.

---

## Permissions

### ❌ "401 Unauthorized" when invoking the agent from outside the portal
**Fix:** The caller (your user or a managed identity) needs `Azure AI User` role on the Foundry resource. In Azure portal → Foundry resource → Access control (IAM) → Add role assignment.

### ❌ "403 Forbidden" calling the data plane
**Fix:** `Cognitive Services User` is not enough for agents. Use **`Azure AI User`** (role ID `53ca6127-db72-4b80-b1b0-d745d6d5456d`).

---

## Cleanup gotchas

### ❌ Resource group delete fails with "soft-deleted resources"
**Fix:** Cognitive Services + Key Vault both have soft-delete. After deleting the RG, also purge from **Manage deleted resources** in Cognitive Services + Key Vault blades, or your name is taken for 90 days.

---

## When all else fails

1. **Tracing** tab every tool call, args, latency, error. Most issues become obvious here.
2. Try the same prompt with **gpt-4o-mini** to rule out model behavior.
3. Recreate the agent fresh designer state can occasionally corrupt during fast clicking.
4. Open an issue against this tutorial repo with the trace ID.
