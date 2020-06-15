# DNS

Run script in [summary](./p2-1-configure-forward-zone-summary.md)

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
````

</p>
</details>

#### What happens if I do not define a A record matching a MX record ?

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

</p>
</details>

##### Can I have 1 CNAME and 1 A record with same DNS name (it is not possible with Infoblox)?

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
nameserver2      IN      A       172.31.18.95
mailprod         IN      A       172.31.18.30
mailbackup       IN      A       172.31.18.72
; Canonical Name/Alias
dns              IN    CNAME    nameserver.mylabserver.com.
nameserver2      IN    CNAME    nameserver.mylabserver.com.
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
````

</p>
</details>


### Playing with nslookup


### Can I override a public entry


````

vim /etc/named.conf
# Insert
zone "com" {
type master;
file "/var/named/fwd.com.db";
};

named-checkconf


cat << EOF >  /var/named/com.db
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
EOF

named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
chmod 760 /var/named/fwd.mylabserver.com.db
chgrp named /var/named/fwd.mylabserver.com.db

systemctl restart named

nslookup google.com localhost
````
