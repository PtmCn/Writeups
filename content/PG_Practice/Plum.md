---
Status: Done
OS: Linux
Difficulty: Medium
tags:
  - admin
  - search
Date: 2026-11-08T01:22:00
Owned: 2026-11-09T03:18:00
---

---
# Enumeration
## port scan

rustscan  
![[Pasted image 20261108012050.png]]

## port 80

webpage  
![[Pasted image 20261108012118.png]]

search with searchsploit  
![[Pasted image 20261108012507.png]]

not sure which version is running  

## Dir enum 
feroxbuster result  
![[Pasted image 20261108012838.png]]

the latest version show on changelog is 5.8.7  
![[Pasted image 20261108012741.png]]

# Foothold
found admin path  
`/core/admin`  
![[Pasted image 20261108013052.png]]

try loggin in with `admin:admin` for the hundred times, it works  
![[Pasted image 20261108013213.png]]

tried to upload revshell.php using the Media tab, failed  

there is static pages tab  
![[Pasted image 20261109025856.png]]

we can edit the page  
replace the content with revshell  
![[Pasted image 20261109030414.png]]

got the shell  
![[Pasted image 20261109030429.png]]

get the local flag  
![[Pasted image 20261109030455.png]]

# Priv Esc

look around from our shell we found credential in `/var/mail/www-data`  
![[Pasted image 20261109031549.png]]

`root:6s8kaZZNaZZYBMfh2YEW`  

let's try switch user with su  
![[Pasted image 20261109031653.png]]

done  
![[Pasted image 20261109031731.png]]


