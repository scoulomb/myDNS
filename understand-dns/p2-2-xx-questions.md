# DNS 

## Questions on reverse zone

### MX records on reverse zone warning

Details on MX record given in this reverse zone [question](./p2-1-xx-questions.md#What-happens-if-I-do-not-define-a-A-record-matching-a-MX-record?).
In the lab we have same warning for reverse zone.
If we remove those MX, disappear? 
Yes warning disappear (same as in forward zone, in all case we have an output, checked)

### Does it makes sense to define a MX record in a reverse zone


For me it is a non sense !

#### Question on LXA


From:  https://linuxacademy.com/community/posts/show/topic/49680-dns-reverse-zone-lab

<details>
<summary>Details...</summary>
<p>


##### Question

Does it make sense to have a MX record in the reverse  zone?

Because it is present in the lab answer for reverse zone.

````shell script
TTL    86400
@       IN      SOA     nameserver.mylabserver.com. root.mylabserver.com. (
                          10030         ; Serial
                           3600         ; Refresh
                           1800         ; Retry
                         604800         ; Expiry
                          86400         ; Minimum TTL
 )
; Name Server
@        IN      NS       nameserver.mylabserver.com.
; PTR Record Definitions
; aaa       IN      PTR       nameserver.mylabserver.com.
; bbb       IN      PTR       mailprod.mylabserver.com.
; ccc       IN      PTR       mailbackup.mylabserver.com.
240         IN      PTR       nameserver.mylabserver.com.
; which is last octet of my IP
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
````

Similarly I  try to add a A record in reverse but it is not relevant because a  look up would be possible by doing:


`nslookup <dns-name>.1.0.10.in-addr.arpa localhost`


(ns lookup <dns-name>.mylabserver.com would not work, or if it is, it is a non authoritative answer, DNS recursion  )

I understand from https://en.wikipedia.org/wiki/MX_record that defining a MX record, requires a A record (thus the warning which is also mentioned in the solution), and would be fine in forward zone.

As a consequence we can do  a reverse lookup of MX with a PTR.
Thus IMO adding a MX records in reverse zone makes not sense, how we would retrieve this MX otherwise?

What did I miss?

Thx

##### Answer


MX records are known as service records that correspond to a host record.
Only host records are typically resolved via reverse DNS lookup.
MX (and all other service records) are only necessary in regular forward-lookup zones.


</p>
</details>



#### Question on Serverfault


From:  https://serverfault.com/questions/1021169/mx-record-in-a-reverse-zone

<details>
<summary>Details...</summary>
<p>


##### Question

I am taking a DNS course on Linux Academy.
In one of the lab, they define a reverse zone. In this zone they add MXs records.
Does it make sense to have MX record defined in a reverse zone?

**Details:**

For this they do

````
vim /etc/named.conf

zone "1.0.10.in-addr.arpa" {
    type master;
    file "/var/named/1.0.10.db";
};
````

And content of `/var/named/1.0.10.db` is:

````
TTL    86400
@       IN      SOA     nameserver.myserver.com. root.myserver.com. (
                          10030         ; Serial
                           3600         ; Refresh
                           1800         ; Retry
                         604800         ; Expiry
                          86400         ; Minimum TTL
 )
; Name Server
@        IN      NS       nameserver.myserver.com.
; PTR Record Definitions
240         IN      PTR       nameserver.myserver.com.
241         IN      PTR       mailprod.myserver.com.
242         IN      PTR       mailbackup.myserver.com.
; which is last octet of my IP
; Mail Exchange Records
@        IN    MX    10    mailprod.myserver.com.
@        IN    MX    20    mailbackup.myserver.com.
````


Similarly I  try to add a A record in reverse but it is not relevant because a  look up would be possible by doing:

````
nslookup <dns-name>.1.0.10.in-addr.arpa localhost
````

Doing

````
ns lookup <dns-name>.mylabserver.com localhost
````


would not work, (or if it is, it is a non authoritative answer, DNS recursion  ).
Am I correct?


I understand from  https://en.wikipedia.org/wiki/MX_record that defining a MX record, requires a A record.
As a consequence we can do  a reverse lookup of MX with a PTR?

Thus I am wondering if adding a MX records in reverse zone makes sense, how we would retrieve this MX then?

What did I miss?
   


##### Answer

It would only make sense if you want to receive mail addressed to eg `scoulomb@1.0.10.in-addr.arpa` (which seems more than a little unusual).
`dig 1.0.10.in-addr.arpa MX` should work for retrieving the `MX` record (given the zone in the question).
I would guess that this might rather be a case of them using the same template for every zone, or something along those lines. It's certainly not the typical thing to do in a reverse zone.


</p>
</details>


#### Wrap up 

it does not make sense

I will run [reverse zone summary](./p2-2-configure-reverse-zone-summary.md).

Then I keep MX and add a host record:

```shell script
cat << EOF >  /var/named/${REVERSE_ZONE}.db
\$TTL    86400
@       IN      SOA     nameserver.mylabserver.com. root.mylabserver.com. (
                          10030         ; Serial
                           3600         ; Refresh
                           1800         ; Retry
                         604800         ; Expiry
                          86400         ; Minimum TTL
 )
; Name Server
@        IN      NS       nameserver.mylabserver.com.
; PTR Record Definitions
; aaa       IN      PTR       nameserver.mylabserver.com.
; bbb       IN      PTR       mailprod.mylabserver.com.
; ccc       IN      PTR       mailbackup.mylabserver.com.
${HOST_PRIVATE_IP_ARRAY[3]} IN      PTR       nameserver.mylabserver.com.
; which is last octet of my IP
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.

nameserver  IN      A       172.31.18.93

EOF

cat  /var/named/${REVERSE_ZONE}.db
named-checkzone ${REVERSE_ZONE}.db.in-addr.arpa /var/named/${REVERSE_ZONE}.db 


systemctl restart named
```



Now I will try to retrieve this record 

For A record:

````shell script
[root@server1 cloud_user]# nslookup nameserver.mylabserver.com. localhost
Server:         localhost
Address:        ::1#53

** server can't find nameserver.mylabserver.com.: NXDOMAIN
````

Given that we have:

```shell script
[root@server1 cloud_user]# cat /etc/named.conf | grep arpa
zone "1.0.10.in-addr.arpa" {  type master;  file "/var/named/1.0.10.db";};
```

I will do 

````shell script

nslookup nameserver.1.0.10.in-addr.arpa localhost
````

Where output is 


````shell script

[root@server1 cloud_user]# nslookup nameserver.1.0.10.in-addr.arpa localhost
Server:         localhost
Address:        ::1#53

Name:   nameserver.1.0.10.in-addr.arpa
Address: 172.31.18.93
````

For MX records.
From [forward zone question](./p2-1-xx-questions.md#Note-the-nslookup-which-is-particular)

```shell script
[root@server1 cloud_user]# nslookup -type=mx mylabserver.com localhost
Server:         localhost
Address:        ::1#53

Non-authoritative answer:
*** Can't find mylabserver.com: No answer

```

Similarly as A record retrieve is

````shell script
nslookup -type=mx  1.0.10.in-addr.arpa localhost
````

It confirms usage of the zone in the named.

Output is 

````shell script
[root@server1 cloud_user]# nslookup -type=mx  1.0.10.in-addr.arpa localhost
Server:         localhost
Address:        ::1#53

1.0.10.in-addr.arpa     mail exchanger = 10 mailprod.mylabserver.com.
1.0.10.in-addr.arpa     mail exchanger = 20 mailbackup.mylabserver.com.
````

It would mean we have address like `scoulomb@1.0.10.in-addr.arpa`.

### Reverse look up of MX

See [question](./p2-1-xx-questions.md#What-happens-if-I-do-not-define-a-A-record-matching-a-MX-record?).
Given that we usually have a A record matching a MX record. We will do the reverse look with the help of the PTR record matching the A record.  
(see comment in servfault question, and reply in lxa)

### Can I remove entry with same name as the zone

As in [forward zone question](./p2-1-xx-questions.md#Can-I-remove-entry-with-same-name-as-the-zone)

<details>
<summary>Details...</summary>
<p>

````
cat << EOF >  /var/named/1.0.10.db
\$TTL    86400
@       IN      SOA     nameserver.mylabserver.com. root.mylabserver.com. (
                          10030         ; Serial
                           3600         ; Refresh
                           1800         ; Retry
                         604800         ; Expiry
                          86400         ; Minimum TTL
 )
; Name Server
@        IN      NS       nameserver.mylabserver.com.
; PTR Record Definitions
123         IN      PTR       nameserver2.mylabserver.com.
; which is last octet of my IP
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

named-checkzone 1.0.10.in-addr.arpa /var/named/1.0.10.db
````

Output is 

````shell script
[root@server1 cloud_user]# named-checkzone 1.0.10.in-addr.arpa /var/named/1.0.10.db
zone 1.0.10.in-addr.arpa/IN: 1.0.10.in-addr.arpa/MX 'mailprod.mylabserver.com' (out of zone) has no addresses records (A or AAAA)
zone 1.0.10.in-addr.arpa/IN: 1.0.10.in-addr.arpa/MX 'mailbackup.mylabserver.com' (out of zone) has no addresses records (A or AAAA)
zone 1.0.10.in-addr.arpa/IN: loaded serial 10030
OK
````

</p>
</details>

Yes it is possible unlike forward zone test.

LAB COMPLETE