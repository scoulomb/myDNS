# DNS

## Note on recursive DNS and authoritative DNS 

https://umbrella.cisco.com/blog/difference-authoritative-recursive-dns-nameservers

Same dns server can be a recursive and authoritative.
For instance local is authoritative for the domain we defined in the forward zone file.
If we target directly this dns in resolv or  it is specified in arg in nslookup, 
no recursion is performed as the dns is also the authoritative.
otherwise for a user to get a record in this DNS I would have to register it in top subdomain for other DNS recursive server to find it
https://en.wikipedia.org/wiki/Domain_name_registrar

Btw in the nslookup answer we can see it is authoritative one

```
[root@server1 cloud_user]# nslookup nameserver.mylabserver.com localhost
Server:         localhost
Address:        ::1#53

Name:   nameserver.mylabserver.com
Address: 172.31.18.93


````

Unlike with 

````
[cloud_user@server1 ~]$ nslookup google.fr localhost
;; Got SERVFAIL reply from ::1, trying next server
Server:         localhost
Address:        ::1#53

** server can't find google.fr: NXDOMAIN

[cloud_user@server1 ~]$ nslookup google.fr localhost
Server:         localhost
Address:        ::1#53

Non-authoritative answer:
Name:   google.fr
Address: 142.250.31.94
Name:   google.fr
Address: 2607:f8b0:4004:c0b::5e
````

where we have `Non-authoritative answer`

Similarly (as localhost), a public DNS can be a recursive DNS (as when using localhost) and has authority role  (SOA) for a given domain,
For instance for google domain (same as mylabserver.com)

We can find it   (cf. https://stackoverflow.com/questions/38021/how-do-i-find-the-authoritative-name-server-for-a-domain-name)

````
sylvain@sylvain-hp:~$ nslookup
> set querytype=soa
> google.com
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
google.com
	origin = ns1.google.com
	mail addr = dns-admin.google.com
	serial = 315449991
	refresh = 900
	retry = 900
	expire = 1800
	minimum = 60

Authoritative answers can be found from:

````

(using ISP or 8.8.8.8 DNS example, `nslookup -type=soa google.com 8.8.8.8`)
And we can target it, we have the authoritative answer (no recursion)

````
sylvain@sylvain-hp:~$ nslookup google.com ns1.google.com
Server:		ns1.google.com
Address:	216.239.32.10#53

Name:	google.com
Address: 216.58.204.142
Name:	google.com
Address: 2a00:1450:4007:812::200e

````
Non authoritative is not mentionned






