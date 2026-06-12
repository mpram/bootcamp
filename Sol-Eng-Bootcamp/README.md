# 🥾 Solution Engineering Bootcamp

A hands-on bootcamp that takes Solution Engineers from **building AI agents** to **securing, governing, and publishing them** as enterprise-ready agents with Microsoft Entra and Microsoft Agent 365.

## What you'll learn

By working through these labs you will:

- **Build agents two ways** — a low-code agent in **Microsoft Copilot Studio** and a pro-code agent in **Microsoft Foundry (Azure AI Foundry)**.
- **Extend agents with real capabilities** — knowledge sources, web/Bing grounding, REST API tools, Code Interpreter, MCP servers, and connected sub-agents.
- **Understand agent identity** — how **Entra Agent IDs** and **blueprints** give each agent a governable identity.
- **Govern agents like an AI Admin** — Conditional Access (Report-only), custom security attributes, and sponsorship-change lifecycle workflows.
- **Publish with governance** — apply Entra policies through **Microsoft Agent 365** at activation time so every agent meets organizational standards.

## Index

| Folder | What it covers |
|--------|----------------|
| [wildpaws-travel-concierge](wildpaws-travel-concierge/COPILOT-STUDIO-WALKTHROUGH.md) | **Copilot Studio agent.** Build *Wildpaws Trail Guide* end to end — travel knowledge, web search, two REST API tools (Weather, FX), and a connected *Expense Tracker* sub-agent — then deploy it to Teams. Introduces Agent ID and blueprints. |
| [sous-snark-tutorial](sous-snark-tutorial/Azure-AI-Foundry-Walkthrough.md) | **Microsoft Foundry agent.** Build *Sous Snark*, a sous-chef agent, with Bing grounding, Code Interpreter (Python), and a public MCP server for live external knowledge. |
| [Entra-set-up](Entra-set-up/Conditional-Access-for-Agents.md) | **Govern the agent identities in Entra.** Create a Report-only Conditional Access policy, tag agents with custom security attributes, and automate sponsor-change notifications with lifecycle workflows. |
| [A365](A365/Agent-365-Custom-Template.md) | **Publish with Agent 365.** Apply the Entra Conditional Access policy and custom security attributes to the pilot agents during the Agent 365 publish wizard. |

## Suggested order

1. **wildpaws-travel-concierge** — build the Copilot Studio agent.
2. **sous-snark-tutorial** — build the Foundry agent.
3. **Entra-set-up** — secure and govern both agent identities.
4. **A365** — publish both agents with governance applied.

> The governance labs (Entra-set-up and A365) build directly on the two agents created in the first two labs — work through the folders in order.

