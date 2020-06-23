# DNS 

## Configure forward zone summary with ArchLinux

Equivalent to [Lab Summary](p2-1-summary-configure-forward-zone.md).

Make a clean setup

<!--
Unlike lab setup we need to install and enable named 
Setup was done in [dns cache section](./p1-1-dns-cache.md).
Note  yum install -y bind bind-utils and here it is bind-tools,
In ubuntu it is:
 sudo apt-get install bind9
 sudo apt-get install bind9-utils
-->
````
systemctl stop named
sudo pacman -R bind bind-tools --noconfirm
sudo pacman -S bind bind-tools --noconfirm

systemctl start named
systemctl enable named
````

Do the  conf


<!--
Unlike lab setup we insert at end of file and not the include
-->

````
# Insert the zone configuration at end of file
# https://unix.stackexchange.com/questions/20573/sed-insert-text-after-the-last-line
sed -i '$azone "mylabserver.com" { type master; file "/var/named/fwd.mylabserver.com.db"; };' /etc/named.conf

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

nslookup mailprod.mylabserver.com 127.0.0.1
nslookup nameserver.mylabserver.com 127.0.0.1
nslookup scoulomb.mylabserver.com 127.0.0.1
nslookup scoulombipv6.mylabserver.com 127.0.0.1
````

<!--
Unlike the lab setup targeted DNS is 127.0.0.1 and not localhost
-->