# Agentic DevOps — Live Demo Runbook (SampleApp)

> **Audience:** DevOps / Platform Engineering / SRE
> **Length:** ~30 min (or pick 2–3 of the chapters for shorter slots)
> **Repo:** `SampleApp` — Team Task Tracker (Node.js / TypeScript / Express)
> **Maps to:** *Part 3 — DevOps* of the GitHub Copilot Productivity Deep-Dive

This runbook walks an audience through the **Agentic DevOps** story end-to-end:
the bottleneck has moved from coding to operations, and AI agents — running
inside GitHub Actions — close the loop. We use the workflow catalog in
[`.github/workflows/AGENTIC-WORKFLOWS.md`](../../.github/workflows/AGENTIC-WORKFLOWS.md)
to show eight different "Ops side of the SDLC" automations live.

---

## Pre-demo checklist

Run [`scripts/seed-demo-data.ps1`](./scripts/seed-demo-data.ps1) the day before
your demo to set up reproducible artifacts the agents can act on.

| ✅ | Item |
|---|------|
| ☐ | `gh auth status` — logged into the demo org |
| ☐ | `gh aw --version` — `gh-aw` extension installed (`gh extension install github/gh-aw`) |
| ☐ | `gh aw compile` runs cleanly in the SampleApp directory |
| ☐ | All `*.lock.yml` files committed and pushed to `main` |
| ☐ | At least one **failed** run of `CI/CD Pipeline` exists on `main` (for incident-response demo) |
| ☐ | At least one **issue without labels** exists (for triage demo) |
| ☐ | At least one source file with `<80%` coverage (for testing demo) |
| ☐ | At least one **draft release** with auto-generated notes exists (for release-notes demo) |
| ☐ | Demo terminal: PowerShell, font ≥ 18pt, dark theme |
| ☐ | Browser tabs open: Actions tab · Issues tab · PRs tab · one example agent PR |

`scripts/seed-demo-data.ps1` automates the four "at least one" rows above.

---

## Chapter 0 — The Bottleneck Shift (~3 min · slide-only)

**Say:** *"AI accelerated coding to the point where the bottleneck moved.
Teams now spend more time on CI/CD config, deployment reviews, triage, and
firefighting than on actual code. Agentic DevOps is how we close that gap.
Today I'll show you eight workflows running on this repo — all written as
Markdown prompts."*

Open `.github/workflows/AGENTIC-WORKFLOWS.md` in the browser. Walk down the
table. **Land the punch line:** *every row is a Markdown file we wrote in
under 100 lines of plain English.*

---

## Chapter 1 — Continuous Triage (~4 min · ⭐ easiest, do this live)

**Storyline:** *"Issue triage is the first place teams drown. Every new bug
report needs a label, an area, a priority, and an owner. That's pattern
matching — and a perfect job for an agent."*

### Steps

1. Open [`.github/workflows/continuous-triage.md`](../../.github/workflows/continuous-triage.md).
   Read the **What "good triage" looks like** section aloud — point at the
   constrained label vocabulary.
2. Switch to the browser. Open the unlabelled issue from the seed script (or
   create a new one live: *"Tasks API returns 500 when teamId is missing"*).
3. Watch the Actions tab — the `Continuous Triage Agent` run starts within
   ~10 seconds.
4. Refresh the issue. Show:
   - 4 labels applied (`type:bug`, `area:tasks`, `area:api`, `priority:p2`).
   - Comment with likely files: `src/routes/tasks.ts`, `src/middleware/validation.ts`.
   - One clarifying question.
   - Triage block appended to the body.

**Key talking points:**
- The agent only uses labels from a fixed list — no label sprawl.
- Safe-outputs cap at 1 comment + 6 labels. The agent **cannot** close,
  assign, or escalate.
- This runs in 8 minutes max — past that, `timeout-minutes` kills it.

---

## Chapter 2 — Continuous Docs (~4 min · ⭐⭐)

**Storyline:** *"Docs drift. Routes change, the docs don't. Engineers stop
trusting them, then stop reading them, then stop updating them. Let's invert
that."*

### Steps

1. Open [`.github/workflows/continuous-docs.md`](../../.github/workflows/continuous-docs.md).
   Highlight **the agent edits only `docs/API.md`** — anything else falls
   back to an issue.
2. Live edit: open `src/routes/tasks.ts` and add a query field to
   `TaskQuerySchema` (e.g., `dueBefore: z.string().datetime().optional()`).
   Commit + push to a branch + merge to `main`.
3. The `Continuous Docs Agent` triggers on the path filter
   (`src/routes/**`, `src/models/**`).
4. Open the resulting draft PR. Show:
   - `docs/API.md` updated **only** in the `Tasks` section.
   - The new `dueBefore` query parameter appears in the request table.
   - Other endpoint sections untouched.

**Key talking points:**
- Path filters keep the agent from waking up on unrelated commits.
- The agent reads the **Zod schemas** as ground truth — it never invents
  fields.
- `protected-files: fallback-to-issue` means if the diff would touch
  source code, the agent opens an issue instead.

---

## Chapter 3 — Continuous Testing (~4 min · ⭐⭐)

**Storyline:** *"You can't merge a PR with <80% coverage. Fine — but who
writes the tests for the legacy file at 42% from three years ago?"*

### Steps

1. Open [`.github/workflows/continuous-testing.md`](../../.github/workflows/continuous-testing.md).
   Read the **target picking algorithm** aloud.
2. Trigger manually: `gh workflow run continuous-testing.lock.yml`.
3. While it runs, show the most recent coverage artifact in the Actions tab.
4. Open the resulting PR. Show:
   - Only one `*.test.ts` file changed (or extended).
   - Tests use factories from `src/tests/factories.ts`.
   - Body has a **before / projected after** coverage table.
5. Run `npm test` locally on the branch — show the new tests pass.

**Key talking points:**
- The agent picks the worst file by **branch coverage**, not statement.
- Diff capped at 300 lines — keeps reviews humane.
- The agent will refuse to touch production code to make tests pass — it'll
  open an issue instead recommending a refactor.

---

## Chapter 4 — Incident Response (~4 min · ⭐⭐⭐)

**Storyline:** *"It's 2 AM. CI failed on main. Who looks at the logs?"*

### Steps

1. Open [`.github/workflows/incident-response.md`](../../.github/workflows/incident-response.md).
   Highlight the **trigger guard** — only `main`, only failures, only `CI/CD
   Pipeline`.
2. Open the seeded failed CI run from the Actions tab.
3. Find the resulting incident issue in the Issues tab. Show:
   - Bucket classification (e.g., `dependency` or `flake`).
   - The first failing assertion quoted verbatim.
   - History (has this test failed in the last 30 runs?).
   - Suggested next step + owner suggestion (no auto-assignment).

**Key talking points:**
- The agent **does not auto-revert** PRs and **does not auto-fix** regressions.
- It will only open a fix-PR for `dependency` or `flag` causes — and only
  when the change is a one-line config or version pin.
- This is "second pair of eyes," not "autonomous remediation."

---

## Chapter 5 — Dependency Updates (~3 min · ⭐⭐)

**Storyline:** *"Dependabot opens 30 PRs a week. Nobody reviews them. They
rot. Let's coalesce."*

### Steps

1. Open [`.github/workflows/dependency-update.md`](../../.github/workflows/dependency-update.md).
   Point at the **scope** section — patches only by default; `@azure/*` is
   off-limits.
2. Trigger manually: `gh workflow run dependency-update.lock.yml`.
3. Open the resulting PR. Show:
   - `package.json` + lockfile updated together.
   - Body has an `Upgraded` table and a `Skipped` table with reasons.
   - **Verification** section pastes the tail of `npm test` proving the
     suite still passes.
4. Compare to a Dependabot PR — point out the agent's PR is **one** PR for
   N upgrades, with proof it works.

**Key talking points:**
- The agent reads each upgrade's CHANGELOG via the GitHub MCP and demotes
  anything mentioning "breaking" or "removed".
- If validation fails, the agent opens an **issue** with the failing
  command — not a broken PR.

---

## Chapter 6 — Security Audit (~4 min · ⭐⭐⭐)

**Storyline:** *"Code review caught the obvious stuff. What about the second
review nobody has time for?"*

### Steps

1. Open [`.github/workflows/security-audit.md`](../../.github/workflows/security-audit.md).
   Read the **OWASP API Top 10 priority order** aloud.
2. Show the most recent run's issues (seeded by the script: a contrived BOLA
   on `/api/v1/tasks/:id`).
3. Open the issue. Show:
   - `[security][high]` title — no critical details in the title.
   - Severity rubric in the body.
   - File + line + commit SHA citation (clickable).
   - Suggested fix as a **diff in a code block**, never committed.
   - Reviewer questions for the human.

**Key talking points:**
- This agent never opens PRs. Security fixes must be human-authored.
- Critical findings hide details in a `<details>` block — title is
  intentionally vague to avoid disclosure via notification emails.

---

## Chapter 7 — Release Notes (~3 min · ⭐ easy crowd-pleaser)

**Storyline:** *"GitHub auto-generates 'What's Changed: 47 PRs.' Nobody
reads that."*

### Steps

1. Open [`.github/workflows/release-notes.md`](../../.github/workflows/release-notes.md).
   Show the **Output structure** template.
2. Find the seeded draft release. Click **Publish** (or re-run the
   `release-notes` workflow with the `tag` input).
3. Refresh. The notes are rewritten with:
   - 2–4 narrative **Highlights** at the top.
   - PRs grouped by Conventional Commit type.
   - Dependency PRs collapsed to one line.
   - Contributors list at the bottom.

**Key talking points:**
- The Highlights section is plain English — no PR numbers, lead with verbs.
- The agent preserves anything between `<!-- end-generated -->` and the
  next heading — humans can pin notes that survive regeneration.

---

## Chapter 8 — Chaos Engineering (~3 min · ⭐⭐ closer)

**Storyline:** *"We've shown six agents that fix problems. Let's flip it —
one agent that creates problems on purpose."*

### Steps

1. Open [`.github/workflows/chaos-engineering.md`](../../.github/workflows/chaos-engineering.md).
   List the 13 scenarios on screen.
2. Trigger: `gh workflow run chaos-engineering.lock.yml -f scenario=random`.
3. Show the resulting draft PR with a realistic defect.
4. **Don't merge it.** Walk through the PR body — Scenario, Defect, Expected
   detection, Rollback command — and ask the audience: *"Which CI check or
   alert should catch this? How fast?"*

**Key talking points:**
- This is gameday-in-a-box. You have to specifically `gh pr merge` to
  arm it — the PR is draft + labelled `do-not-merge-without-review`.
- The agent's job is to *test your detection stack*, not your code.

---

## Closing slide / wrap-up (~2 min)

Walk back through the catalog one more time. Numbers to land:

- **8 workflows.** Each is a markdown file under 100 lines.
- **One language.** Plain English in `.md`, compiled to YAML by `gh aw compile`.
- **One firewall.** All eight run sandboxed with `network.allowed: ["github"]`.
- **One safety pattern.** Every workflow caps PRs/issues per run; nothing
  ever pushes to `main` directly.

> *"The human's role didn't disappear — it shifted from author to reviewer.
> That's the Agentic DevOps thesis."*

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Workflow doesn't trigger on `issues: opened` | Repo settings → Actions → "Allow GitHub Actions to create and approve pull requests" disabled | Enable it (org admin) |
| `gh aw compile` errors on frontmatter | YAML indent off, or unsupported `safe-outputs` key | `gh aw compile --strict` to see exact error |
| Agent says "permission denied" | Missing `permissions:` key, or repo `GITHUB_TOKEN` permissions are read-only | Check repo settings → Actions → Workflow permissions |
| Continuous-testing run picks the wrong file | Coverage artifact from previous run is stale | Re-run `CI/CD Pipeline` first to refresh `coverage-report` |
| No labels appear on triaged issue | Repo doesn't have those label names yet | Run `scripts/seed-demo-data.ps1` to create them |

See also: [`demo-prompts.md`](./demo-prompts.md) (copy-paste prompts) and
[`cheat-sheet.md`](./cheat-sheet.md) (1-page quick reference).
