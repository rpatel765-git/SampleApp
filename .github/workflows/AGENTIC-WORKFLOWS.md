# Agentic DevOps Workflows — Team Task Tracker

This directory contains **GitHub Agentic Workflows** (gh-aw) that automate the
DevOps side of the SDLC. Each workflow is a Markdown prompt file that
`gh aw compile` turns into a deterministic, locked GitHub Actions workflow.
A Copilot-powered agent runs the prompt in a sandboxed, firewalled container
and produces *safe outputs* — pull requests, issues, or comments.

> **Why this matters.** AI accelerated coding to the point where the bottleneck
> moved to operations: triage, docs, testing, deployment, and incident response.
> Agentic Workflows close the loop. The vision is *"first line of code →
> autonomous incident response,"* with a human reviewing — not authoring — the
> work.

---

## How it works

```
.md prompt file  ──►  gh aw compile  ──►  .lock.yml  ──►  Copilot agent  ──►  PR / Issue
                                                          (sandboxed,
                                                           firewalled,
                                                           safe-outputs)
```

| Layer | Purpose |
|-------|---------|
| **Markdown prompt** | What the agent should do, in plain English |
| **YAML frontmatter** | Triggers, permissions, network policy, safe-outputs |
| **`.lock.yml`** | Compiled deterministic workflow committed to repo |
| **Sandboxed container** | Egress firewall: only `github` allowed |
| **Safe outputs** | Hard caps: max PRs / issues per run, draft by default |

Compile and trigger:

```bash
# Compile every .md in this directory to its .lock.yml
gh aw compile

# Manually trigger a workflow by name
gh aw trigger continuous-triage

# Or use the standard GH CLI on the compiled file
gh workflow run continuous-triage.lock.yml
```

---

## Workflow Catalog

| # | Workflow | Trigger | What It Does | Demo Difficulty |
|---|----------|---------|--------------|-----------------|
| 1 | [chaos-engineering](./chaos-engineering.md) | `workflow_dispatch` | Inject one of 13 realistic defects via draft PR — exercise your CI/observability | ⭐⭐ |
| 2 | [continuous-triage](./continuous-triage.md) | `issues: opened` | Auto-label, prioritize, set area, and route every new issue | ⭐ |
| 3 | [continuous-docs](./continuous-docs.md) | `push` to `main` (routes/) | Detect API surface changes and refresh `docs/API.md` via PR | ⭐⭐ |
| 4 | [continuous-testing](./continuous-testing.md) | weekly + `push` | Find files below 80% coverage and generate Jest tests for them | ⭐⭐ |
| 5 | [incident-response](./incident-response.md) | `workflow_run: completed (failure)` on CI | RCA the failure → fix PR if obvious, otherwise tracking issue | ⭐⭐⭐ |
| 6 | [dependency-update](./dependency-update.md) | weekly | Audit deps, propose patch/minor upgrades, run tests, open one PR | ⭐⭐ |
| 7 | [security-audit](./security-audit.md) | weekly + manual | OWASP-style review of recent diffs; open remediation issues | ⭐⭐⭐ |
| 8 | [release-notes](./release-notes.md) | `release: published` (draft) | Generate human-readable release notes from merged PRs | ⭐ |
| 9 | [flaky-test-detector](./flaky-test-detector.md) | nightly | Detect flaky tests across recent CI runs and open quarantine PR | ⭐⭐⭐ |

> **Difficulty legend.** ⭐ = safe to run live in any demo. ⭐⭐ = needs a couple
> of seeded artifacts (issues, low-coverage file, etc.). ⭐⭐⭐ = best shown via
> a pre-recorded run because it depends on prior failures or scheduled history.

---

## Mapping to Part 3 — Agentic DevOps Pillars

| Pillar (slides) | Workflow(s) here |
|-----------------|------------------|
| 🔨 **Build** — generate / maintain CI/CD | `ci-cd.yml` (existing) |
| 🧪 **Test** — autonomous coverage growth | `continuous-testing`, `flaky-test-detector` |
| 🚀 **Deploy** — release management | `release-notes` |
| 📊 **Monitor** — keep state in sync | `continuous-docs`, `continuous-triage` |
| 🔥 **Respond** — autonomous incident handling | `incident-response`, `chaos-engineering` |
| 🔒 **Secure** — shift-left + supply chain | `security-audit`, `dependency-update` |

---

## Security Model (applies to **every** workflow here)

- **Sandboxed containers** — fresh, ephemeral, no persistent state.
- **Egress firewall** — `network.allowed: ["github"]` blocks all outbound
  traffic except `github.com` and `copilot.com`. The agent **cannot** reach
  Cosmos DB, internal services, or arbitrary URLs.
- **Safe outputs** — every workflow caps PRs (`max: 1`, `draft: true`) and
  issues (`max: 1`). The agent cannot push directly to `main`.
- **Scoped permissions** — `contents: read` by default; write is granted only
  through the `safe-outputs` mechanism, not raw `GITHUB_TOKEN`.
- **Protected files** — anything under `.github/`, `infra/`, or secrets falls
  back to opening an issue rather than editing.

---

## Demo

See [`demos/agentic-devops/README.md`](../../demos/agentic-devops/README.md)
for the full ~30 minute walkthrough script and copy-paste prompts.

## Adding your own

1. Copy the closest workflow as a template.
2. Edit the frontmatter (`on:`, `safe-outputs`, `timeout-minutes`).
3. Write the prompt body — **describe the contract, not the implementation**.
4. Run `gh aw compile` to produce the `.lock.yml`.
5. Commit both files. The first run is the test.
