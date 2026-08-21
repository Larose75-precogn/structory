<div align="center">

# Structory

### The open-source operating system for financial organizations.

**The organization owns the data. · The journal is the source of truth. · State is computed, never stored.**

[Live demo](https://structory.ai/compta) · [Accounts demo](https://structory.ai/smc) · [structory.ai](https://structory.ai)

`5 services in production` · `~30,000 lines` · `1 core` · `1 journal format` · `Apache-2.0`

`open-source` · `ai-native` · `fintech` · `byos` · `accounting` · `ledger`

</div>

---

## The idea

**Structory doesn't store state. It stores history.**

An organization is a **journal** — the chronological, append-only record of everything that happened to it. The balance sheet, the cash position, the reports are not stored anywhere: they are **computed views** of that journal, recalculated on demand.

```
Journal → events → rules → time → computed state
computed state → accounting · cash flow · budget · reporting · dashboards · AI · apps
```

**Keep the journal. Rebuild any state. Forever.** Audit every action, and hand an AI agent the full, clean history of the organization. This is not "accounting with some AI" — it's a data infrastructure for organizations, whose first use case happens to be accounting.

## The architecture

```
Own Storage  →  Journal  →  Objects / Flows / Rules / Time  →  Computed views  →  Applications & Agents
```

Four universal building blocks structure everything: **Objects** (the entities), **Flows** (every event — "everything starts with a flow"), **Rules** (the business logic), **Time** (every event is dated). Every view is derived from them.

The whole design is one inversion of the usual model:

| Traditional software | Structory |
|---|---|
| App → proprietary database → **your data locked in** | **Your journal, in your own storage** → common structure → **unlimited apps** |

Applications no longer own the data. The organization does. This is **BYOS** — *Bring Your Own Storage*: the journal lives in a space the organization owns (today, its own Google Drive). Applications are only ways to read it and act on it — they never appropriate it.

The journal is **append-only**: an entry is never modified or deleted. A correction is a *new* event, and the state is recomputed. Full history, perfect audit trail — the append-only event journal is the whole point.

## What exists

Five services in production — **four of them applications sharing one core and one journal format**, plus one standalone add-on:

| Product | What it is | Try it |
|---|---|---|
| **Ma Compta / Structory Ledger** | Accounting engine on `ledger-cli`, up to legal filings (FEC) | [demo](https://structory.ai/compta) |
| **Suivre mes comptes** | Multi-account net worth (banks, life insurance, crypto…), daily email | [demo](https://structory.ai/smc) |
| **Compta Copro** | First vertical — homeowners-association accounting, one real building live | [page](https://structory.ai/comptacopro) |
| **Journal de Banque** | The bank flow as the **master flow** for cash accounting | [page](https://structory.ai/jdb) |
| **SheetToCSV** | Standalone add-on, published on the Google Marketplace | — |

*Journal de Banque, in particular:* balancing books against a bank is a permanent bottleneck of endless reconciliation. Structory makes the bank flow the **starting point** of cash accounting instead — a direct consequence of the architecture.

## AI-native by design

The journal is the ideal context for an LLM: a single, structured, complete text file goes straight into the model — no database to traverse, no schema to reverse-engineer. An agent reads the whole organization, then acts (classify a transaction, draft a document, flag an anomaly), and **every action is written back as a new event** — fully auditable.

Without this, each application rebuilds its own model of the same data. For AI agents, that means more synchronization, more duplication, and more context to reconstruct on every task. One journal removes all of it. Reasoning can run on a **local LLM** (Ollama) or a cloud model — the journal is the same clean context either way.

## Open source & BYOS

Built on proven engines, none reinvented: `ledger-cli` (20 years of double-entry accounting), `Docling` (document understanding), Ollama (local LLM), Google Drive (the organization's storage), Stripe (billing). Structory **organizes**; these engines compute. It makes `ledger-cli` — until now reserved for technical users — usable online, with nothing to install. And it stays open source.

The journal and the organization's data live in storage the organization owns. That's what makes the whole thing trustworthy — and verifiable.

## Business model

**€1 / month per building block** — a building block is an **organization or a user**. One organization + one user = €1; then +€1 per additional org or user.

Open source is the distribution engine, not a giveaway: you don't pay to read the code, you pay to **not operate it** (five services, local AI, bank connectors, storage you own), and for the network of organizations, modules and connectors around it — including a marketplace where partner modules pay €1/block and price freely on top.

## Status — Pre-Seed

Raising **€150k** · founder pseudonymous by choice · fully bootstrapped to date · zero fixed costs. This raise finalizes the core, ships the first production organizations, and prepares the 2027 Seed.

## The code

Structory is not one repository — it is a small set of focused services, each open and verifiable:

| Repository | What it implements |
|---|---|
| [`ledger_api`](https://github.com/Larose75-precogn/ledger_api) | The journal — `ledger-cli` engine, FEC export, PCG rules, write-access roles |
| [`analyzor`](https://github.com/Larose75-precogn/analyzor) | Bricks registry, BYOS / Drive, rules cascade, Docling, LLM, intent understanding |
| [`executor`](https://github.com/Larose75-precogn/executor) | Orchestration + bank connectors (Powens, Enable Banking, Mercury, Qonto) |
| [`subscriptions_api`](https://github.com/Larose75-precogn/subscriptions_api) | Users, organizations, roles, Stripe, magic-link auth |
| [`bibliotheque`](https://github.com/Larose75-precogn/bibliotheque) | Connectors, bricks, BYOS org creation (the Apps Script glue) |

Journal de Banque and the vertical modules (Compta Copro, Suivre mes comptes) live in their own repositories too. This repository is the front door and the docs.

## Verify it yourself

That's the whole point of open source here. The architecture, the running product and the source are public — nothing to take on faith. Read [`ARCHITECTURE.md`](ARCHITECTURE.md), run the 15-minute [`QUICKSTART.md`](QUICKSTART.md), open the [demos](https://structory.ai/compta), and browse the repositories above. **The code is here — verify it yourself.**

## License

[Apache License 2.0](LICENSE) — use it, run it, build on it.

---

<div align="center">
<sub>structory.ai · contact via the site</sub>
</div>
