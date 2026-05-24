# =============================================================
# Project Clarity — Windows Firewall Rule for QUIC/UDP
# Run this in PowerShell AS ADMINISTRATOR on the Windows host.
# Required to allow WSL2's moq-relay to be reachable from the browser.
# =============================================================

$RuleName = "Project Clarity - MOQ QUIC (UDP 4443)"
$Port = 4443

# Check if rule already exists
$existing = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host "✅ Firewall rule '$RuleName' already exists. Skipping." -ForegroundColor Green
} else {
    New-NetFirewallRule `
        -DisplayName $RuleName `
        -Direction Inbound `
        -Action Allow `
        -Protocol UDP `
        -LocalPort $Port `
        -Profile Any

    Write-Host "✅ Firewall rule created: UDP port $Port open for MOQ QUIC." -ForegroundColor Green
}

# Print WSL2 IP address for use in browser
Write-Host ""
Write-Host "Your WSL2 IP address:" -ForegroundColor Cyan
wsl hostname -I
Write-Host ""
Write-Host "Use this IP in your .env as MOQ_RELAY_URL:" -ForegroundColor Cyan
Write-Host "  MOQ_RELAY_URL=https://<WSL2-IP>:4443" -ForegroundColor Yellow
Write-Host ""
Write-Host "For local browser testing, you also need to trust the self-signed cert." -ForegroundColor Cyan
Write-Host "Pass the cert fingerprint to @kixelated/moq via the certFingerprint option." -ForegroundColor Cyan
