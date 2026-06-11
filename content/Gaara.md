---
type: Lab-Machine
Status: 🟢
OS: Linux
Difficulty: Easy
IP: 192.168.174.142
Date: 2026-06-01T14:18:00
Owned:
---

# 🖥️ Machine: [[Gaara]]
**List Source:** #Lainkusanagi | #TJnull 
**Target IP:** 

---
# Enumeration
## port scan
![[Pasted image 20260601142307.png]]

## dir enum
![[Pasted image 20260601142713.png]]
another wordlist
![[Pasted image 20260601150104.png]]
found Cryoserver

# Exploit

error page show server version
![[Pasted image 20260601142749.png]]
let's try some exploit
![[Pasted image 20260601142818.png]]

from the script add target to targets.txt

![[Pasted image 20260601143855.png]]
we got user list /nologin cant be use
we can spray for user
list
sync
root
spray using brutus
```
brutus --target 192.168.174.142:22 --protocol ssh -U users.txt -P /usr/share/wordlists/fasttrack.txt -v
```

since the lab name is Gaara I'm creating the shorter version of password list
```
grep "naruto" /usr/share/wordlists/rockyou.txt >> passwords.txt
grep "ninja" /usr/share/wordlists/rockyou.txt >> passwords.txt
grep "konoha" /usr/share/wordlists/rockyou.txt >> passwords.txt
```
ended up with 1796 words

while waiting for bruteforce 
with the second attempt of dir enum
we found the page
![[Pasted image 20260601150215.png]]
with path let's checkout
```
/Temari
/Kazekage
/iamGaara
```
/Temari
![[Pasted image 20260601150304.png]]
nothing interesting
the remaining 2 path look the same too
let's use that as user to bruteforce
start with just iamGaara
```
hydra -l iamGaara -P passwords.txt ssh://192.168.174.142 -t 4 -v -I -t 1
```

no luck
tooking too long opening write up there is some weird text /iamGaara
![[Pasted image 20260601153105.png]]
f1MgN9mTf9SNbzRygcU

I try to get the diff without scanning manually, curl all path
```
curl http://ip/iamGaara
...
...
```
notice there is difference in file size of iamGaara from others
![[Pasted image 20260601154001.png]]compare
```
diff file1.txt file2.txt
```
doesn't help much bruh

let's try connect with iamGaara:f1MgN9mTf9SNbzRygcU
```
ssh iamGaara@192.168.174.142
```

i think it's encoded try base64 didn't work
looking at writeup shows it base58 bruh
![[Pasted image 20260601154208.png]]
next time need to use [ciper identifier](https://www.dcode.fr/cipher-identifier)

![[Pasted image 20260601154307.png]]

let's ssh using gaara:ismyname
turn out it was fucking rabbithole we just need to stick with rockyou
![[Pasted image 20260601154840.png]]
waste too much time meh
![[Pasted image 20260601154928.png]]

# Post-Exploit

![[Pasted image 20260601155233.png]]

gdb
![[Pasted image 20260601155604.png]]

this one work
![[Pasted image 20260601155943.png]]
![[Pasted image 20260601160027.png]]

![[Pasted image 20260601160049.png]]
too many rabbit holes bruhh