# AESdecrypt.ps1 - AES decryption
# Ensure decrypted shellcode is stored as variable using $noAESrun


param([string]$AESKey)

if ($AESrun -or $global:AESrun) {
    try {
        # Use whichever AESrun variable exists
        $encryptedData = if ($AESrun) { $AESrun } else { $global:AESrun }
        
        # Hash the key (same method as encrypt script)
        $k = [System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($AESKey))
        
        # Decode and split (same format as encrypt script creates)
        $b = [Convert]::FromBase64String($encryptedData)
        $iv = $b[0..15]
        $ciphertext = $b[16..($b.Length-1)]
        
        # Setup AES (same settings as encrypt script)
        $aes = [Security.Cryptography.Aes]::Create()
        $aes.Key = $k
        $aes.IV = $iv
        $aes.Mode = [Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [Security.Cryptography.PaddingMode]::PKCS7
        
        # Decrypt
        $decryptor = $aes.CreateDecryptor()
        $decryptedBytes = $decryptor.TransformFinalBlock($ciphertext, 0, $ciphertext.Length)
        
        # Store as byte array (not converted to string)
        $global:noAESrun = [byte[]]$decryptedBytes
        
        # Cleanup
        $decryptor.Dispose()
        $aes.Dispose()
        
        Write-Host "Successfully decrypted to `$noAESrun byte array" -ForegroundColor Green
        Write-Host "Decrypted byte array length: $($global:noAESrun.Length) bytes" -ForegroundColor Cyan
        Write-Host "First 10 bytes: $($global:noAESrun[0..9] -join ',')" -ForegroundColor Cyan
        
    } catch {
        Write-Error "Decryption failed: $($_.Exception.Message)"
    }
} else {
    Write-Error "`$AESrun variable not found"
}