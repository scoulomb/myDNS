# DNS

## Create a Reverse Zone File summary

[With ArchLinux equivalent - Configure reverse zone](with-archlinux-p2-2-summary-configure-reverse-zone.md)  

````
ssh cloud_user@3.80.8.88
sudo su
````

Note we consider setup is already done as in the lab otherwise do steps described in [dns cache section](p1-1-dns-cache.md) after login an root.

````

export HOST_PRIVATE_IP=$(ifconfig -a | grep -A 3 eth0 | grep inet | head -n 1 | cut -d ' ' -f 10)
echo $HOST_PRIVATE_IP

export HOST_PRIVATE_IP_ARRAY=($(echo $HOST_PRIVATE_IP | tr "." "\n"))
export REVERSE_ZONE="${HOST_PRIVATE_IP_ARRAY[2]}.${HOST_PRIVATE_IP_ARRAY[1]}.${HOST_PRIVATE_IP_ARRAY[0]}"
export REVERSE_ZONE_CONF="zone \"${REVERSE_ZONE}.in-addr.arpa\" {  type master;  file \"/var/named/${REVERSE_ZONE}.db\";};"
# Or expand only with quote
export REVERSE_ZONE_CONF_2="zone \""$REVERSE_ZONE".in-addr.arpa\" {  type master;  file \"/var/named/"$REVERSE_ZONE".db\";};"


# Set reverse zone conf in named
# https://stackoverflow.com/questions/17477890/expand-variables-in-sed
sed -i "/include.*named.rfc1912.zones.*/i ${REVERSE_ZONE_CONF}" /etc/named.conf
named-checkconf # Does not see all like error on file name because of ""


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
EOF

cat  /var/named/${REVERSE_ZONE}.db
named-checkzone ${REVERSE_ZONE}.db.in-addr.arpa /var/named/${REVERSE_ZONE}.db 

chmod 760 /var/named/${REVERSE_ZONE}.db
chgrp named /var/named/${REVERSE_ZONE}.db


systemctl restart named

nslookup $HOST_PRIVATE_IP localhost
````
