# Demo Prompts — Agentic DevOps

Copy-paste prompts for live demos. Pair with
[`README.md`](./README.md) (the full runbook) and
[`cheat-sheet.md`](./cheat-sheet.md) (the 1-page reference).

---

## A. Generating a workflow with Copilot Agent Mode (VS Code)

When the slide says *"these workflows are just markdown — let me show you how
fast it is to write one,"* paste this into VS Code Agent Mode:

```
Create a new GitHub Agentic Workflow at .github/workflows/onboarding-buddy.md
that follows the same pattern as .github/workflows/continuous-triage.md.

Trigger:
- issues: opened, when the issue has the label "good first issue"

Goal:
- Welcome the contributor by name.
- Point them at SampleApp/README.md and the relevant area's source folder
  (use the area:* labels from continuous-triage to decide).
- Suggest a CONTRIBUTING checklist tailored to their issue.
- Offer to pair-program via @copilot if they reply with "/pair".

Constraints:
- Sandboxed (network.allowed: ["github"])
- safe-outputs: 1 comment, 0 PRs
- timeout-minutes: 6
- Read-only contents permission

Match the existing tone and section structure of continuous-triage.md exactly.
```

This is a great "show, don't tell" — the agent emits a compliant prompt file
in ~30 seconds.

---

## B. Asking Copilot CLI to design the next workflow

For *"what other workflows would you add?"* use this in `copilot` (Plan mode,
`Shift+Tab`):

```
Plan a ninth Agentic Workflow for the SampleApp repo. Read every file in
.github/workflows/ to understand the existing pattern. Suggest exactly one
workflow that:

1. Is high-leverage for a Node.js/Express team (no inventing problems).
2. Has a clean trigger we don't already cover.
3. Doesn't overlap with continuous-triage, continuous-docs, continuous-testing,
   incident-response, dependency-update, security-audit, release-notes,
   flaky-test-detector, or chaos-engineering.
4. Can be safely sandboxed (no need for non-github egress).

Output: a one-page proposal with the trigger, frontmatter sketch, prompt-body
outline, and one paragraph on why it earns its slot.
```

Common audience suggestions you can fast-forward through with this:
- API contract drift (OpenAPI vs implementation)
- Changelog enforcement on every PR
- Stale-PR / stale-issue triage
- Cost-impact comments on infra PRs
- Runbook validator (read `sre/knowledge-base/runbooks/`, verify each command
  still exists in code)

---

## C. Live triage demo issue

Paste this when creating an issue live for the **continuous-triage** demo:

```
Title:
Tasks API returns 500 when teamId is missing on POST /api/v1/tasks

Body:
Repro:
1. POST /api/v1/tasks with body { "title": "test" } and no teamId
2. Server responds 500 with { "error": "INTERNAL_ERROR" }

Expected:
400 with a Zod validation message indicating teamId is required.

Notes:
- Reproduces on the deployed staging app and locally.
- Auth header was set; this isn't an auth issue.
- The Zod schema does mark teamId as required, so something is unwrapping
  before validation.
```

The agent should label this `type:bug`, `area:tasks`, `area:api`,
`priority:p2`, `ready` and point at `src/routes/tasks.ts` plus
`src/middleware/validation.ts`.

---

## D. Live route change for the continuous-docs demo

Paste this into `src/models/task.ts` (inside `TaskQuerySchema`) to drive a
docs refresh:

```ts
  // Filter for tasks due before a specific datetime (ISO 8601).
  // Returned tasks are still ordered by `sort` — this is a filter, not a sort.
  dueBefore: z.string().datetime().optional(),
```

Then in `src/routes/tasks.ts`, in `findAllTasks`:

```ts
    if (query.dueBefore) {
      conditions.push('c.dueDate < @dueBefore');
      parameters.push({ name: '@dueBefore', value: query.dueBefore });
    }
```

Commit message:

```
feat(tasks): support dueBefore filter on GET /api/v1/tasks
```

The `continuous-docs` agent should refresh **only** the `Tasks` section of
`docs/API.md` to add `dueBefore` as a request query param.

---

## E. Audience Q&A — common questions and crisp answers

> *"What if the agent goes rogue and opens 50 PRs?"*
>
> Each workflow declares `safe-outputs.create-pull-request.max: 1`. The
> compiled `.lock.yml` enforces it at the GitHub Actions runner level —
> the agent can't override it.

> *"Can it leak our secrets?"*
>
> `network.allowed: ["github"]`. The sandbox firewall blocks every
> outbound destination except `github.com` and `copilot.com`. There's no
> path from the agent to your DB or your secrets store.

> *"Why markdown? Why not just YAML?"*
>
> Markdown is the natural medium for instructions. YAML is the natural
> medium for runners. The split lets you write what you want in English
> and let `gh aw compile` produce the deterministic, audit-able runner
> manifest. Both files are committed — the YAML is the contract.

> *"How is this different from a custom GitHub Action?"*
>
> A custom action is code. An agentic workflow is a prompt. The difference
> shows up at maintenance time: when requirements change, you edit one
> sentence in the markdown, recompile, and ship.

> *"What model runs these?"*
>
> Copilot's coding agent — same model and harness as Copilot CLI and the
> cloud agent. Workflows inherit the org's Copilot policies.

> *"Per-run cost?"*
>
> Each invocation consumes one premium request from the org's Copilot quota.
> Triage is sub-minute; testing/incident response is the upper bound.

---

## F. The escape-hatch prompt

If a demo workflow misbehaves live (agent picks the wrong file, generates a
huge diff, etc.), use this in the PR/issue:

```
@copilot please re-run with these constraints:
- Only modify <file>.
- Limit the diff to <N> lines.
- Skip <thing it shouldn't have done>.
```

The cloud agent will pick up the comment and create a corrected revision on
the same branch. Useful when you want the audience to see the *iterate* step
of plan → execute → iterate → self-correct.
