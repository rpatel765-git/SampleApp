#requires -Version 7.0
<#
.SYNOPSIS
    Trigger any agentic workflow in the SampleApp by short name.

.DESCRIPTION
    Wraps `gh workflow run` with friendly aliases that match the workflow
    catalog in .github/workflows/AGENTIC-WORKFLOWS.md. Pass extra `-f key=value`
    arguments to forward to the workflow's inputs.

.PARAMETER Name
    Short name of the workflow. One of:
      triage      | continuous-triage
      docs        | continuous-docs
      testing     | continuous-testing
      incident    | incident-response
      deps        | dependency-update
      security    | security-audit
      release     | release-notes
      flaky       | flaky-test-detector
      chaos       | chaos-engineering

.PARAMETER Inputs
    Extra `key=value` pairs to forward to the workflow as `-f` arguments.

.PARAMETER Watch
    If set, runs `gh run watch` after triggering so the live output streams
    to your terminal.

.EXAMPLE
    pwsh ./trigger-workflow.ps1 triage
    pwsh ./trigger-workflow.ps1 chaos -Inputs @{ scenario = 'random' }
    pwsh ./trigger-workflow.ps1 incident -Inputs @{ run_id = '12345678' } -Watch
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string] $Name,

    [hashtable] $Inputs = @{},

    [switch] $Watch
)

$ErrorActionPreference = 'Stop'

$alias = @{
    'triage'             = 'continuous-triage'
    'continuous-triage'  = 'continuous-triage'
    'docs'               = 'continuous-docs'
    'continuous-docs'    = 'continuous-docs'
    'testing'            = 'continuous-testing'
    'continuous-testing' = 'continuous-testing'
    'incident'           = 'incident-response'
    'incident-response'  = 'incident-response'
    'deps'               = 'dependency-update'
    'dependencies'       = 'dependency-update'
    'dependency-update'  = 'dependency-update'
    'security'           = 'security-audit'
    'security-audit'     = 'security-audit'
    'release'            = 'release-notes'
    'release-notes'      = 'release-notes'
    'flaky'              = 'flaky-test-detector'
    'flaky-test-detector'= 'flaky-test-detector'
    'chaos'              = 'chaos-engineering'
    'chaos-engineering'  = 'chaos-engineering'
}

$key = $Name.ToLowerInvariant()
if (-not $alias.ContainsKey($key)) {
    Write-Error "Unknown workflow '$Name'. Run with no args or see AGENTIC-WORKFLOWS.md for the list."
}
$workflow = "$($alias[$key]).lock.yml"

# Verify gh + repo context
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "gh CLI is not authenticated. Run 'gh auth login' first."
}

# Build argument list
$args = @('workflow', 'run', $workflow)
foreach ($pair in $Inputs.GetEnumerator()) {
    $args += '-f'
    $args += "$($pair.Key)=$($pair.Value)"
}

Write-Host ""
Write-Host "Triggering $workflow ..." -ForegroundColor Cyan
if ($Inputs.Count -gt 0) {
    Write-Host "Inputs:" -ForegroundColor DarkGray
    foreach ($pair in $Inputs.GetEnumerator()) {
        Write-Host "  $($pair.Key) = $($pair.Value)" -ForegroundColor DarkGray
    }
}
Write-Host ""

& gh @args
if ($LASTEXITCODE -ne 0) {
    Write-Error "gh workflow run failed (exit $LASTEXITCODE). Has the .lock.yml been compiled and pushed to main?"
}

Write-Host ""
Write-Host "Run started. View it at:" -ForegroundColor Green
Write-Host "  $(gh repo view --json url -q .url)/actions/workflows/$workflow"

if ($Watch) {
    Write-Host ""
    Write-Host "Watching latest run..." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
    & gh run watch
}
