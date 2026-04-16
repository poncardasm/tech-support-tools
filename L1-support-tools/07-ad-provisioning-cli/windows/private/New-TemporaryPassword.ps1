function New-TemporaryPassword {
    <#
    .SYNOPSIS
        Generates a secure temporary password.
    .DESCRIPTION
        Creates a random password meeting common complexity requirements:
        - At least 12 characters
        - Uppercase, lowercase, numbers, and special characters
    .OUTPUTS
        String containing the generated password
    #>
    [CmdletBinding()]
    param(
        [int]$Length = 16
    )
    
    $uppercase = 'ABCDEFGHJKLMNPQRSTUVWXYZ'  # Excludes I, O to avoid confusion
    $lowercase = 'abcdefghijkmnpqrstuvwxyz'  # Excludes l, o to avoid confusion
    $numbers = '23456789'                     # Excludes 0, 1 to avoid confusion
    $special = '!@#$%^&*'
    
    $allChars = $uppercase + $lowercase + $numbers + $special
    
    # Ensure at least one of each type
    $password = @(
        $uppercase[(Get-Random -Maximum $uppercase.Length)]
        $lowercase[(Get-Random -Maximum $lowercase.Length)]
        $numbers[(Get-Random -Maximum $numbers.Length)]
        $special[(Get-Random -Maximum $special.Length)]
    )
    
    # Fill the rest randomly
    for ($i = 4; $i -lt $Length; $i++) {
        $password += $allChars[(Get-Random -Maximum $allChars.Length)]
    }
    
    # Shuffle the password
    $password = $password | Sort-Object { Get-Random }
    
    return -join $password
}
