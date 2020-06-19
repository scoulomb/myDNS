# DNS 

## Create a Forward Zone

We will configure a forward zone and a forward zone file, then add TTL, SOA, NS, and A records. Next, we will run a syntax check on the named.conf and the forward zone file with named-checkconf and named-checkzone commands. These commands allow a name server to resolve a query, given the hostname, and returns the IP address. This is the most common type of DNS query.

To complete this lab, we need to use the vim command to create and open a forward zone file and create the following records:

- TTL Record
- SOA Record
- A Records:
  - nameserver
  - mailprod
  - mailbackup
- CNAME Record:
    - dns = nameserver.mylabserver.com.

### Before We Begin

To get started, we need to log in to our terminal using the provided lab credentials. Once logged in, use sudo su and the provided password to become the root user.
Environment is prepared otherwise do as before


### Add the Forward Zone

To begin, we need to add the forward zone and configuration to the /etc/named.conf file. Then run the named-checkconf command to verify the configuration by doing the following:

Add the forward zone configuration:
````
vim /etc/named.conf
````
Insert the zone configuration just before the include statements at the bottom of the file:

````
zone "mylabserver.com" {
type master;
file "/var/named/fwd.mylabserver.com.db";
};
````

Save and quit with the :wq command.
Run the named-checkconf command to verify the configuration.

````
named-checkconf
````

As long as nothing is output, we know that we completed the lab correctly.

### Create the Forward Zone File

Next, we need to create our forward zone file and check the configuration for syntax errors with named-checkzone. To do so, complete the following:

Create the forward zone file:
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
mailprod         IN      A       172.31.18.30
mailbackup       IN      A       172.31.18.72
; Canonical Name/Alias
dns        IN    CNAME    nameserver.mylabserver.com.
; Mail Exchange Records
@        IN    MX    10    mailprod.mylabserver.com.
@        IN    MX    20    mailbackup.mylabserver.com.
EOF
````

Run the `named-checkzone` command to check the zone file for syntax errors.
````
named-checkzone mylabserver.com /var/named/fwd.mylabserver.com.db
````

Once we confirm there are no errors, we can continue.

Change the File Permissions
To finish the lab, we need to change the file permissions and the group owner for `/var/named/fwd.mylabserver.com.db`, restart the service, and then test the configuration. To do so, complete the following:

Change the file permissions for `/var/named/fwd.mylabserver.com.db`:

````
chmod 760 /var/named/fwd.mylabserver.com.db
````
Change the group owner of the file to named:
````
chgrp named /var/named/fwd.mylabserver.com.db
````
Restart the named service.

````
systemctl restart named
````
Run a query to test the configuration.

````
nslookup mailprod.mylabserver.com localhost
````
