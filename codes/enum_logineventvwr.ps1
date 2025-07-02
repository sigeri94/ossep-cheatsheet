$filter = @{
    Path = "C:\Windows\System32\winevt\Logs\Security.evtx"
    Id = 4624
    StartTime = [datetime]'2025-01-01'
    EndTime   = [datetime]'2025-12-31T23:59:59'
}

Get-WinEvent -FilterHashtable $filter | ForEach-Object {
    $msg = $_.Message

    # Extract Account Name
    $accountMatch = ($msg -split "New Logon:")[1] -split "Account Domain:" | Select-String "Account Name:\s+(.*)"
    $accountName = if ($accountMatch.Matches.Count -gt 0) { $accountMatch.Matches[0].Groups[1].Value.Trim() } else { "N/A" }

    # Skip system/service accounts
    if (
        $accountName -and
        $accountName -notmatch '^DWM-' -and
        $accountName -notmatch '^UMFD-' -and
        $accountName -notin @("SYSTEM", "LOCAL SERVICE", "NETWORK SERVICE")
    ) {
        # Workstation
        $workstationMatch = $msg | Select-String "Workstation Name:\s+(.*)"
        $workstation = if ($workstationMatch.Matches.Count -gt 0) { $workstationMatch.Matches[0].Groups[1].Value.Trim() } else { "N/A" }

        # IP Address
        $ipMatch = $msg | Select-String "Source Network Address:\s+(.*)"
        $ip = if ($ipMatch.Matches.Count -gt 0) { $ipMatch.Matches[0].Groups[1].Value.Trim() } else { "N/A" }

        [PSCustomObject]@{
            TimeCreated           = $_.TimeCreated
            AccountName           = $accountName
            WorkstationName       = $workstation
            SourceNetworkAddress  = $ip
        }
    }
} | Format-List
