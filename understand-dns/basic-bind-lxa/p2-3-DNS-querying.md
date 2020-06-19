# DNS 

## DNS querying


### Introduction

Name service queries are essential in retrieving information stored in DNS records. 
We will be using the tools in the `bind-utils` package to perform these requests. 
In this hands-on lab, we will perform name service queries using the nslookup, host, and dig commands.

## The Scenario
The DNS team at ABC Company has just rolled out a new DNS system.
Part of this process was implementing three new caching name servers
or the satellite offices outside of their main campus. 
The Technical Lead for Office XYZ has asked us to perform name service queries,
to ensure new records are being returned to the offsite offices.
He has also asked us to take this opportunity to train another staff member on name service query utilities.

To complete this lab, we must install the `bind-utils` package, then verify that queries resolve successfully using the nslookup, host, and dig commands.

## Logging In
Use the credentials provided on the hands-on lab overview page, and log in as cloud_user with SSH. Once you're in, get root privileges with sudo -i.


## Install packages
Install the bind and bind-utils Packages 
with yum, Then Start and Enable the named Service
This will install what we need:

````shell script
yum install -y bind bind-utils
# Now let's start up the daemon:
systemctl start named
#Finally, we'll enable it to start up after the server reboots:
systemctl enable named
````


Note: exact same as [dns cache section](p1-1-dns-cache.md).
(no need to go through VM)

In LXA they start and enable named it is not needed actually here! as we are not using the cache as  in [dns cache section](p1-1-dns-cache.md).
In [forward](p2-1-summary-configure-forward-zone.md) and [reverse](p2-2-summary-configure-reverse-zone.md) zone lab, this setup was pre-configured.

Note operations are (I reordered and added when missing): 
- Resolve the IP for google.com
- List the name servers for google.com / Display the name servers for the google.com domain
- Resolve the IP address for ns4.google.com
- Display the mail servers for google.com

## Use the host Command

### ADD: Resolve the IP for google.com


````shell 
host -t a google.com
host -t aaaa google.com
````

Output is 

````shell script
[root@server1 cloud_user]# host -t a google.com
google.com has address 172.217.15.110
[root@server1 cloud_user]# host -t aaaa google.com
google.com has IPv6 address 2607:f8b0:4004:814::200e
````

### Display the name servers for the google.com domain:

````shell 
host -t ns google.com
````

Output is 

````shell script
[root@server1 cloud_user]# host -t ns google.com
google.com name server ns3.google.com.
google.com name server ns4.google.com.
google.com name server ns1.google.com.
google.com name server ns2.google.com.
````


### ADD: Resolve the IP address for ns4.google.com


````shell 
host -t a ns4.google.com
host -t aaaa ns4.google.com
````

Output is 

````shell script
[root@server1 cloud_user]# host -t a ns4.google.com
ns4.google.com has address 216.239.38.10
[root@server1 cloud_user]# host -t aaaa ns4.google.com
ns4.google.com has IPv6 address 2001:4860:4802:38::a
````

### Display the mail servers for google.com:

````shell
host -t mx google.com
````

Output is 


````shell script
[root@server1 cloud_user]# host -t mx google.com
google.com mail is handled by 30 alt2.aspmx.l.google.com.
google.com mail is handled by 40 alt3.aspmx.l.google.com.
google.com mail is handled by 50 alt4.aspmx.l.google.com.
google.com mail is handled by 10 aspmx.l.google.com.
google.com mail is handled by 20 alt1.aspmx.l.google.com.
````


## Run the nslookup Command

### Resolve the IP for google.com

````
nslookup google.com
````

Output is 

````shell script
[root@server1 cloud_user]# nslookup google.com
Server:         10.0.0.2
Address:        10.0.0.2#53

Non-authoritative answer:
Name:   google.com
Address: 172.217.164.174
Name:   google.com
Address: 2607:f8b0:4004:814::200e
````

We can use `-type A`, `man nslookup` say default is A, but it will not return AAAA.

````shell script
[root@server1 cloud_user]# nslookup -type=A google.com
Server:         10.0.0.2
Address:        10.0.0.2#53

Non-authoritative answer:
Name:   google.com
Address: 172.217.15.78

[root@server1 cloud_user]# nslookup -type=AAAA google.com
Server:         10.0.0.2
Address:        10.0.0.2#53

Non-authoritative answer:
Name:   google.com
Address: 2607:f8b0:4004:814::200e
````

### List the name servers for google.com:

````
nslookup -type=ns google.com
````

Output is 

````shell script
[root@server1 cloud_user]# nslookup ns4.google.com
Server:         10.0.0.2
Address:        10.0.0.2#53

Non-authoritative answer:
Name:   ns4.google.com
Address: 216.239.38.10
Name:   ns4.google.com
Address: 2001:4860:4802:38::a

[root@server1 cloud_user]# nslookup -type=ns google.com
Server:         10.0.0.2
Address:        10.0.0.2#53

Non-authoritative answer:
google.com      nameserver = ns3.google.com.
google.com      nameserver = ns4.google.com.
google.com      nameserver = ns1.google.com.
google.com      nameserver = ns2.google.com.

Authoritative answers can be found from:
````

### Resolve the IP address for ns4.google.com:

````
nslookup ns4.google.com
````

output is 

````shell script
[root@server1 cloud_user]# nslookup ns4.google.com
Server:         10.0.0.2
Address:        10.0.0.2#53

Non-authoritative answer:
Name:   ns4.google.com
Address: 216.239.38.10
Name:   ns4.google.com
Address: 2001:4860:4802:38::a
````


### List the mail servers responsible for mail exchange for google.com:

````shell script
nslookup -query=mx google.com
````

Output is

````shell script
[root@server1 cloud_user]# nslookup -query=mx google.com
Server:         10.0.0.2
Address:        10.0.0.2#53

Non-authoritative answer:
google.com      mail exchanger = 20 alt1.aspmx.l.google.com.
google.com      mail exchanger = 30 alt2.aspmx.l.google.com.
google.com      mail exchanger = 40 alt3.aspmx.l.google.com.
google.com      mail exchanger = 50 alt4.aspmx.l.google.com.
google.com      mail exchanger = 10 aspmx.l.google.com.

Authoritative answers can be found from:
````

Same was done here in [part 2 questions](p2-1-xx-questions.md#Note-the-nslookup-which-is-particular)

Note corresponding A,AAAA records:

````shell script
[root@server1 cloud_user]# nslookup alt1.aspmx.l.google.com          
Server:         10.0.0.2                                             
Address:        10.0.0.2#53                                          
                                                                     
Non-authoritative answer:                                            
Name:   alt1.aspmx.l.google.com                                      
Address: 209.85.202.26                                               
Name:   alt1.aspmx.l.google.com                                      
Address: 2a00:1450:400b:c00::1a                                      

````

#### Use the debug mode for nslookup to provide more details about google.com:

````shell script
nslookup -debug google.com
````

Output is 

````shell script
[root@server1 cloud_user]# nslookup -debug google.com
Server:         10.0.0.2
Address:        10.0.0.2#53

------------
    QUESTIONS:
        google.com, type = A, class = IN
    ANSWERS:
    ->  google.com
        internet address = 172.217.7.142
        ttl = 117
    AUTHORITY RECORDS:
    ADDITIONAL RECORDS:
------------
Non-authoritative answer:
Name:   google.com
Address: 172.217.7.142
------------
    QUESTIONS:
        google.com, type = AAAA, class = IN
    ANSWERS:
    ->  google.com
        has AAAA address 2607:f8b0:4004:c08::71
        ttl = 136
    AUTHORITY RECORDS:
    ADDITIONAL RECORDS:
------------
Name:   google.com
Address: 2607:f8b0:4004:c08::71

````


## Using the dig Command

### Resolve the IP for google.com:

````
dig google.com
````

Output is 

````shell script
[root@server1 cloud_user]# dig google.com

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-16.P2.el7_8.6 <<>> google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62299
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             69      IN      A       172.217.7.142

;; Query time: 0 msec
;; SERVER: 10.0.0.2#53(10.0.0.2)
;; WHEN: Wed Jun 17 10:22:15 UTC 2020
;; MSG SIZE  rcvd: 55

````

### List the name servers for google.com:

````shell script
dig ns google.com
````

Output is 

````shell script
[root@server1 cloud_user]# dig ns google.com

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-16.P2.el7_8.6 <<>> ns google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 26556
;; flags: qr rd ra; QUERY: 1, ANSWER: 4, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;google.com.                    IN      NS

;; ANSWER SECTION:
google.com.             300     IN      NS      ns3.google.com.
google.com.             300     IN      NS      ns4.google.com.
google.com.             300     IN      NS      ns1.google.com.
google.com.             300     IN      NS      ns2.google.com.

;; Query time: 1 msec
;; SERVER: 10.0.0.2#53(10.0.0.2)
;; WHEN: Wed Jun 17 10:23:13 UTC 2020
;; MSG SIZE  rcvd: 111
````

List only the four NS records for google.com:

````
dig ns google.com +noall +answer
````

Output is

````shell script
[root@server1 cloud_user]# dig ns google.com +noall +answer

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-16.P2.el7_8.6 <<>> ns google.com +noall +answer
;; global options: +cmd
google.com.             251     IN      NS      ns1.google.com.
google.com.             251     IN      NS      ns2.google.com.
google.com.             251     IN      NS      ns3.google.com.
google.com.             251     IN      NS      ns4.google.com.
[root@server1 cloud_user]#

````

Note for all this operation made on LXA server, we had

````shell script
[root@server1 cloud_user]# cat /etc/resolv.conf
# Generated by NetworkManager
search ec2.internal
nameserver 10.0.0.2
````

### ADD: Resolve the IP address for ns4.google.com


````shell script
dig ns4.google.com
````

Output is 

````shell script
[root@server1 cloud_user]# dig ns4.google.com

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-16.P2.el7_8.6 <<>> ns4.google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 31969
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;ns4.google.com.                        IN      A

;; ANSWER SECTION:
ns4.google.com.         18      IN      A       216.239.38.10

;; Query time: 0 msec
;; SERVER: 10.0.0.2#53(10.0.0.2)
;; WHEN: Wed Jun 17 11:36:52 UTC 2020
;; MSG SIZE  rcvd: 59
````




### ADD: Display the mail servers for google.com

Usage:

````shell script
[root@server1 cloud_user]# dig -h | grep type
Usage:  dig [@global-server] [domain] [q-type] [q-class] {q-opt}
        q-type   is one of (a,any,mx,ns,soa,hinfo,axfr,txt,...) [default:a]
                 (Use ixfr=version for type ixfr)
                 -t type             (specify query type)
clear
````

Applied:

````shell script
dig -t mx google.com
````

Output is 

````shell script
[root@server1 cloud_user]# dig -t mx google.com

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-16.P2.el7_8.6 <<>> -t mx google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 57564
;; flags: qr rd ra; QUERY: 1, ANSWER: 5, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;google.com.                    IN      MX

;; ANSWER SECTION:
google.com.             259     IN      MX      30 alt2.aspmx.l.google.com.
google.com.             259     IN      MX      40 alt3.aspmx.l.google.com.
google.com.             259     IN      MX      50 alt4.aspmx.l.google.com.
google.com.             259     IN      MX      10 aspmx.l.google.com.
google.com.             259     IN      MX      20 alt1.aspmx.l.google.com.

;; Query time: 0 msec
;; SERVER: 10.0.0.2#53(10.0.0.2)
;; WHEN: Wed Jun 17 11:39:36 UTC 2020
;; MSG SIZE  rcvd: 147

````



## ADD: Using Windows

I will use windows machine here (as I could have used my linux VM for operation)
They have a nslookup which is working as linux version.

But they also have powershell!


### Resolve the IP for google.com

````shell 
Resolve-DnsName -Name google.fr -Server 8.8.8.8
````

Output is 

````shell script
> Resolve-DnsName -Name google.fr -Server 8.8.8.8

Name                                           Type   TTL   Section    IPAddress                                
----                                           ----   ---   -------    ---------                                
google.fr                                      AAAA   299   Answer     2a00:1450:4007:817::2003                 
google.fr                                      A      299   Answer     216.58.206.22
````



### List the name servers for google.com


````shell
Resolve-DnsName -Name google.com -Type ns -Server 8.8.8.8
````

Output is 


````shell script
> Resolve-DnsName -Name google.com -Type ns -Server 8.8.8.8

Name                           Type   TTL   Section    NameHost                                                                                        
----                           ----   ---   -------    --------                                                                                        
google.com                     NS     21599 Answer     ns3.google.com                                                                                  
google.com                     NS     21599 Answer     ns4.google.com                                                                                  
google.com                     NS     21599 Answer     ns2.google.com                                                                                  
google.com                     NS     21599 Answer     ns1.google.com                                                                                  

````

### Resolve the IP address for ns4.google.com


````shell
Resolve-DnsName -Name ns4.google.com  -Server 8.8.8.8
````

Output is 


````shell script
> Resolve-DnsName -Name ns4.google.com  -Server 8.8.8.8

Name                                           Type   TTL   Section    IPAddress                                
----                                           ----   ---   -------    ---------                                
ns4.google.com                                 AAAA   21599 Answer     2001:4860:4802:38::a                     
ns4.google.com                                 A      18565 Answer     216.239.38.10                            
````

and

````shell script
> Resolve-DnsName -Name ns4.google.com  -type A -Server 8.8.8.8

Name                                           Type   TTL   Section    IPAddress                                
----                                           ----   ---   -------    ---------                                
ns4.google.com                                 A      18488 Answer     216.239.38.10
````

### Display the mail servers for google.com:

````shell
Resolve-DnsName -Name google.com -Type mx -Server 8.8.8.8
````

Output is 


````shell script
> Resolve-DnsName -Name google.com -Type mx -Server 8.8.8.8

Name                                     Type   TTL   Section    NameExchange                              Preference                               
----                                     ----   ---   -------    ------------                              ----------                               
google.com                               MX     228   Answer     alt1.aspmx.l.google.com                   20                                       
google.com                               MX     228   Answer     alt3.aspmx.l.google.com                   40                                       
google.com                               MX     228   Answer     alt4.aspmx.l.google.com                   50                                       
google.com                               MX     228   Answer     aspmx.l.google.com                        10                                       
google.com                               MX     228   Answer     alt2.aspmx.l.google.com                   30                                       

````

## Conclusion

We've used a few different tools for querying DNS servers.
We have a mapping across the different ways.
