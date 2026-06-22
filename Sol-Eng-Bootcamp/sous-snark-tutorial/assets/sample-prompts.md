# Sample prompts show off each tool

Use these in the Foundry **Playground** to demo each capability. After each response, expand the tool-call rows in the message to confirm the right tool fired.

## 🟢 Warm-up (no tools needed)

| Prompt | What to expect |
|---|---|
| `Hi.` | A snarky greeting + Judgment Summary with effort "Low". |
| `What's your job?` | Sous Snark explains itself in character. |

## 🐍 Code Interpreter

| Prompt | What to expect |
|---|---|
| `Scale this brownie recipe from 8 servings to 5: 200g butter, 300g sugar, 4 eggs, 250g flour, 100g cocoa.` | Python runs, returns scaled grams. Tool row labeled **code_interpreter**. |
| `Convert 350°F to Celsius and tell me if my oven is judging me.` | Math via code interpreter; commentary in voice. |
| `If a chicken thigh is 180 kcal and I eat 4, plus 1 cup of rice (205 kcal), what's the total?` | Code interpreter sums. |

## 🌐 Bing grounding

| Prompt | What to expect |
|---|---|
| `Find me a real shakshuka recipe with sources.` | Bing tool fires. Response cites web URLs. |
| `What's a trendy dessert in 2026?` | Live-web answer with citations. |

## 🔌 MCP server (Microsoft Learn)

> The Microsoft Learn MCP is wired up for demo purposes. It's not food-related the point is to show participants that **any** MCP server plugs in the same way.

| Prompt | What to expect |
|---|---|
| `Search Microsoft Learn for how to add tools to a Foundry agent.` | Tool row labeled **microsoft_learn / microsoft_docs_search**. Response cites learn.microsoft.com URLs. |
| `Find me Microsoft docs about the Model Context Protocol.` | MCP tool fires. |

## 🎭 Personality stress tests

| Prompt | Why it's fun |
|---|---|
| `I want something healthy. Add bacon.` | Forces the "narrative" line. |
| `I'm on a diet. Recipe for tiramisu please.` | Watch the passive-aggression. |
| `I have 3 ingredients: ketchup, marshmallows, and ambition.` | Sous Snark must be helpful AND snarky simultaneously. |
| `Rate my dinner: instant ramen with a slice of American cheese.` | Should produce a brutal Judgment Summary. |

## ✅ Verifying tool dispatch

In the playground, every assistant message has a small **tool calls** disclosure. Click it to see:

```
▼ Tool calls (2)
  ├─ code_interpreter ── 142 ms ── ✓
  └─ microsoft_learn.microsoft_docs_search ── 980 ms ── ✓
```

If a tool didn't fire when you expected it to:
1. Check the agent **Instructions** is the tool referenced by the right name?
2. Reload the agent designer (caching).
3. See [`troubleshooting.md`](troubleshooting.md).
