#---------- Registry Run Keys (System-wide and Current User)
$runKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)

Write-Host "`n[+] Registry Run/RunOnce Keys:"
foreach ($key in $runKeys) {
    Write-Host "`n$key"
    try {
        Get-ItemProperty -Path $key | ForEach-Object {
            $_.PSObject.Properties | ForEach-Object {
                if ($_.Name -ne "PSPath") {
                    Write-Host "    $($_.Name): $($_.Value)"
                }
            }
        }
    } catch {
        Write-Host "    [!] Cannot access: $key"
    }
}

#----------- start up
Set-Location "C:\Users"

# Define file types to search for
$fileTypes = @("ConsoleHost_history.txt", "*.bat", "*.ps1", "*.pub")

# Search and display contents
foreach ($type in $fileTypes) {
    Write-Output "`n`nSearching for: $type"
    $files = Get-ChildItem -Recurse -Filter $type -ErrorAction SilentlyContinue -File
    foreach ($file in $files) {
        Write-Output "`n--- [$($file.FullName)] ---"
        $ext = $file.Extension.ToLower()
        if ($ext -eq ".txt" -or $ext -eq ".bat" -or $ext -eq ".ps1") {
            try {
                Get-Content $file.FullName -ErrorAction Stop
            } catch {
                Write-Warning "Failed to read $($file.FullName): $_"
            }
        } else {
            Write-Output "    [Skipped content: unsupported extension $ext]"
        }
    }
}

# Check Startup folders for all users and display file contents if any
Write-Output "`n`nScanning per-user Startup folders..."
Get-ChildItem "C:\Users" -Directory | ForEach-Object {
    $startupPath = Join-Path $_.FullName "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path $startupPath) {
        $startupFiles = Get-ChildItem -Path $startupPath -Force -File -ErrorAction SilentlyContinue
        if ($startupFiles.Count -gt 0) {
            Write-Output "`nContents of: $startupPath"
            foreach ($file in $startupFiles) {
                Write-Output "`n--- [$($file.FullName)] ---"
                $ext = $file.Extension.ToLower()
                if ($ext -eq ".txt" -or $ext -eq ".bat" -or $ext -eq ".ps1") {
                    try {
                        Get-Content $file.FullName -ErrorAction Stop
                    } catch {
                        Write-Warning "Failed to read $($file.FullName): $_"
                    }
                } else {
                    Write-Output "    [Skipped content: unsupported extension $ext]"
                }
            }
        }
    }
}

# Also scan the All Users (common) Startup folder
Write-Output "`n`nScanning common Startup folder..."
$commonStartupPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
if (Test-Path $commonStartupPath) {
    $commonStartupFiles = Get-ChildItem -Path $commonStartupPath -Force -File -ErrorAction SilentlyContinue
    if ($commonStartupFiles.Count -gt 0) {
        Write-Output "`nContents of: $commonStartupPath"
        foreach ($file in $commonStartupFiles) {
            Write-Output "`n--- [$($file.FullName)] ---"
            $ext = $file.Extension.ToLower()
            if ($ext -eq ".txt" -or $ext -eq ".bat" -or $ext -eq ".ps1") {
                try {
                    Get-Content $file.FullName -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to read $($file.FullName): $_"
                }
            } else {
                Write-Output "    [Skipped content: unsupported extension $ext]"
            }
        }
    }
}

#----- Scheduled Tasks (exclude disabled or not currently running)
Write-Host "`n[+] Enabled and Running Scheduled Tasks:"
try {
    $tasks = Get-ScheduledTask | Where-Object {
        $_.State -ne 'Disabled'
    }

    foreach ($task in $tasks) {
        try {
            $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath
            $lastRun = $info.LastRunTime
            $isActive = $task.State -eq 'Ready' -or $task.State -eq 'Running'

            # Skip if last run year is 1999 or never run
            if ($lastRun -ne $null -and $lastRun.Year -ne 1999 -and $isActive) {
                $output = [PSCustomObject]@{
                    TaskName     = "$($task.TaskPath)$($task.TaskName)"
                    LastRunTime  = $lastRun
                    RunAsUser    = $task.Principal.UserId
                    State        = $task.State
                }
                $output | Format-List
            }
        } catch {
            Write-Warning "Failed to get info for task: $($task.TaskName)"
        }
    }
} catch {
    Write-Host "    [!] Error retrieving scheduled tasks."
}

#--- Services set to Auto Start (including Delayed) and Running
Write-Host "`n[+] Auto-start & Running Services (including Delayed Start):"
try {
    Get-WmiObject -Class Win32_Service |
    Where-Object {
        ($_.StartMode -eq "Auto" -or $_.StartMode -eq "Delayed Auto") -and
        $_.State -eq "Running"
    } |
    ForEach-Object {
        [PSCustomObject]@{
            Name        = $_.Name
            DisplayName = $_.DisplayName
            StartMode   = $_.StartMode
            State       = $_.State
            StartName   = $_.StartName
            PathName    = $_.PathName
        } | Format-List
    }
} catch {
    Write-Host "    [!] Error enumerating services."
}

# ---- Winlogon UserInit + Shell
Write-Host "`n[+] Winlogon UserInit & Shell Values:"
$winlogonKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
try {
    $userInit = Get-ItemProperty -Path $winlogonKey -Name "Userinit" -ErrorAction Stop
    $shell = Get-ItemProperty -Path $winlogonKey -Name "Shell" -ErrorAction Stop
    Write-Host "    Userinit: $($userInit.Userinit)"
    Write-Host "    Shell: $($shell.Shell)"
} catch {
    Write-Host "    [!] Error reading Winlogon keys."
}

Write-Host "`n=== Enumeration Complete ==="
