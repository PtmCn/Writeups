---
Status: In progress
OS: Linux
Difficulty: Easy
tags:
  - drupal
  - SUID
Date: 2026-06-20T17:04:00
Owned:
---

---
# IP address: 192.168.122.193
![[Pasted image 20260620170235.png]]
# Enumeration
## port scan

I'm trying out rustscan for the first time :D
```sh
rustscan -a 192.168.122.193 | tee rust.txt
```
![[Pasted image 20260620214526.png]]  
want to get more detail so I scanned the port found with Nmap -sV  
```sh
grc nmap -Pn -p22,80,111,50881 -sV 192.168.122.193 -v
```
Nmap result  
Look like port 50881 is also RPC
![[Pasted image 20260620221042.png]]  

we have http on port 80  
![[Pasted image 20260620220037.png]]
as we can see it is using Drupal cms  
wappalyzer shows it Drupal 7
![[Pasted image 20260620221457.png]]

tried checking port 50881 for website and don't find any  

also checked udp  
```sh
rustscan --udp --ulimit 5000 -a 192.168.122.193 | tee rustudp.txt
```
![[Pasted image 20260620214825.png]]
nothing interesting for udp  

## dir enum

run feroxbuster  
```sh
feroxbuster -u http://192.168.122.193/ -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt -o ferox80.txt
```
took so long so I ctrl+c it  
![[Pasted image 20260620221323.png]]  


# Exploit

Since we know it's running Drupal 7 let's find some exploit using searchsploit  
```
searchsploit drupal 7
```
![[Pasted image 20260620221556.png]]
the exploit that add admin user is interesting  
but there is RCE let's get that  
```
searchsploit -m 35150
```
turn out it is .php file  

I think the feroxbuster broke the site lol  
![[Pasted image 20260620221940.png]]
yes it is revert the lab and it's back  

I tried to use the exploit 44449 which is ruby and couldn't run it.  

Imma run drupalscan

```
sudo gem install DrupalScan
```
let's run, useless bruh can't even run  

https://github.com/immunIT/drupwn

bruh everything is so old with drupal  
found another scanner named droopescan hope this one works  
couldn't install it either tried both pipx and setup venv  

checking out the writeup turnout they use metasploit  
![[Pasted image 20260620225736.png]]
set the options  
![[Pasted image 20260620225800.png]]
ran the exploit and got the shell  
![[Pasted image 20260620225823.png]]
get shell by typing `shell`  
![[Pasted image 20260620230234.png]]
got the local flag  
# Privilege Escalation
check SUID
```sh
find / -perm -u=s -type f 2>/dev/null
```
![[Pasted image 20260620230406.png]]
there is /bin/mount 
GTFObins as always
![[Pasted image 20260620231210.png]]
![[Pasted image 20260620231508.png]]
got this error with illegal option -p
found there is file read SUID
![[Pasted image 20260620231539.png]]

```
/usr/bin/find /root/proof.txt -exec cat {} \;
```
guess the path  
![[Pasted image 20260620231601.png]]
got the flag !!  
