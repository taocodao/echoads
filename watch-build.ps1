param([int]$PollSeconds = 20)
$repo = "taocodao/echoads"
$workflow = "arenza-ios-build.yml"
$lastRunId = ""
Write-Host "Watching $repo / $workflow  (every ${PollSeconds}s)" -ForegroundColor Cyan
Write-Host "Ctrl+C to stop."; Write-Host ""
while ($true) {
    $runsJson = gh api "repos/$repo/actions/workflows/$workflow/runs?per_page=1" 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "  API error - retrying..." -ForegroundColor Yellow; Start-Sleep -Seconds $PollSeconds; continue }
    $run = ($runsJson | ConvertFrom-Json).workflow_runs[0]
    if (-not $run) { Write-Host "  No runs yet" -ForegroundColor DarkGray; Start-Sleep -Seconds $PollSeconds; continue }
    $runId = $run.id; $status = $run.status; $conclusion = $run.conclusion
    $ts = Get-Date -f "HH:mm:ss"
    if ($status -eq "in_progress" -or $status -eq "queued") {
        Write-Host "  [$ts] Run #$($run.run_number) $status - $( ($run.head_commit.message -split \"`n\")[0] )" -ForegroundColor DarkCyan
        Start-Sleep -Seconds $PollSeconds; continue
    }
    if ($runId -eq $lastRunId) { Start-Sleep -Seconds $PollSeconds; continue }
    $lastRunId = $runId
    if ($conclusion -eq "success") {
        Write-Host "  [$ts] PASS Run #$($run.run_number)" -ForegroundColor Green
        Write-Host "  $($run.html_url)"; Write-Host ""
    } elseif ($conclusion -eq "failure" -or $conclusion -eq "timed_out") {
        Write-Host "  [$ts] FAIL Run #$($run.run_number)" -ForegroundColor Red
        Write-Host "  $($run.html_url)"; Write-Host ""
        $jobs = (gh api "repos/$repo/actions/runs/$runId/jobs" 2>&1 | ConvertFrom-Json).jobs
        foreach ($job in ($jobs | Where-Object { $_.conclusion -eq "failure" })) {
            Write-Host "  JOB: $($job.name)" -ForegroundColor Magenta
            $log = gh api "repos/$repo/actions/jobs/$($job.id)/logs" 2>&1
            $errLines = $log | Where-Object { $_ -match " error:" -or $_ -match "Build FAILED" }
            if ($errLines) {
                Write-Host "  === ERRORS ===" -ForegroundColor Red
                $errLines | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
            } else {
                Write-Host "  (last 30 lines)" -ForegroundColor Yellow
                $log | Select-Object -Last 30 | ForEach-Object { Write-Host "    $_" }
            }
        }
        Write-Host "  -- done --"; Write-Host ""
    } else {
        Write-Host "  [$ts] $($conclusion.ToUpper()) Run #$($run.run_number)" -ForegroundColor DarkGray
    }
    Start-Sleep -Seconds $PollSeconds
}