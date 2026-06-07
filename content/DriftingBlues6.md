---
type: Lab-Machine
Status: 🟢
OS: Linux
Difficulty: Easy
IP:
Date: 2026-06-03T02:17:00
Owned: 2026-06-04T01:14:00
---

# 🖥️ Machine: [[DriftingBlues6]]
**List Source:** #Lainkusanagi | #TJnull 
**Target IP:** `{{value:IP_Address}}`

---
# Enumeration
## port scan
### naabu
![[Pasted image 20260603022318.png]]
port 80
![[Pasted image 20260603021902.png]]


## dir enum
force robots.txt while scanning port
![[Pasted image 20260603022001.png]]
.zip huh
### dirbuster
```sh
dirbuster -u http://192.168.230.219/ -l /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -e zip -H -v
```
idk how to use kinda weird
### feroxbuster
```
feroxbuster -u http://192.168.230.219 -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt -x zip -o ferox.txt
```
add -x zip for extension
![[Pasted image 20260603022920.png]]
check README
ok testpattern is a cms
![[Pasted image 20260603022856.png]]
login page
![[Pasted image 20260603023233.png]]
check for exploit 
![[Pasted image 20260603023338.png]]
from readme we got the cms version
interesting exploit is RCE but need authentication

don't find any .zip with 200 code
![[Pasted image 20260603023551.png]]

### ferox2
```
feroxbuster -u http://192.168.230.219 -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt -x zip -o ferox.txt
```
this time we got file
![[Pasted image 20260603023843.png]]
turn out there is cred.txt but needed password to unzip
![[Pasted image 20260603023933.png]]
trying bruteforce tool
![[Pasted image 20260603025134.png]]
found some article about cracking old zip
```
zip2john spammer.zip > hash.txt
john hash.txt
```
done
myspace4
![[Pasted image 20260603034335.png]]
open creds.txt
mayer:lionheart

# Exploit
after login
go to files upload revshell
# Priv escalation
![[Pasted image 20260603032143.png]]

check os![[Pasted image 20260603032618.png]]
then ran linuxExploitSuggester.sh
![[Pasted image 20260603033628.png]]
compilation problem
![[Pasted image 20260603034155.png]]

to upgrade shell for qol
```
python -c 'import pty; pty.spawn("/bin/bash")'
```

let' try linpeas.sh
![[Pasted image 20260604005250.png]]
many CVEs, some i've tried but have problem compiling the code
https://github.com/firefart/dirtycow
got this error
![[Pasted image 20260604010249.png]]

bruh 
I can just sent dirty.c to target and compile on target lol
![[Pasted image 20260604011139.png]]
run the exploit with new password 'password123'
![[Pasted image 20260604011013.png]]

after running the shell froze
reconnect and switch to user toor with root priv
![[Pasted image 20260604011105.png]]


![[Pasted image 20260604011255.png]]
