---
title: "THM:crackthehash"
subtitle: "TryHackMe room: https://tryhackme.com/room/crackthehash"
category: "Cracking"
tags: cracking,hashcat,hash-identifier,crackstation
---
# THM:Crack the hash

URL: [https://tryhackme.com/room/crackthehash](https://tryhackme.com/room/crackthehash) [Easy]

Tags: 
<div style="margin-left: 5px;">
{% assign tags = page.tags | split: "," %}
{% for tag in tags %}
<a href="../search/?q={{tag}}" title="Click to search by this tag"><span class="badge bg-secondary">{{tag}}</span></a>
{% endfor %}
</div>
<hr>

## Reconnaissance

This is not a Capture The Flag. It's a room that has several hashes to be cracked. Description of the room:

> Cracking hashes challenges

## Level 1

One of the first things needed is to identify what potential hash algorithms are used, based on the format of the hash. Some ways to do that is check:

- https://hashcat.net/wiki/doku.php?id=example_hashes
- https://www.tunnelsup.com/hash-analyzer/

Also from the terminal, you can use `hash-identifier`. For example:

> ```bash
> hash-identifier CBFDAC6008F9CAB4083784CBD1874F76618D2A97
> ```

Next, if these are hashes of known values with no salt applied, they might be easily crackable with [rainbow tables](https://duckduckgo.com/?q=rainbow+tables). For some, you can use an online resource, or you can crack them locally.

### Cracking Online

For example, you might try the various hashes on a site like:

- **https://crackstation.net/**
- **https://www.onlinehashcrack.com/**

Below is a summary of the hashes and their algorithm.

| Hash                                                              | Algorithm     |
|-------------------------------------------------------------------|---------------|
|`48bb6e862e54f2a795ffc4e541caed4d`                                 |md5            |
|`CBFDAC6008F9CAB4083784CBD1874F76618D2A97`                         |SHA1           |
|`1C8BFE8F801D79745C4631D09FFF36C82AA37FC4CCE4FC946683D7B336B63032` |SHA256         |
|`$2y$12$Dwt1BZj6pcyc3Dy1FWZ5ieeUznr71EeNkJkUlypTsgbX1H68wsRom`     |Bcrypt-Blowfish|
|`279412f945939ba78ce0758d3fd83daa`                                 |md4            |

### Cracking Locally

Another way to attempt to crack these hashes is with `hashcat`. You could put your hashes into a file called [`hashes_l1.txt`](hashes_l1.txt) for example, and then run something like this:

> ```bash
> hashcat -m 0 hashes_l1.txt /usr/share/wordlists/rockyou.txt  
> ```

Note that the `-m 0` is the hash "code" from the HashCat website: https://hashcat.net/wiki/doku.php?id=example_hashes - So `0` is the code for MD5 for example.

### Special Case

Of the hashes above the one that starts with `$2y$12$...` is an unusual one. From the THM hint, we see:

> *Search the hashcat examples page (https://hashcat.net/wiki/doku.php?id=example_hashes) for $2y$. This type of hash can take a very long time to crack, so either filter rockyou for four character words, or use a mask for four lower case alphabetical characters.*

When I tried to run `hashcat` against on my laptop (*Intel i7 7th Gen, no GPU*), it says it will take 11+ days to complete!

```python
Time.Estimated...: Mon Feb 21 14:23:25 2022 (11 days, 18 hours)
```

So, per the hint, let's pull just the first 4 letters from RockYou and create a new wordlist:

> ```bash
> cut -c-4 /usr/share/wordlists/rockyou.txt > ./rock4.txt
> ```

But then, this is going to have some duplicates and trash. We can at least get rid of the duplicates by calling `sort` and having it just include the unique (`-u`) lines, and the hint told us it's all lower case. So, we can convert everything to lowercase, then just pull out the unique values:

> ```bash
> tr A-Z a-z < ./rock4.txt | sort -u > rock4.sorted.txt 
> ```

The `tr` replaces uppercase for lowercase from the shortened `rock4.txt`, then pipes that to `sort` which will pull out the unique values, and output itself to `rock4.sorted.txt`.

This dramatically reduces the size of our wordlist:

| File                | Size              |
| ------------------- | -----------------:|
| `rockyou.txt`       | 139,921,507 bytes |
| `rock4.txt`         | 71,718,690 bytes  |
| `rock4.sorted.txt`  | 3,770,791 bytes   |

So we went from 139MB, to 71MB, to 3MB. However, when we re-run `hashcat`:

> ```bash
> hashcat -m 3200 hashes.txt rock4.sorted.txt
> ```

On my non-GPU laptop, that improved the time, but not to a reasonable level:

```python
Time.Estimated...: Thu Feb 10 12:39:59 2022 (14 hours, 55 mins)
```

My guess is this would run dramatically faster on a desktop machine with a GPU.

## Level 2

Below are the algorithms used for each hash. Note that these can't be broken online, you'll need to use `hashcat` for these.

| Hash                                                                | Algorithm     |
|---------------------------------------------------------------------|---------------|
|`F09EDCB1FCEFC6DFB23DC3505A882655FF77375ED8AA2D1C13F640FCCC2D0C85`   | SHA2-256      |
|`1DFECA0C002AE40B8619ECF94819CC1B`                                   | NTLM          |
|`$6$aReallyHardSalt$6WKUTqzq.UQQmrm0p/T7MPpMbGNnzXPMAXi4bJMl9be.cfi3/qxIf.hsGpS41BqMhSrHVXgMpdjS6xeKZAs02.` | sha512crypt $6$, SHA512 (Unix)  |
|`e5d8870e5bdd26602cab8dbe07a942c8669e56d6`                           | HMAC-SHA1     |

> ### **NOTE:**
> For the last one on Level 2, `hashcat` expects the hash to be `hash:salt` type format.

## Summary

Completed: [2022-02-09 22:27:21]