# Contoso Travel Concierge

A **Microsoft 365 Copilot declarative agent** that demonstrates every Agent Registry tab end-to-end:

| Registry tab | Populated by |
|---|---|
| Overview / icon / description | Teams app manifest + declarative agent manifest |
| Instructions | `declarativeAgents/travelConcierge.json` → `instructions` |
| Capabilities | `capabilities[]` (WebSearch, CodeInterpreter, GraphConnectors, OneDriveAndSharePoint) |
| Actions / Tools | `actions[]` → two API plugins (Weather + Currency) |
| Connected agents | `worker_agents[]` → Expense Buddy (second declarative agent) |
| Channels | Microsoft 365 Copilot + Teams |
| Activity | Auto, once users chat |

## What the agent does

**Contoso Travel Concierge** is a corporate travel assistant. It:

1. Looks up live **weather** at any destination (Open-Meteo public API — no auth)
2. Converts **currencies** at live rates (Frankfurter public API — no auth)
3. **Searches the web** for travel advisories, visa rules, airline news
4. Uses **code interpreter** for itinerary math (cost splits, layover times)
5. Reads corporate travel policy from **SharePoint/OneDrive** (when grounded by tenant data)
6. Hands off expense questions to its connected **Expense Buddy** worker agent

## Project structure

```
contoso-travel-concierge/
├── appPackage/
│   ├── manifest.json              Teams app manifest 1.19 (registers declarative agent)
│   ├── color.png                  192x192 brand icon
│   ├── outline.png                32x32 transparent icon
│   ├── declarativeAgents/
│   │   ├── travelConcierge.json   Main agent — instructions, capabilities, actions, worker_agents
│   │   └── expenseBuddy.json      Worker agent — connected via worker_agents
│   └── apiPlugins/
│       ├── weatherPlugin.json     API plugin manifest
│       ├── weatherOpenApi.yaml    OpenAPI 3.0.1 for Open-Meteo
│       ├── currencyPlugin.json
│       └── currencyOpenApi.yaml
├── scripts/
│   ├── package.ps1                Zips appPackage → contoso-travel-concierge.zip
│   ├── upload.ps1                 POSTs zip to Teams app catalog via Graph
│   └── set-icons.ps1              Regenerates branded color.png / outline.png
└── README.md
```

## Deploy

```pwsh
cd c:\contoso-travel-concierge\scripts
.\set-icons.ps1            # generates icons
.\package.ps1              # zips appPackage
.\upload.ps1               # uploads to tenant Teams app catalog
```

After upload (~5–15 min for Copilot/registry to index), the agent appears in:
- **M365 admin center → Agents → All agents** with full Capabilities / Actions / Instructions / Connected agents tabs
- **Microsoft 365 Copilot** agent picker
- **Teams** (if you also add the `bots` block — left out here so it's pure-declarative)

## Why declarative agent (not custom-engine bot)

Custom-engine bots (Bot Framework) populate only the bot row in the registry — **no Instructions, Capabilities, or Tools tabs**, because that intelligence lives inside your container and is invisible to the platform. Declarative agents declare everything in the manifest so M365 can render every facet.

Trade-off: declarative agents run on Copilot's LLM (you provide instructions, not code). For this demo that's a feature — zero infra, works in any tenant.
