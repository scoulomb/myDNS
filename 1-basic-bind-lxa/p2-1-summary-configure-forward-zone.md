# DNS 

## Configure forward zone summary

[With ArchLinux equivalent - Configure forward zone](with-archlinux-p2-1-summary-configure-forward-zone.md)
 
<!--
We automate this with a sed
https://fabianlee.org/2018/10/28/linux-using-sed-to-insert-lines-before-or-after-a-match/

````
vim /etc/named.conf
# Insert the zone configuration just before the include statements at the bottom of the file:

zone "mylabserver.com" {
type master;
file "/var/named/fwd.mylabserver.com.db";
};
````

-->


````
ssh cloud_user@3.80.8.88
sudo su
````

Note we consider setup is already done as in the lab otherwise do steps described in [dns cache section](p1-1-dns-cache.md) after login an root.

````
# Insert the zone configuration just before the include statements at the bottom of the file:
sed -i '/^include.*named.rfc1912.zones.*/i zone "mylabserver.com" { type master; file "/var/named/fwd.mylabserver.com.db"; };' /etc/named.conf

named-checkconf

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
mailprod         IN      A       172.31.18.30
mailbackup       IN      A       172.31.18.72
scoulomb         IN      A       42.42.42.42
; AAAA records definitions
scoulombipv6     IN      AAAA    2001:db8:85a3:8d3:1319:8a2e:370:7348
; Canonical Name/Alias
dns        IN    CNAME    nameserver.mylabserver.com.
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db

chmod 760 /var/named/fwd.mylabserver.com.db
chgrp named /var/named/fwd.mylabserver.com.db

systemctl restart named

nslookup mailprod.mylabserver.com localhost
nslookup nameserver.mylabserver.com localhost
nslookup scoulomb.mylabserver.com localhost
nslookup scoulombipv6.mylabserver.com localhost
````

I added `scoulomb` to
 - have A record with different name as zone and not linked to MX.
 and `scoulombipv6` record to:
 - have a AAAA record