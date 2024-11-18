#!/usr/bin/env python3

import sys
from Crypto.Cipher import AES

# Define the key and IV
key = b"\x06\x02\x00\x00\x00\xa4\x00\x00\x52\x53\x41\x31\x00\x04\x00\x00"
iv = b"\x01\x00\x01\x00\x67\x24\x4F\x43\x6E\x67\x62\xF2\x5E\xA8\xD7\x04"

# Check if ciphertext is provided as an argument
if len(sys.argv) != 2:
    print("Usage: script.py <ciphertext>")
    print("Ciphertext format: Each byte separated by a newline.")
    sys.exit(1)

# Parse the ciphertext argument
try:
    ciphertext_input = sys.argv[1].strip().split("\n")
    ciphertext = bytes(map(int, ciphertext_input))
except ValueError:
    print("Error: Ciphertext must be a series of integers, each on a new line.")
    sys.exit(1)

# Decrypt the ciphertext
aes = AES.new(key, AES.MODE_CBC, IV=iv)
try:
    password = aes.decrypt(ciphertext).decode("utf-16").rstrip("\x00")
    print(f"[+] Found password: {password}")
except Exception as e:
    print(f"Error during decryption: {e}")
    sys.exit(1)
