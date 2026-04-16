<#
.SYNOPSIS
    Generates a random temporary password.

.DESCRIPTION
    Creates a secure temporary password for password reset operations.
    Includes uppercase, lowercase, numbers, and special characters.

.EXAMPLE
    $password = New-TemporaryPassword
#>
function New-TemporaryPassword {
    [CmdletBinding()]
    param()
    
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $numbers = '0123456789'
    $special = '!@#$%^&*()_+-=[]{}|;:,.<>?'
    
    $all = $uppercase + $lowercase + $numbers + $special
    $password = @()
    
    # Ensure at least one of each type
    $password += $uppercase[(Get-Random -Maximum $uppercase.Length)]
    $password += $lowercase[(Get-Random -Maximum $lowercase.Length)]
    $password += $numbers[(Get-Random -Maximum $numbers.Length)]
    $password += $special[(Get-Random -Maximum $special.Length)]
    
    # Fill remaining 8 characters
    for ($i = 0; $i -lt 8; $i++) {
        $password += $all[(Get-Random -Maximum $all.Length)]
    }
    
    # Shuffle the password
    $password = $password | Sort-Object { Get-Random }
    return -join $password
}
