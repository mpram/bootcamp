# Americas Security GBB

## Purpose
Central repository for Americas Security GBB assets enabling:
- Seller and CSA enablement
- Repeatable demo + workshop delivery
- Reusable technical artifacts (KQL, scripts, playbooks)
- Field-driven innovation and feedback loops

This repo is intended to be **practical, field-tested, and customer-ready**.

---

## What Lives Here

### 1. Demo Frameworks
End-to-end demo scenarios aligned to real customer problems:
- SOC modernization (XDR + SIEM + Copilot)
- Identity and Zero Trust journeys
- Data security and compliance workflows
- AI / Agentic Security scenarios (A365, Copilot, automation)

Each demo should include:
- Scenario overview (business problem)
- Demo flow (step-by-step)
- Required prerequisites
- Talk track (what to say)

---

### 2. KQL / Hunting Queries
Reusable queries across:
- Defender XDR (MDE, MDI, MDO)
- Sentinel (SIEM, UEBA, data lake)
- Cross-source investigations

Focus:
- High-signal detections
- Real attacker techniques
- Correlation across identity, endpoint, and data

---

### 3. Automation & SOAR
Playbooks and workflows:
- Logic Apps (Sentinel)
- Automated response + enrichment
- Ticketing / downstream integrations

Priorities:
- Reduce analyst toil
- Accelerate time-to-response
- Showcase platform integration value

---

### 4. Labs & Workshops
Structured hands-on content:
- Bootcamp labs (Sol-Eng, CSA enablement)
- Customer workshops (EBC / EC ready)
- POC guidance

Each lab should include:
- Objectives
- Setup steps
- Execution steps
- Expected outcomes

---

### 5. Customer-Facing Assets
Reusable artifacts for the field:
- One-pagers
- Architecture patterns
- Pitch decks (lightweight, export-friendly)
- Business value framing

---

## Contribution Model

### Who Can Contribute
- GBBs, CSAs, sellers, and engineering partners

### Contribution Guidelines
- Keep content **real and field-tested**
- Bias toward **working examples over theory**
- Include:
  - Clear description of use case
  - Dependencies / prerequisites
  - Known limitations

### Naming Conventions
- `Demo-<Scenario>-<ShortName>`
- `KQL-<UseCase>-<DataSource>`
- `Playbook-<Trigger>-<Action>`
- `Lab-<Experience>-<Level>`

---

## Design Principles

### 1. Customer-First
- Anchor everything in a real problem:
  - “Reduce SOC noise”
  - “Accelerate investigation”
  - “Consolidate tools”

### 2. End-to-End > Feature Demo
- Show workflows, not isolated capabilities

### 3. Signal Over Volume
- Prioritize **high-quality detections and insights**
- Avoid “demo telemetry spam”

### 4. Platform Story
- Emphasize:
  - XDR + SIEM convergence
  - Identity + Endpoint + Data correlation
  - Copilot and agentic workflows

---

## Getting Started

1. Clone the repo
2. Navigate to relevant folder:
   - `/Demos`
   - `/KQL`
   - `/Automation`
   - `/Labs`
3. Follow README within each directory
4. Test in demo or customer tenant

---

## Known Gaps (Expected Evolution)
- Standardized demo data sets
- Cross-tenant / multi-tenant scenarios
- Expanded Copilot + agent workflows
- Deeper integration with data lake + Graph

---

## Ownership

Maintained by Americas Security GBB

For major contributions or structural changes:
- Align with repo maintainers
- Validate with at least one field use case

---

## Why This Matters

This repo is designed to:
- Reduce duplication across GBBs
- Improve demo quality and consistency
- Capture and scale field innovation
- Accelerate time-to-impact in customer engagements
