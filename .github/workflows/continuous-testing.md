---
on:
  schedule:
    - cron: "0 6 * * 1"   # Mondays 06:00 UTC
  workflow_dispatch:
    inputs:
      target_file:
        description: 'Specific src/ file to target (leave blank for auto-pick)'
        required: false
        type: string
      coverage_floor:
        description: 'Coverage % below which a file is eligible'
        required: false
        default: '80'
        type: string

permissions:
  contents: read

engine: copilot

network:
  allowed:
    - "github"

safe-outputs:
  create-pull-request:
    max: 1
    draft: true
    title-prefix: "[tests] "
    protected-files: fallback-to-issue
    labels: ["testing", "agentic-workflow"]
  create-issue:
    max: 1
    labels: ["testing", "agentic-workflow"]

timeout-minutes: 25
---

# Continuous Testing Agent

You grow Jest test coverage one file at a time. Each run, you pick the **single
worst-covered source file** and add focused tests until that file clears the
80% floor across statements, branches, functions, and lines.

## Input

- Latest coverage report from the most recent `Test` job on `main`
  (artifact name: `coverage-report`, file: `coverage/coverage-summary.json`).
- The source file you select must live under `src/` and exclude `*.test.ts`,
  `src/index.ts`, and anything under `src/tests/`.
- If `workflow_dispatch.inputs.target_file` is provided, use that file
  unconditionally (skip the auto-pick).

## How to pick the target

1. Parse `coverage/coverage-summary.json`.
2. Filter to files where statement coverage `<` `coverage_floor` (default 80).
3. Among those, pick the file with the **lowest** branch coverage. Ties broken
   by file size (smaller wins, faster feedback).
4. If the filtered list is empty, open an **issue** titled
   `Continuous testing: nothing below the coverage floor — nice work` and stop.

## What "good tests" look like (per `.github/copilot-instructions.md`)

- Colocated: `src/foo/bar.ts` → `src/foo/bar.test.ts`.
- Use Jest + Supertest. For routes, exercise the handler through the Express
  app, not by calling functions directly.
- Use the existing factories in `src/tests/factories.ts`. Never hardcode UUIDs,
  dates, or auth headers.
- Cover, in order: happy path → input validation (400) → auth (401) →
  authorization (403) → not found (404) → edge cases (empty list, max length,
  unicode).
- Mock Cosmos DB and Entra ID. Do not require any environment variables.
- Use AAA structure with descriptive `it("should ...")` names.

## Constraints

- Add or extend **at most one** `*.test.ts` file. Do not modify the source
  file under test except to export a private helper that is otherwise
  untestable — and only as a last resort.
- Do not change `package.json`, `jest.config.js`, or any tooling.
- Do not lower coverage thresholds. If you cannot reach 80% without changing
  production code, stop after the highest-quality additions you can make and
  document the remaining gap in the PR body.
- Total diff must be ≤ 300 lines.

## Output

Open a single **draft** PR titled
`[tests] Raise coverage on <relative-path>` with body sections:

- **Target file** — path + the before-coverage numbers from the artifact.
- **What changed** — list of new `describe`/`it` cases.
- **Coverage delta (estimated)** — projected after-numbers + reasoning.
- **Out of scope** — any branches you deliberately did not cover (e.g.,
  unreachable error paths) and why.
- **Reviewer checklist** — checkbox list (no factory hardcodes, no console.log,
  no real network/DB calls).

If you cannot make meaningful progress (e.g., the file is dead code or pure
type definitions), open an **issue** instead recommending deletion or refactor.
