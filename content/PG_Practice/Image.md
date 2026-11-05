---
Status: Done
OS: Linux
Difficulty: Medium
tags:
  - imageMagick
  - SUID
Date: 2026-11-05T20:53:00
Owned: 2026-11-05T21:54:00
---

---
# Enumeration
## Port Scan

## web
![[Screenshot 2026-11-05 at 20.56.32.png]]

can upload file, uploaded random file shows it only accept JPEG or PNG  

searchsploit show many vuln  
![[Pasted image 20261105205747.png]]

tried uploading valid file extension shows the software version  
![[Pasted image 20261105210037.png]]

# Exploit
https://github.com/overgrowncarrot1/ImageTragick_CVE-2023-34152

![[Pasted image 20261105214231.png]]

we got a shell  ![[Pasted image 20261105214446.png]]

get the local.txt  
![[Pasted image 20261105214552.png]]


# Priv Esc

check suid  
![[Pasted image 20261105214708.png]]

gtfobins
![[Pasted image 20261105214737.png]]

![[Pasted image 20261105214728.png]]

get proof.txt  

the shell kinda dumb can't even hit backspace  
![[Pasted image 20261105214835.png]]

nevermind, I will just type carefully  
leave this part for later  
![[Pasted image 20261105215219.png]]
