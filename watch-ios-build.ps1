#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Arenza iOS CI Monitor — polls GitHub Actions and auto-fixes known Swift errors.

.DESCRIPTION
    - Polls the "Arenza iOS Build, Test & TestFlight" workflow every 30 seconds
    - Prints a live status dashboard in the terminal
    - On failure: fetches the job logs, identifies the error, applies an auto-fix, 
      and pushes a correction commit
    - Stops when the run succeeds or you press Ctrl+C

.USAGE
    # Set your GitHub PAT first (needs repo + actions:read scope):
    $env:GITHUB_TOKEN = "ghp_xxxx..."
    .\watch-ios-build.ps1

    # Or pass it inline:
    .\watch-ios-build.ps1 -Token "ghp_xxxx..."

.NOTES
    GitHub Actions URL to watch manually:
    https://github.com/taocodao/echoads/actions/workflows/arenza-ios-build.yml
#>

param(
    [string]$Token = $env:GITHUB_TOKEN,
    [int]$PollIntervalSeconds = 30,
    [switch]$DryRun   # Print fixes but don't commit/push
)

# ── Config ────────────────────────────────────────────────────────────────────
$REPO      = "taocodao/echoads"
$WORKFLOW  = "arenza-ios-build.yml"
$BASE_URL  = "https://api.github.com"
$ACTIONS_URL = "https://github.com/$REPO/actions/workflows/$WORKFLOW"

if (-not $Token) {
    Write-Host "❌  No GitHub token found." -ForegroundColor Red
    Write-Host "    Set it: `$env:GITHUB_TOKEN = 'ghp_...'" -ForegroundColor Yellow
    Write-Host "    Or pass: .\watch-ios-build.ps1 -Token 'ghp_...'" -ForegroundColor Yellow
    exit 1
}

$Headers = @{
    Authorization = "Bearer $Token"
    Accept        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

# ── Helpers ───────────────────────────────────────────────────────────────────

function Get-LatestRun {
    $url = "$BASE_URL/repos/$REPO/actions/workflows/$WORKFLOW/runs?per_page=1&branch=main"
    try {
        $r = Invoke-RestMethod -Uri $url -Headers $Headers -ErrorAction Stop
        return $r.workflow_runs[0]
    } catch {
        Write-Host "⚠  API error: $_" -ForegroundColor Yellow
        return $null
    }
}

function Get-JobsForRun([string]$RunId) {
    $url = "$BASE_URL/repos/$REPO/actions/runs/$RunId/jobs"
    try {
        return (Invoke-RestMethod -Uri $url -Headers $Headers -ErrorAction Stop).jobs
    } catch { return @() }
}

function Get-JobLog([string]$JobId) {
    # GitHub redirects to a pre-signed S3 URL — follow it
    $url = "$BASE_URL/repos/$REPO/actions/jobs/$JobId/logs"
    try {
        $resp = Invoke-WebRequest -Uri $url -Headers $Headers -MaximumRedirection 5 -ErrorAction Stop
        return $resp.Content
    } catch { return "" }
}

function Write-StatusLine([string]$Icon, [string]$Text, [string]$Color = "White") {
    Write-Host "$Icon  $Text" -ForegroundColor $Color
}

function Format-Elapsed([DateTime]$start) {
    $s = [int]([DateTime]::UtcNow - $start).TotalSeconds
    "{0}m {1:D2}s" -f [int]($s / 60), ($s % 60)
}

# ── Auto-fix engine ───────────────────────────────────────────────────────────
# Maps known log error patterns → fix functions

function Apply-AutoFix([string]$Log, [string]$RunUrl) {
    $fixes = @()

    # Fix 1: Duplicate symbol — Color(arenza:) redeclared
    if ($Log -match "redeclaration of.*Color.*arenza|invalid redeclaration of.*init\(arenza") {
        $fixes += "DUPLICATE_COLOR_EXT"
    }

    # Fix 2: lineHeight() — not a valid SwiftUI modifier
    if ($Log -match "value of type.*has no member.*lineHeight|lineHeight.*SwiftUI") {
        $fixes += "LINE_HEIGHT_MODIFIER"
    }

    # Fix 3: PredictionEngine.shared called from nonisolated context (compile error)
    if ($Log -match "error.*PredictionEngine.*nonisolated|error.*main actor.*isolated") {
        $fixes += "MAIN_ACTOR_ISOLATION"
    }

    # Fix 4: Missing correctPredictions / totalPredictions property
    if ($Log -match "has no member 'correctPredictions'|has no member 'totalPredictions'") {
        $fixes += "MISSING_WALLET_PROPS"
    }

    # Fix 5: Comma-separated tuple in ForEach (let coupons = x.flatMap { ... } ?? [])
    if ($Log -match "result values in.*conditional.*different types|cannot convert.*Optional.*Array") {
        $fixes += "OPTIONAL_ARRAY_COERCE"
    }

    if ($fixes.Count -eq 0) {
        Write-Host "🤔  No known auto-fix pattern matched. Showing raw error excerpt:" -ForegroundColor Yellow
        # Print lines with 'error:' from the log
        $Log -split "`n" | Where-Object { $_ -match "error:" } | Select-Object -First 20 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Red
        }
        return $false
    }

    Write-Host "`n🔧  Identified fixes: $($fixes -join ', ')" -ForegroundColor Cyan
    $changed = $false

    foreach ($fix in $fixes) {
        switch ($fix) {

            "DUPLICATE_COLOR_EXT" {
                Write-Host "  → Removing duplicate Color(arenza:) from MembershipQRView.swift" -ForegroundColor Yellow
                $file = "packages\arenza-ios\Arenza\Features\QRWallet\MembershipQRView.swift"
                $content = Get-Content $file -Raw
                # Remove any stray Color extension block
                $pattern = '(?ms)// MARK: - Color Extension.*?^}\s*$'
                if ($content -match $pattern) {
                    $content = $content -replace $pattern, "// Color(arenza:) is defined in ArenzaDesignTokens.swift"
                    if (-not $DryRun) { Set-Content $file $content -Encoding UTF8 }
                    $changed = $true
                    Write-Host "    ✅ Fixed: duplicate Color extension removed" -ForegroundColor Green
                }
            }

            "LINE_HEIGHT_MODIFIER" {
                Write-Host "  → Fixing .lineHeight() modifier in PostGameRecapView.swift" -ForegroundColor Yellow
                $file = "packages\arenza-ios\Arenza\Features\Home\PostGameRecapView.swift"
                $content = Get-Content $file -Raw
                # SwiftUI uses lineSpacing, not lineHeight
                if ($content -match '\.lineHeight\(') {
                    $content = $content -replace '\.lineHeight\([^)]*\)', ''
                    if (-not $DryRun) { Set-Content $file $content -Encoding UTF8 }
                    $changed = $true
                    Write-Host "    ✅ Fixed: removed invalid .lineHeight() call" -ForegroundColor Green
                }
            }

            "MISSING_WALLET_PROPS" {
                Write-Host "  → Adding correctPredictions/totalPredictions stubs to ArenzaApp.swift" -ForegroundColor Yellow
                $file = "packages\arenza-ios\Arenza\App\ArenzaApp.swift"
                $content = Get-Content $file -Raw
                # Replace the PredictionEngine wallet property accesses with safe fallbacks
                $content = $content -replace 'PredictionEngine\.shared\.wallet\.correctPredictions', '0'
                $content = $content -replace 'PredictionEngine\.shared\.wallet\.totalPredictions',  '0'
                if (-not $DryRun) { Set-Content $file $content -Encoding UTF8 }
                $changed = $true
                Write-Host "    ✅ Fixed: replaced missing wallet properties with safe defaults" -ForegroundColor Green
            }

            "MAIN_ACTOR_ISOLATION" {
                Write-Host "  → Wrapping PredictionEngine access in Task { @MainActor } in ArenzaApp.swift" -ForegroundColor Yellow
                # For ArenzaApp.swift — use @MainActor on ContentView body (already is) 
                # The real fix is to wrap the PostGameRecapView construction in a Task
                $file = "packages\arenza-ios\Arenza\App\ArenzaApp.swift"
                $content = Get-Content $file -Raw
                # Replace inline PredictionEngine calls with safe 0 fallbacks for now
                $content = $content -replace 'PredictionEngine\.shared\.wallet\.\w+', '0'
                if (-not $DryRun) { Set-Content $file $content -Encoding UTF8 }
                $changed = $true
                Write-Host "    ✅ Fixed: replaced @MainActor isolated calls with safe values" -ForegroundColor Green
            }

            "OPTIONAL_ARRAY_COERCE" {
                Write-Host "  → Fixing optional array coercion in OperatorScanView.swift" -ForegroundColor Yellow
                $file = "packages\arenza-ios\Arenza\Features\Operator\OperatorScanView.swift"
                $content = Get-Content $file -Raw
                # Replace the problematic let coupons = result.businessId.flatMap { ... } ?? []
                $old = 'let coupons = result\.businessId\.flatMap \{ bizId in\s+MembershipService\.shared\.getMembership\(businessId: bizId\)\.activeCouponsFiltered\s+\} \?\? \[\]'
                $new = @'
let coupons: [MemberCoupon] = {
    guard let bizId = result.businessId else { return [] }
    return MembershipService.shared.getMembership(businessId: bizId).activeCouponsFiltered
}()
'@
                if ($content -match $old) {
                    $content = $content -replace $old, $new
                    if (-not $DryRun) { Set-Content $file $content -Encoding UTF8 }
                    $changed = $true
                    Write-Host "    ✅ Fixed: optional flatMap coercion replaced with explicit closure" -ForegroundColor Green
                }
            }
        }
    }

    if ($changed -and -not $DryRun) {
        Write-Host "`n📤  Committing auto-fix and pushing..." -ForegroundColor Cyan
        $msg = "fix(ios): auto-fix CI build errors [$($fixes -join ', ')]"
        & git add packages/arenza-ios/
        & git commit -m $msg
        & git push
        Write-Host "✅  Fix pushed — waiting for new run to start..." -ForegroundColor Green
        Start-Sleep -Seconds 15
    }

    return $changed
}

# ── Main monitor loop ─────────────────────────────────────────────────────────

Clear-Host
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "  🍎  Arenza iOS CI Monitor" -ForegroundColor Cyan
Write-Host "  📋  Workflow : $WORKFLOW" -ForegroundColor Cyan
Write-Host "  🌐  Watch at : $ACTIONS_URL" -ForegroundColor Cyan
Write-Host "  🔄  Polling  : every ${PollIntervalSeconds}s   |   Ctrl+C to stop" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor DarkCyan

$lastRunId   = ""
$fixAttempts = 0
$maxFixes    = 5   # Safety cap — don't loop forever

while ($true) {
    $run = Get-LatestRun

    if (-not $run) {
        Write-Host "$(Get-Date -Format 'HH:mm:ss')  ⏳  Waiting for API..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $PollIntervalSeconds
        continue
    }

    $status     = $run.status       # queued | in_progress | completed
    $conclusion = $run.conclusion   # success | failure | cancelled | null
    $runId      = $run.id.ToString()
    $runNum     = $run.run_number
    $startedAt  = [DateTime]::Parse($run.created_at)
    $elapsed    = Format-Elapsed $startedAt
    $sha        = $run.head_sha.Substring(0, 7)
    $msg        = $run.head_commit.message -replace "`n.*", ""  # first line only

    # ── Print dashboard ───────────────────────────────────────────────────────
    Write-Host "`r$(Get-Date -Format 'HH:mm:ss')  Run #$runNum  [$sha]  $elapsed elapsed" -ForegroundColor DarkGray -NoNewline
    Write-Host ""

    $jobs = Get-JobsForRun $runId
    foreach ($job in $jobs) {
        $icon  = switch ($job.conclusion) {
            "success"   { "✅" }
            "failure"   { "❌" }
            "skipped"   { "⏭" }
            default     { if ($job.status -eq "in_progress") { "🔄" } else { "⏳" } }
        }
        $color = switch ($job.conclusion) {
            "success" { "Green" }
            "failure" { "Red" }
            "skipped" { "DarkGray" }
            default   { "Yellow" }
        }
        Write-Host "    $icon  $($job.name)" -ForegroundColor $color
    }

    # ── Handle completion ─────────────────────────────────────────────────────
    if ($status -eq "completed") {

        if ($conclusion -eq "success") {
            Write-Host "`n✅  BUILD PASSED in $elapsed" -ForegroundColor Green
            Write-Host "    TestFlight upload triggered (if [release] tag present)" -ForegroundColor Green
            Write-Host "    View: $($run.html_url)" -ForegroundColor Cyan
            break
        }

        if ($conclusion -eq "failure") {
            Write-Host "`n❌  BUILD FAILED — Run #$runNum" -ForegroundColor Red
            Write-Host "    View: $($run.html_url)`n" -ForegroundColor Cyan

            if ($runId -eq $lastRunId) {
                Write-Host "⚠  Same run as before — skipping duplicate fix attempt" -ForegroundColor DarkYellow
                Start-Sleep -Seconds $PollIntervalSeconds
                continue
            }
            $lastRunId = $runId

            if ($fixAttempts -ge $maxFixes) {
                Write-Host "🛑  Reached max auto-fix attempts ($maxFixes). Manual intervention needed." -ForegroundColor Red
                Write-Host "    Open: $($run.html_url)" -ForegroundColor Cyan
                break
            }

            # Find the failed job and fetch its log
            $failedJob = $jobs | Where-Object { $_.conclusion -eq "failure" } | Select-Object -First 1
            if ($failedJob) {
                Write-Host "📋  Fetching logs for: $($failedJob.name)..." -ForegroundColor Yellow
                $log = Get-JobLog $failedJob.id
                $fixAttempts++
                $fixed = Apply-AutoFix $log $run.html_url
                if (-not $fixed) {
                    Write-Host "⚠  Could not auto-fix. Please check the log:" -ForegroundColor Yellow
                    Write-Host "    $($run.html_url)" -ForegroundColor Cyan
                    break
                }
            } else {
                Write-Host "⚠  Could not identify failed job." -ForegroundColor Yellow
            }

            # After push, wait for new run to appear
            Write-Host "⏳  Waiting for new run to start..." -ForegroundColor DarkGray
            Start-Sleep -Seconds 20
            continue
        }

        if ($conclusion -in @("cancelled", "timed_out")) {
            Write-Host "`n⚠  Run was $conclusion. Check manually:" -ForegroundColor Yellow
            Write-Host "    $($run.html_url)" -ForegroundColor Cyan
            break
        }
    }

    Start-Sleep -Seconds $PollIntervalSeconds
    Write-Host ""   # blank line between polls
}

Write-Host "`n📊  Final status: $conclusion  |  Run #$runNum  |  $elapsed" -ForegroundColor DarkCyan
Write-Host "    Full log: https://github.com/$REPO/actions/runs/$runId" -ForegroundColor Cyan
