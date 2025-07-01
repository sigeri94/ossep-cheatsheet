
# PowerShell Script to check PrintSpoofer and SpoolSample prerequisites

Write-Host "n[*] Checking for Print Spooler service status..." -ForegroundColor Cyan
$spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
if ($spooler.Status -eq "Running") {
    Write-Host "[+] Spooler service is running." -ForegroundColor Green
} else {
    Write-Host "[-] Spooler service is not running." -ForegroundColor Yellow
}

Write-Host "n[*] Checking for SeImpersonatePrivilege..." -ForegroundColor Cyan
$privs = whoami /priv | Select-String "SeImpersonatePrivilege"
if ($privs -match "Enabled") {
    Write-Host "[+] SeImpersonatePrivilege is enabled." -ForegroundColor Green
} else {
    Write-Host "[-] SeImpersonatePrivilege is not enabled." -ForegroundColor Yellow
}

Write-Host "n[*] Checking OS version..." -ForegroundColor Cyan
$osVersion = [System.Environment]::OSVersion.Version
$build = $osVersion.Build
Write-Host "[*] OS Build Number: $build"
if ($build -lt 20348) {
    Write-Host "[+] OS might be vulnerable (pre-Server 2022)." -ForegroundColor Green
} else {
    Write-Host "[-] OS is likely patched (Server 2022 or later)." -ForegroundColor Yellow
}

Write-Host "n[*] Checking named pipes for spoolss..." -ForegroundColor Cyan
$pipes = Get-ChildItem -Path \\.\pipe\ | Where-Object { $_.Name -match "spoolss" }
if ($pipes) {
    Write-Host "[+] spoolss pipe is available." -ForegroundColor Green
} else {
    Write-Host "[-] spoolss pipe not found." -ForegroundColor Yellow
}

Write-Host "`n[*] Summary:"
if ($spooler.Status -eq "Running" -and $privs -match "Enabled" -and $build -lt 20348 -and $pipes) {
    Write-Host "[*] Target is LIKELY vulnerable to PrintSpoofer or SpoolSample." -ForegroundColor Green
} else {
    Write-Host "[*] Target is NOT likely vulnerable, or more checks are needed." -ForegroundColor Red
}
