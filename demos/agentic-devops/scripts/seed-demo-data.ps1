#requires -Version 7.0
<#
.SYNOPSIS
    Seed a SampleApp clone with the artifacts the agentic-devops demo expects.

.DESCRIPTION
    Idempotent. Run before a live demo to make sure each chapter has something
    to act on:

    * Repository labels referenced by continuous-triage
    * One unlabelled issue for the triage demo
    * One file with low coverage for the testing demo
    * One failed CI/CD run on main for the incident-response demo
    * One draft release with auto-generated notes for the release-notes demo

    Safe to run repeatedly — every step checks for existing artifacts before
    creating new ones.

.PARAMETER Repo
    The OWNER/REPO. Defaults to the repo gh thinks you're in.

.PARAMETER SkipFailedRun
    Skip the "trigger a failed CI run" step (it's noisy and may hit Actions
    minutes). Use when you already have a recent failure.

.EXAMPLE
    pwsh ./seed-demo-data.ps1
    pwsh ./seed-demo-data.ps1 -Repo myorg/team-task-tracker -SkipFailedRun
#>

[CmdletBinding()]
param(
    [string] $Repo,
    [switch] $SkipFailedRun
)

$ErrorActionPreference = 'Stop'

if (-not $Repo) {
    $Repo = (gh repo view --json nameWithOwner -q .nameWithOwner)
}
Write-Host "Seeding demo data for $Repo" -ForegroundColor Cyan

# ---------- 1. Labels ----------
Write-Host "`n[1/5] Ensuring labels exist..." -ForegroundColor Cyan
$labels = @(
    @{ name = 'type:bug';        color = 'd73a4a' },
    @{ name = 'type:feature';    color = 'a2eeef' },
    @{ name = 'type:question';   color = 'd876e3' },
    @{ name = 'type:docs';       color = '0075ca' },
    @{ name = 'type:chore';      color = 'cfd3d7' },
    @{ name = 'type:security';   color = 'b60205' },

    @{ name = 'area:tasks';      color = 'fbca04' },
    @{ name = 'area:teams';      color = 'fbca04' },
    @{ name = 'area:dashboard';  color = 'fbca04' },
    @{ name = 'area:auth';       color = 'fbca04' },
    @{ name = 'area:api';        color = 'fbca04' },
    @{ name = 'area:db';         color = 'fbca04' },
    @{ name = 'area:ci';         color = 'fbca04' },
    @{ name = 'area:tests';      color = 'fbca04' },
    @{ name = 'area:infra';      color = 'fbca04' },

    @{ name = 'priority:p0';     color = '5319e7' },
    @{ name = 'priority:p1';     color = '6f42c1' },
    @{ name = 'priority:p2';     color = '8a63d2' },
    @{ name = 'priority:p3';     color = 'b794f4' },

    @{ name = 'needs:repro';     color = 'e99695' },
    @{ name = 'needs:design';    color = 'e99695' },
    @{ name = 'needs:owner';     color = 'e99695' },
    @{ name = 'ready';           color = '0e8a16' },

    @{ name = 'agentic-workflow'; color = '5319e7' },
    @{ name = 'incident';         color = 'b60205' },
    @{ name = 'security';         color = 'b60205' },
    @{ name = 'documentation';    color = '0075ca' },
    @{ name = 'testing';          color = 'fbca04' },
    @{ name = 'dependencies';     color = '0366d6' },
    @{ name = 'flaky-test';       color = 'fbca04' },
    @{ name = 'release';          color = '0e8a16' },
    @{ name = 'chaos-engineering';color = 'b60205' },
    @{ name = 'do-not-merge-without-review'; color = 'b60205' }
)
foreach ($l in $labels) {
    & gh label create $l.name --repo $Repo --color $l.color --force 2>&1 | Out-Null
}
Write-Host "  $($labels.Count) labels ensured." -ForegroundColor DarkGray

# ---------- 2. Triage demo issue ----------
Write-Host "`n[2/5] Ensuring an unlabelled issue for the triage demo..." -ForegroundColor Cyan
$existing = gh issue list --repo $Repo --search 'in:title "Tasks API returns 500"' --json number,labels -L 1 |
    ConvertFrom-Json
if ($existing.Count -gt 0 -and $existing[0].labels.Count -eq 0) {
    Write-Host "  Already exists as #$($existing[0].number)." -ForegroundColor DarkGray
} else {
    $body = @"
**Repro**

1. POST /api/v1/tasks with body { "title": "test" } and no teamId
2. Server responds 500 with { "error": "INTERNAL_ERROR" }

**Expected**

400 with a Zod validation message indicating teamId is required.

**Notes**

- Reproduces on staging and locally.
- Auth header was set; this isn't an auth issue.
- The Zod schema does mark teamId as required, so something is unwrapping
  before validation.
"@
    gh issue create --repo $Repo `
        --title 'Tasks API returns 500 when teamId is missing on POST /api/v1/tasks' `
        --body $body | Out-Host
}

# ---------- 3. Low-coverage file ----------
Write-Host "`n[3/5] Checking for a low-coverage file..." -ForegroundColor Cyan
$coverageDir = Join-Path (Resolve-Path "$PSScriptRoot/../../..").Path 'coverage'
if (-not (Test-Path $coverageDir)) {
    Write-Host "  No coverage report yet. Run 'npm test' once on main, then re-run this script." -ForegroundColor Yellow
} else {
    Write-Host "  Coverage report present — continuous-testing has something to chew on." -ForegroundColor DarkGray
}

# ---------- 4. Failed CI run ----------
if ($SkipFailedRun) {
    Write-Host "`n[4/5] -SkipFailedRun set, leaving CI history untouched." -ForegroundColor DarkGray
} else {
    Write-Host "`n[4/5] Ensuring a recent failed CI run on main..." -ForegroundColor Cyan
    $failed = gh run list --repo $Repo --workflow 'CI/CD Pipeline' --branch main --status failure -L 1 --json databaseId,createdAt |
        ConvertFrom-Json
    if ($failed.Count -gt 0) {
        $age = (Get-Date) - [DateTime]::Parse($failed[0].createdAt)
        if ($age.TotalDays -lt 7) {
            Write-Host "  Recent failed run #$($failed[0].databaseId) from $([int]$age.TotalHours)h ago — good enough." -ForegroundColor DarkGray
        } else {
            Write-Host "  Last failed run is $([int]$age.TotalDays) days old. Consider triggering chaos-engineering and merging the PR to fail CI freshly." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  No failed runs found. Trigger chaos-engineering and merge the PR to seed one (or use -SkipFailedRun)." -ForegroundColor Yellow
    }
}

# ---------- 5. Draft release ----------
Write-Host "`n[5/5] Ensuring a draft release exists..." -ForegroundColor Cyan
$drafts = gh release list --repo $Repo -L 5 --json name,isDraft,tagName | ConvertFrom-Json
$existingDraft = $drafts | Where-Object { $_.isDraft -and $_.tagName -like 'v*' } | Select-Object -First 1
if ($existingDraft) {
    Write-Host "  Draft release '$($existingDraft.tagName)' already exists." -ForegroundColor DarkGray
} else {
    $stamp = (Get-Date -Format 'yyyy.MM.dd-HHmm')
    $tag   = "v0.$stamp-demo"
    Write-Host "  Creating draft release $tag with auto-generated notes..." -ForegroundColor DarkGray
    gh release create $tag --repo $Repo --draft --generate-notes --title "Demo $tag" --notes-start-tag main^ 2>&1 | Out-Host
}

Write-Host "`nSeed complete. You're ready to run the demo." -ForegroundColor Green
Write-Host "Next:" -ForegroundColor Green
Write-Host "  gh aw compile" -ForegroundColor Green
Write-Host "  git add .github && git commit -m 'compile agentic workflows' && git push" -ForegroundColor Green
Write-Host "  pwsh ./trigger-workflow.ps1 triage" -ForegroundColor Green
