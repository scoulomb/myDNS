# DNS

Run script in [summary](p2-1-summary-configure-forward-zone.md)

## ADD: Forward zone go further

### Pointing to IP using local DNS

I am using `nslookup` to find ip of `google.com`.
Adding a custom a record (toto pointing to google IP)
restart thw service, do `nslookup toto.mylabserver.com localhost`, and working
then in `/etc/resolv.conf`, I edit to point to localhost DNS
And when doing `curl` I reach google website !

### Playing with forward zone file

#### Can I have 2 A records with same DNS name?

<details>
<summary>Details...</summary>
<p>

````
cat << EOF >  /var/named/fwd.mylabserver.com.db
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
; A Record Definitions
nameserver       IN      A       172.31.18.93
nameserver       IN      A       172.31.18.94
mailprod         IN      A       172.31.18.30
mailbackup       IN      A       172.31.18.72
; Canonical Name/Alias
dns        IN    CNAME    nameserver.mylabserver.com.
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
systemctl restart named
nslookup nameserver.mylabserver.com localhost

````

Output is:

````shell script
[root@server1 cloud_user]# nslookup nameserver.mylabserver.com localhost
Server:         localhost
Address:        ::1#53

Name:   nameserver.mylabserver.com
Address: 172.31.18.93
Name:   nameserver.mylabserver.com
Address: 172.31.18.94

````

</p>
</details>

Answer is yes.



#### Can I have 1 A record and 1 CNAME with same DNS name


<details>
<summary>Details...</summary>
<p>

````
cat << EOF >  /var/named/fwd.mylabserver.com.db
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
; A Record Definitions
nameserver       IN      A       172.31.18.93
nameserver       IN      A       172.31.18.94
nameserver2      IN      A       172.31.18.95
mailprod         IN      A       172.31.18.30
mailbackup       IN      A       172.31.18.72
; Canonical Name/Alias
nameserver       IN      CNAME    nameserver.mylabserver.com. 
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
````
Output is 

````shell script
[root@server1 cloud_user]# named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
dns_master_load: /var/named/fwd.mylabserver.com.db:18: nameserver.mylabserver.com: CNAME and other data
zone mylabserver.com/IN: loading from master file /var/named/fwd.mylabserver.com.db failed: CNAME and other data
zone mylabserver.com/IN: not loaded due to errors.
````

</p>
</details>

Answer is NO. And it does not make sense.


#### Canonical CNAME case

If change in [conf of section "Can I have 1 A record and 1 CNAME with same DNS name"](#Can-I-have-1-A-record-and-1-CNAME-with-same-DNS-name),
CNAME `nameserver` to `namserver3` it is working.


<details>
<summary>Details...</summary>
<p>

````
cat << EOF >  /var/named/fwd.mylabserver.com.db
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
; A Record Definitions
nameserver       IN      A       172.31.18.93
nameserver       IN      A       172.31.18.94
nameserver2      IN      A       172.31.18.95
mailprod         IN      A       172.31.18.30
mailbackup       IN      A       172.31.18.72
; Canonical Name/Alias
nameserver3      IN      CNAME    nameserver.mylabserver.com. 
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db

systemctl restart named
nslookup nameserver.mylabserver.com localhost

````
Output is (note the A record in response) 

````shell script
[root@server1 cloud_user]# nslookup nameserver3.mylabserver.com localhost
Server:         localhost
Address:        ::1#53

nameserver3.mylabserver.com     canonical name = nameserver.mylabserver.com.
Name:   nameserver.mylabserver.com
Address: 172.31.18.93
Name:   nameserver.mylabserver.com
Address: 172.31.18.94
````

</p>
</details>


#### Can I have 2 different A record pointing to same IP?

<details>
<summary>Details...</summary>
<p>

````
cat << EOF >  /var/named/fwd.mylabserver.com.db
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
; A Record Definitions
nameserver       IN      A       172.31.18.93
nameserver2      IN      A       172.31.18.93
mailprod         IN      A       172.31.18.30
mailbackup       IN      A       172.31.18.72
; Canonical Name/Alias
dns        IN    CNAME    nameserver.mylabserver.com.
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db

systemctl restart named
nslookup nameserver.mylabserver.com localhost
nslookup nameserver2.mylabserver.com localhost

````

Output is

````shell script
[root@server1 cloud_user]# nslookup nameserver.mylabserver.com localhost
Server:         localhost
Address:        ::1#53

Name:   nameserver.mylabserver.com
Address: 172.31.18.93

[root@server1 cloud_user]# nslookup nameserver2.mylabserver.com localhost
Server:         localhost
Address:        ::1#53

Name:   nameserver2.mylabserver.com
Address: 172.31.18.93
````

</p>
</details>

Answer is yes.

#### What happens if I do not define a A record matching a MX record?

See [reverse section](./p2-2-configure-reverse-zone.md)

https://en.wikipedia.org/wiki/MX_record
> The host name must map directly to one or more address records (A, or AAAA) in the DNS, and must not point to any CNAME records.

<details>
<summary>Details...</summary>
<p>

````
cat << EOF >  /var/named/fwd.mylabserver.com.db
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
; A Record Definitions
nameserver       IN      A       172.31.18.93
; mailprod         IN     A       172.31.18.30 <- COMMENTED
; mailbackup       IN     A       172.31.18.72 <- COMMENTED
; Canonical Name/Alias
dns              IN    CNAME    nameserver.mylabserver.com.
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
````

Output is 

````shell script
[root@server1 cloud_user]# named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
zone mylabserver.com/IN: mylabserver.com/MX 'mailprod.mylabserver.com' has no address records (A or AAAA)
zone mylabserver.com/IN: mylabserver.com/MX 'mailbackup.mylabserver.com' has no address records (A or AAAA)
zone mylabserver.com/IN: loaded serial 10030
OK
````

We have a warning saying no A record is associated.

````
systemctl restart named
nslookup -type=mx mailprod.mylabserver.com localhost
nslookup mylabserver.com localhost
nslookup -type=mx mylabserver.com localhost
````

###### Note the nslookup which is particular
(level above)
````shell script
[root@server1 cloud_user]# nslookup -type=mx mailprod.mylabserver.com localhost
Server:         localhost
Address:        ::1#53

** server can't find mailprod.mylabserver.com: NXDOMAIN

[root@server1 cloud_user]# nslookup mylabserver.com localhost
Server:         localhost
Address:        ::1#53

*** Can't find mylabserver.com: No answer

[root@server1 cloud_user]# nslookup -type=mx mylabserver.com localhost
Server:         localhost
Address:        ::1#53

mylabserver.com mail exchanger = 20 mailbackup.mylabserver.com.
mylabserver.com mail exchanger = 10 mailprod.mylabserver.com.
````
It uses the zone in the named.

If uncomment A record we do not have IP.

</p>
</details>

#### Can I remove entry with same name as the zone

Taking example from [summary](p2-1-summary-configure-forward-zone.md) and removing nameserver.

````
cat << EOF >  /var/named/fwd.mylabserver.com.db
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
; A Record Definitions
mailprod         IN      A       172.31.18.30
mailbackup       IN      A       172.31.18.72
; Canonical Name/Alias
dns        IN    CNAME    nameserver.mylabserver.com.
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
````

Output is

````shell script
[root@server1 cloud_user]# named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
zone mylabserver.com/IN: NS 'nameserver.mylabserver.com' has no address records (A or AAAA)
zone mylabserver.com/IN: not loaded due to errors.
````

Sp we have to keep it

Reapply [summary](p2-1-summary-configure-forward-zone.md)  (except sed) to restore state.

More details in `systemctl status named.service` and `journalctl -xe`.

````shell script
[root@server1 cloud_user]# named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
zone mylabserver.com/IN: NS 'nameserver.mylabserver.com' has no address records (A or AAAA)
zone mylabserver.com/IN: not loaded due to errors.
[root@server1 cloud_user]# systemctl restart named
Job for named.service failed because the control process exited with error code. See "systemctl status named.service" and "journalctl -xe" for details.
[root@server1 cloud_user]#
[root@server1 cloud_user]# systemctl status named.service
● named.service - Berkeley Internet Name Domain (DNS)
   Loaded: loaded (/usr/lib/systemd/system/named.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Wed 2020-06-17 12:16:25 UTC; 10s ago
  Process: 11672 ExecStop=/bin/sh -c /usr/sbin/rndc stop > /dev/null 2>&1 || /bin/kill -TERM $MAINPID (code=exited, status=0/SUCCESS)
  Process: 1596 ExecStart=/usr/sbin/named -u named -c ${NAMEDCONF} $OPTIONS (code=exited, status=0/SUCCESS)
  Process: 11682 ExecStartPre=/bin/bash -c if [ ! "$DISABLE_ZONE_CHECKING" == "yes" ]; then /usr/sbin/named-checkconf -z "$NAMEDCONF"; else echo "Checking of zone files is disabled"; fi (code=exited, status=1/FAILURE)
 Main PID: 1598 (code=exited, status=0/SUCCESS)

Jun 17 12:16:25 server1 bash[11682]: _default/mylabserver.com/IN: bad zone
Jun 17 12:16:25 server1 bash[11682]: zone localhost.localdomain/IN: loaded serial 0
Jun 17 12:16:25 server1 bash[11682]: zone localhost/IN: loaded serial 0
Jun 17 12:16:25 server1 bash[11682]: zone 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa/IN: loaded serial 0
Jun 17 12:16:25 server1 bash[11682]: zone 1.0.0.127.in-addr.arpa/IN: loaded serial 0
Jun 17 12:16:25 server1 bash[11682]: zone 0.in-addr.arpa/IN: loaded serial 0
Jun 17 12:16:25 server1 systemd[1]: named.service: control process exited, code=exited status=1
Jun 17 12:16:25 server1 systemd[1]: Failed to start Berkeley Internet Name Domain (DNS).
Jun 17 12:16:25 server1 systemd[1]: Unit named.service entered failed state.
Jun 17 12:16:25 server1 systemd[1]: named.service failed.
[root@server1 cloud_user]#
````
#### Can I override a public entry in my local DNS


<details>
<summary>Details...</summary>
<p>

````

vim /etc/named.conf
# Insert
zone "com" {
type master;
file "/var/named/fwd.com.db";
};

named-checkconf


cat << EOF >  /var/named/fwd.com.db
\$TTL    86400
@       IN      SOA     nameserver.com. root.com. (
                      10030         ; Serial
                       3600         ; Refresh
                       1800         ; Retry
                     604800         ; Expiry
                      86400         ; Minimum TTL
)
; Name Server
@        IN      NS       nameserver.com.
; A Record Definitions
google           IN      A       42.42.42.42
nameserver       IN      A       172.31.18.94
; I have to keep nameserver as explained previously
EOF

named-checkzone com.  /var/named/fwd.com.db
chmod 760 /var/named/fwd.com.db
chgrp named /var/named/fwd.com.db

systemctl restart named

nslookup google.com localhost
````

Output is :

````shell script
[root@server1 cloud_user]# nslookup google.com localhost
Server:         localhost
Address:        ::1#53

Name:   google.com
Address: 42.42.42.42
````

It enables to understand naming convention.

</p>
</details>

Answer is yes



### Playing with nslookup

See example of mx in section above (we also type soa in note on [recusive and authoritative](./p2-1-zz-note-on-recursive-and-authoritative-dns.md).

