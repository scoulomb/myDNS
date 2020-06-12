# DNS

## Create a Reverse Zone File

---
[HERE]
 

And also how mix ptr and arecord?
STOP
reverse for PTR and CNAME? shouldwork

----

We will see how to configure the zone in `/etc/named.conf` and create the Start of Authority record as well as other records in the reverse zone file. Then we'll test our configuration with a reverse query.

We will add the zone configuration to the `/etc/named.conf file.` 
Then, create a reverse zone file. Also, create the following records in the reverse zone file:

- TTL Record
- SOA Record
- Name Server
- PTR Records:
  - nameserver.mylabserver.com.
  - mailprod.mylabserver.com.
  - mailbackup.mylabserver.com.
Before We Begin
To get started, we need to log in to our terminal using the provided lab credentials. Once logged in, use sudo su - and the provided password to become the root user.

### Get the IP Address for the Primary Interface

First, we need to record the IP address for the primary interface for the lab server:

````
ifconfig -a
ifconfig -a | grep -A 3 eth0 | grep inet | head -n 1 | cut -d ' ' -f 10 > ip.txt
cat ip.txt
````

Copy the IP address to a document for later use. => `10.0.1.33`
Note It matches the given private ip!

### Add the Reverse Zone Configuration
With our IP address found, we need to add the reverse zone configuration to the /etc/named.conf file. Then run the named-checkconf command to verify the configuration. To do so, complete the following:

Open our `/etc/named.conf` document:

````
vim /etc/named.conf
````

Take the first three octets of the private IP address from the previous step and enter it in reverse order where you see xx.xx.xxx (for example, if our server's IP address is `10.0.1.55`, then `xx.xx.xxx` is going to be `1.0.10`). Insert the zone configuration just before the include statements at the bottom of the file:

````
zone "xx.xx.xxx.in-addr.arpa" {
    type master;
    file "/var/named/xx.xx.xxx.db";
};
````
In our case

````
vim /etc/named.conf

zone "1.0.10.in-addr.arpa" {
    type master;
    file "/var/named/1.0.10.db";
};
  
````
Save the document with wq.

Run the `named-checkconf` command to verify the configuration:
````
named-checkconf
````
Create the Reverse Zone File
With the configuration created, we need to create the reverse zone file and check the configuration for syntax errors with named-checkzone:

Create the reverse zone file using the IP address information in /var/named/xx.xx.xxx.db:

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
; aaa       IN      PTR       nameserver.mylabserver.com.
; bbb       IN      PTR       mailprod.mylabserver.com.
; ccc       IN      PTR       mailbackup.mylabserver.com.
240         IN      PTR       nameserver.mylabserver.com.
; which is last octet of my IP
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF
````

Note the aaa, bbb, and ccc. Those will be the last octet in the actual IP address of whichever server they belong to. If the IP address of nameserver.mylabserver.com is 10.0.1.23, then that line would read:


Save the document with :wq.
Run the named-checkzone command to check the zone file for syntax errors:
````
named-checkzone xx.xx.xxx.in-addr.arpa /var/named/xx.xx.xxx.db
named-checkzone 1.0.10.db.in-addr.arpa /var/named/1.0.10.db 
````

I had the error:
````
zone 1.0.10.in-addr.arpa/IN: loading from master file /var/named/1.0.10.db failed: no owner
zone 1.0.10.in-addr.arpa/IN: not loaded due to errors.
````

It was due to bad whitespace in LXA (todo: report issue).
It is explained here, also with cat EOF as done with fw zone we should escpae the `\$` at the beginning of the file.



Note: It is expected to see errors for missing A or AAAA records as we did not create those records as part of this exercise.
Indeed I had the warning:

````
[root@server1 cloud_user]# named-checkzone 1.0.10.db.in-addr.arpa /var/named/1.0.10.db
zone 1.0.10.db.in-addr.arpa/IN: 1.0.10.db.in-addr.arpa/MX 'mailprod.mylabserver.com' (out of zone) has no addresses records (A or AAAA)
zone 1.0.10.db.in-addr.arpa/IN: 1.0.10.db.in-addr.arpa/MX 'mailbackup.mylabserver.com' (out of zone) has no addresses records (A or AAAA)
zone 1.0.10.db.in-addr.arpa/IN: loaded serial 10030
OK
````

________Question if done does warning not mentioned?

Change the File Permissions and the Group Owner
Next, we need to change the file permissions and the group owner for /var/named/xx.xx.xxx.db:

Change the file permissions for /var/named/xx.xx.xxx.db:

```
 /var/named/xx.xx.xxx.db
chmod 760 /var/named/1.0.10.db
```

Change the group owner of the file to named:

```
chgrp named /var/named/xx.xx.xxx.db
chgrp named /var/named/1.0.10.db
```

Restart the named service:

````
systemctl restart named
````

Run a query to test the configuration (note that x.x.x.x is the full IP address we got from the initial ifconfig command):

````
nslookup x.x.x.x localhost
nslookup 10.0.1.240 localhost
````

Output is 

````
[root@server1 cloud_user]# nslookup 10.0.1.240 localhost
240.1.0.10.in-addr.arpa name = nameserver.mylabserver.com.
````

____question: get revere record of a CNAME, and of a MX?
https://linuxacademy.com/cp/socialize/index/type/community_post/id/49680

use local when private DNS do forwarding? vpn 

check DNS in k8s
try nslook up with infobloxip as paramto check if i can get test.locfor non reg

que fait le look up d un reverse
a.toto.net ip1
b.toto.net ip1

