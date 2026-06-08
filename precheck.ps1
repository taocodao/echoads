# Swift Static Pre-Check for Arenza iOS
# Catches the most common build errors before pushing to CI

$swiftDir = "packages\arenza-ios\Arenza"
$files = Get-ChildItem -Path $swiftDir -Recurse -Filter "*.swift" | Select-Object -ExpandProperty FullName
$errors = @()
$warnings = @()

foreach ($file in $files) {
    $rel = $file.Replace((Get-Location).Path + "\", "")
    $lines = Get-Content $file
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++

        # CHECK 1: Duplicate extension Data { ... hexString
        if ($line -match "extension Data" -and $file -notmatch "SecureEnclaveManager") {
            $nextFew = $lines[$lineNum..([Math]::Min($lineNum+3, $lines.Count-1))] -join " "
            if ($nextFew -match "hexString") {
                $errors += "[DUP-EXT]  $rel`:$lineNum  Duplicate Data.hexString extension (canonical is in SecureEnclaveManager.swift)"
            }
        }

        # CHECK 2: @MainActor-isolated access from nonisolated sync context
        if ($line -match "ProfileEngine\.shared\." -or $line -match "ContextualMomentService\.shared\." -or $line -match "AnomalyDetector\.shared\.") {
            # Check if we are inside an actor or @MainActor class
            $context = $lines[([Math]::Max(0,$lineNum-20))..$lineNum] -join "`n"
            if ($context -notmatch "@MainActor" -and $context -notmatch "actor " -and $context -notmatch "await MainActor.run" -and $context -notmatch "func.*async") {
                $warnings += "[ISOLATION] $rel`:$lineNum  Possible @MainActor isolation crossing: $($line.Trim())"
            }
        }

        # CHECK 3: captured var mutation in concurrent closure
        if ($line -match "var \w+ = \d+" -and $lines[$lineNum..([Math]::Min($lineNum+10, $lines.Count-1))] -join " " | Select-String "Timer\.scheduledTimer|Task \{") {
            $warnings += "[CONCUR]   $rel`:$lineNum  Possible captured mutable var in concurrent closure: $($line.Trim())"
        }

        # CHECK 4: Notification name that doesn't exist
        if ($line -match "\.NSBundleDidLoad") {
            $errors += "[BAD-NOTIF] $rel`:$lineNum  .NSBundleDidLoad is not a valid NSNotification.Name"
        }

        # CHECK 5: Wrong init argument label
        if ($line -match "streakMultiplier:") {
            $context2 = $lines[([Math]::Max(0,$lineNum-5))..$lineNum] -join " "
            if ($context2 -match "UserPrediction\(") {
                $errors += "[WRONG-ARG] $rel`:$lineNum  UserPrediction uses 'streakMultiplierApplied:' not 'streakMultiplier:'"
            }
        }

        # CHECK 6: type-checker-intensive map closures with many fields
        if ($line -match "\.map\s*\{" -and $lines[$lineNum..([Math]::Min($lineNum+15, $lines.Count-1))] -join " " | Select-String "UUID\(\).*UUID\(\).*random") {
            $warnings += "[TYPECHK]  $rel`:$lineNum  Complex .map closure may cause type-checker timeout — consider breaking into a for-loop"
        }
    }
}

Write-Host ""
Write-Host "===== Arenza Swift Pre-Check =====" -ForegroundColor Cyan
Write-Host "Files scanned: $($files.Count)" -ForegroundColor DarkGray
Write-Host ""

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "[PASS] No issues found." -ForegroundColor Green
} else {
    if ($errors.Count -gt 0) {
        Write-Host "ERRORS ($($errors.Count)):" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        Write-Host ""
    }
    if ($warnings.Count -gt 0) {
        Write-Host "WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
        $warnings | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        Write-Host ""
    }
    if ($errors.Count -gt 0) {
        Write-Host "[FAIL] Fix errors before pushing." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "[WARN] Warnings only — review before pushing." -ForegroundColor Yellow
    }
}