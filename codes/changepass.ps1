#make sure the login user have ACL to change other user password before run this script
$targetUsername = "alfred"
$newPassword = "Password1"

try {
    # Search for the user's DN
    $searcher = New-Object DirectoryServices.DirectorySearcher
    $searcher.Filter = "(&(objectClass=user)(sAMAccountName=$targetUsername))"
    $searcher.PropertiesToLoad.Add("distinguishedName") | Out-Null

    $result = $searcher.FindOne()
    if (-not $result) {
        Write-Warning "[X] Could not find user '$targetUsername'"
        return
    }

    $dn = $result.Properties["distinguishedName"][0]
    $ldapPath = "LDAP://$dn"
    Write-Host "[+] Found DN: $dn"

    # Connect to user object
    $user = New-Object DirectoryServices.DirectoryEntry($ldapPath)

    # Change the password
    $user.Invoke("SetPassword", $newPassword)
    $user.CommitChanges()

    Write-Host "[+] Password for '$targetUsername' changed successfully."
} catch {
    Write-Warning "[X] Error: $($_.Exception.Message)"
}

