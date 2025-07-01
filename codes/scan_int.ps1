# Read hosts from host.txt (format: IP HOSTNAME)
$hosts = Get-Content -Path "hosts.txt"

$ports = @(22, 80, 53, 443, 1433, 445, 3389, 25, 5985, 88, 464, 389, 636)
$timeout = 1000  # Timeout in milliseconds

foreach ($line in $hosts) {
    if ($line -match '^\s*(\d{1,3}(?:\.\d{1,3}){3})\s+(\S+)\s*$') {
        $ip = $matches[1]
        $hostname = $matches[2]
        $openPorts = @()

        foreach ($port in $ports) {
            try {
                $socket = New-Object System.Net.Sockets.Socket(
                    [System.Net.Sockets.AddressFamily]::InterNetwork,
                    [System.Net.Sockets.SocketType]::Stream,
                    [System.Net.Sockets.ProtocolType]::Tcp
                )

                $socket.SendTimeout = $timeout
                $socket.ReceiveTimeout = $timeout
                $async = $socket.BeginConnect($ip, $port, $null, $null)
                $success = $async.AsyncWaitHandle.WaitOne($timeout, $false)

                if ($success -and $socket.Connected) {
                    $openPorts += $port
                }

                $socket.Close()
            } catch {
                # Silent on failure
            }
        }

        if ($openPorts.Count -gt 0) {
            Write-Host "$ip - $hostname"
            Write-Host "open : $($openPorts -join ',')" -ForegroundColor Green
        } else {
            Write-Host "$ip - $hostname"
            Write-Host "open : none" -ForegroundColor Yellow
        }
    } else {
        Write-Warning "Invalid line format: $line"
    }
}
