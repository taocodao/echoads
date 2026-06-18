# ci-monitor-loop.ps1
# Watches GitHub Actions for the latest iOS build run.
# Polls every 30s. On failure: fetches logs and prints Swift errors.
# Usage: .\ci-monitor-loop.ps1

$repo    = "taocodao/echoads"
$poll    = 30
$maxWait = 1800

Write-Host ""
Write-Host "[CI Monitor] Starting -- watching $repo" -ForegroundColor Cyan
Write-Host "[CI Monitor] Polling every ${poll}s (max ${maxWait}s)" -ForegroundColor Cyan
Write-Host ""

$start      = Get-Date
$lastRunId  = ""
$lastStatus = ""

while ($true) {
    $elapsed = (Get-Date) - $start
    if ($elapsed.TotalSeconds -gt $maxWait) {
        Write-Host "[CI Monitor] Timeout after ${maxWait}s. Exiting." -ForegroundColor Yellow
        break
    }

    # Fetch latest runs
    $json = gh run list --repo $repo --limit 10 --json databaseId,status,conclusion,workflowName,displayTitle 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[$(Get-Date -f 'HH:mm:ss')] gh cli error -- retrying..." -ForegroundColor DarkGray
        Start-Sleep $poll
        continue
    }

    $runs = $json | ConvertFrom-Json
    $run  = $runs | Where-Object { $_.workflowName -like "*iOS*" } | Select-Object -First 1
    if (-not $run) { $run = $runs | Select-Object -First 1 }

    if (-not $run) {
        Write-Host "[$(Get-Date -f 'HH:mm:ss')] No runs found -- waiting..." -ForegroundColor DarkGray
        Start-Sleep $poll
        continue
    }

    $runId  = $run.databaseId
    $status = $run.status
    $concl  = $run.conclusion
    $title  = if ($run.displayTitle.Length -gt 60) { $run.displayTitle.Substring(0,60) + "..." } else { $run.displayTitle }

    if ($runId -ne $lastRunId -or $status -ne $lastStatus) {
        $color = "White"
        if ($status -eq "completed") {
            $color = if ($concl -eq "success") { "Green" } else { "Red" }
        } elseif ($status -eq "in_progress") {
            $color = "Yellow"
        } elseif ($status -eq "queued") {
            $color = "DarkYellow"
        }
        Write-Host "[$(Get-Date -f 'HH:mm:ss')] Run #$runId  [$status/$concl]  $title" -ForegroundColor $color
        $lastRunId  = $runId
        $lastStatus = $status
    }

    if ($status -eq "completed") {
        if ($concl -eq "success") {
            Write-Host ""
            Write-Host "[CI Monitor] BUILD PASSED -- TestFlight upload triggered." -ForegroundColor Green
            Write-Host "             https://github.com/$repo/actions/runs/$runId"
            Write-Host ""
            break
        } else {
            Write-Host ""
            Write-Host "[CI Monitor] BUILD FAILED -- fetching error log..." -ForegroundColor Red
            Write-Host "             https://github.com/$repo/actions/runs/$runId"
            Write-Host ""

            # Print failed jobs
            try {
                $jobJson  = gh run view $runId --repo $repo --json jobs 2>&1 | ConvertFrom-Json
                $failJobs = $jobJson.jobs | Where-Object { $_.conclusion -eq "failure" }
                if ($failJobs) {
                    Write-Host "Failed jobs:" -ForegroundColor Red
                    $failJobs | ForEach-Object {
                        Write-Host "  - $($_.name)" -ForegroundColor DarkRed
                    }
                    Write-Host ""
                }
            } catch {}

            # Print Swift errors from log
            try {
                Write-Host "Swift compiler errors:" -ForegroundColor Red
                $log    = gh run view $runId --repo $repo --log 2>&1
                $errors = $log | Select-String -Pattern "error:|Build FAILED" | Select-Object -First 30
                if ($errors) {
                    $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkRed }
                } else {
                    Write-Host "  (no pattern matches -- check URL above for full log)" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "  (could not fetch log: $_)" -ForegroundColor DarkGray
            }

            Write-Host ""
            Write-Host "[CI Monitor] Fix the errors above, commit, and push to retry." -ForegroundColor Yellow
            Write-Host ""
            break
        }
    }

    Start-Sleep $poll
}
