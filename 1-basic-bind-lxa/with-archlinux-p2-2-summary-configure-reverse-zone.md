# DNS

## Configure Reverse zone summary with ArchLinux

Equivalent to [Lab Summary](p2-2-summary-configure-reverse-zone.md),

Make a clean setup

<!--
Unlike lab setup we need to install and enable named 
Setup was done in [dns cache section](./p1-1-dns-cache.md).
Note  yum install -y bind bind-utils and here it is bind-tools,
In ubuntu it is:
 sudo apt-get install bind9
 sudo apt-get install bind9-utils
-->

Command below are not needed if we run [fw zone summary with Archlinux](with-archlinux-p2-1-summary-configure-forward-zone.md).
This enables to have both fw and rev zone.

<!--
Unlike lab env
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
Unlike lab setup 
- we change computation
- we insert at end of file and not before the include (note we do not use sed here)
-->

````
export HOST_IP=$( ip addr | grep -A 3 eth0 | grep inet | head -n 1 |  cut -d ' ' -f 6 | cut -d '/' -f 1)
echo $HOST_IP

export HOST_IP_ARRAY=($(echo $HOST_IP | tr "." "\n"))
export REVERSE_ZONE="${HOST_IP_ARRAY[2]}.${HOST_IP_ARRAY[1]}.${HOST_IP_ARRAY[0]}"
export REVERSE_ZONE_CONF="zone \"${REVERSE_ZONE}.in-addr.arpa\" {  type master;  file \"/var/named/${REVERSE_ZONE}.db\";};"

echo $REVERSE_ZONE_CONF

# Set reverse zone conf in named
echo ${REVERSE_ZONE_CONF} >> /etc/named.conf
named-checkconf


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
${HOST_IP_ARRAY[3]} IN      PTR       nameserver.mylabserver.com.
; which is last octet of my IP
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF

cat  /var/named/${REVERSE_ZONE}.db
named-checkzone ${REVERSE_ZONE}.db.in-addr.arpa /var/named/${REVERSE_ZONE}.db 

chmod 760 /var/named/${REVERSE_ZONE}.db
chgrp named /var/named/${REVERSE_ZONE}.db


systemctl restart named

nslookup $HOST_IP 127.0.0.1
````

<!--
Unlike the lab setup targeted DNS is 127.0.0.1 and not localhost
-->

Note the querying 

````shell script
[root@archlinux dev]# nslookup -type=PTR 15.2.0.10.in-addr.arpa 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

15.2.0.10.in-addr.arpa  name = nameserver.mylabserver.com.

[root@archlinux dev]# nslookup 15.2.0.10.in-addr.arpa 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

*** Can't find 15.2.0.10.in-addr.arpa: No answer

[root@archlinux dev]# nslookup -type=A 10.0.2.15 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

15.2.0.10.in-addr.arpa  name = nameserver.mylabserver.com.

[root@archlinux dev]# nslookup 10.0.2.15 127.0.0.1
15.2.0.10.in-addr.arpa  name = nameserver.mylabserver.com.
````
which is resolving as A.

Note IPv6: https://www.ionos.fr/digitalguide/hebergement/aspects-techniques/enregistrement-ptr/