# Agentic DevOps — 1-Page Cheat Sheet

> Print this. Tape it next to your demo terminal.

## The pitch (10 seconds)

> *"AI moved the bottleneck from coding to ops. Agentic Workflows close the
> loop — eight markdown files in `.github/workflows/`, each a Copilot agent
> running in a sandbox, each producing one safe output."*

## The eight workflows

| ⚡ | Workflow | Trigger | Output |
|---|----------|---------|--------|
| ⭐ | `continuous-triage` | issue opened | comment + labels |
| ⭐⭐ | `continuous-docs` | push to routes/ | docs PR |
| ⭐⭐ | `continuous-testing` | weekly + manual | tests PR |
| ⭐⭐⭐ | `incident-response` | CI failure on main | incident issue (or fix PR) |
| ⭐⭐ | `dependency-update` | weekly | upgrade PR |
| ⭐⭐⭐ | `security-audit` | weekly | up to 3 issues |
| ⭐ | `release-notes` | release published | rewritten release body |
| ⭐⭐⭐ | `flaky-test-detector` | nightly | quarantine PR |
| ⭐⭐ | `chaos-engineering` | manual | defect PR |

## Live demo order (3 chapters → 12 min, full demo → 30 min)

**Short (12 min):** triage → docs → release-notes → wrap-up.
**Full (30 min):** triage → docs → testing → incident → deps → security →
release-notes → chaos → wrap-up.

## Commands

```powershell
# Compile every .md to its .lock.yml
gh aw compile

# Trigger any workflow manually
gh workflow run <name>.lock.yml

# Watch the most recent run live
gh run watch

# Re-trigger triage on an existing issue
gh workflow run continuous-triage.lock.yml -f issue_number=42

# Seed the demo (idempotent, safe to re-run)
pwsh ./demos/agentic-devops/scripts/seed-demo-data.ps1

# One-shot trigger by friendly name (uses helper)
pwsh ./demos/agentic-devops/scripts/trigger-workflow.ps1 triage
```

## Three things the agent **cannot** do

1. **Push to `main`** — every output goes through `safe-outputs` (PR/issue
   only) with `protected-files: fallback-to-issue`.
2. **Reach your network** — `network.allowed: ["github"]` blocks all egress
   except `github.com` + `copilot.com`. No DB, no internal API, no exfil.
3. **Run forever** — `timeout-minutes` (6–25) enforced by the runner.

## When something looks wrong on stage

- Workflow didn't trigger? → Repo settings → Actions → check workflow
  permissions and "Allow Actions to create PRs."
- Diff is enormous? → That's the wrong workflow shape; show the
  `safe-outputs` cap and re-run.
- Wrong file picked? → Use the workflow's `workflow_dispatch.inputs` to
  force the target.
- Agent contradicted itself? → Comment `@copilot` on the PR with corrections
  — show the iterate-loop in action.

## Where each part of the deck lives

| Slide section | Show this on screen |
|---------------|---------------------|
| Bottleneck shift | `AGENTIC-WORKFLOWS.md` table |
| What is Agentic DevOps | The mapping table at the bottom of the catalog |
| Use cases (5 canonical) | `continuous-*.md` files side-by-side |
| Security model | `network.allowed`, `safe-outputs`, `timeout-minutes` lines |
| Custom workflow | `demo-prompts.md` section A (Agent Mode generates one live) |
| Migration / extensibility | `demo-prompts.md` section B (Plan-mode CLI proposes #9) |
