$ldapServer = "dc02.gotham.com"
$baseDN = "dc=gotham,dc=com"
$ldapFilter = "(objectClass=user)"
$attributes = @("sAMAccountName", "memberOf")

$directoryEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$ldapServer/$baseDN")
$searcher = New-Object System.DirectoryServices.DirectorySearcher($directoryEntry)
$searcher.Filter = $ldapFilter
$searcher.PageSize = 1000
$attributes | ForEach-Object { $searcher.PropertiesToLoad.Add($_) | Out-Null }

$computers = @()

try {
    $results = $searcher.FindAll()
    foreach ($result in $results) {
        $account = $result.Properties["samaccountname"]
        if (-not $account) { continue }
        $account = $account[0]

        if ($account -like '*$') {
            $computers += $account
        } else {
            Write-Output "User: $account"
            $groups = $result.Properties["memberof"]
            foreach ($group in $groups) {
                $parts = $group -split ',' | Where-Object { $_ -like 'CN=*' }
                $cleanParts = $parts | ForEach-Object { $_.Substring(3) }
                $groupStr = $cleanParts -join ', '
                Write-Output "  Group: $groupStr"
            }
        }
    }

    foreach ($comp in $computers) {
        $hostname = $comp.TrimEnd('$')
        $fqdn = "$hostname.gotham.com"
        try {
            $ip = [System.Net.Dns]::GetHostAddresses($hostname) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
            if ($ip) {
                Write-Output "$($ip.IPAddressToString) $hostname $fqdn"
            } else {
                Write-Output "0.0.0.0 $hostname $fqdn"
            }
        } catch {
            Write-Output "0.0.0.0 $hostname $fqdn"
        }
    }
}
catch {
    Write-Error "LDAP query failed: $_"
}
