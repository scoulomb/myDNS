# DNS 

## Configure forward zone summary

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
sudo su

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
````
