# DNS

## Create a chroot Jail

Isolating BIND in a chroot jail is common practice. 
It prevents any malicious user, who happens to gain access to the system by exploiting a BIND vulnerability,
from further exploiting the system. In this lab, we'll practice setting up a jail for BIND.

ABC Company is currently in the process of setting up its own internally-hosted DNS service.
The next phase of the project is to set BIND up in a chroot jail.
The DNS administrator fell sick and is unavailable, but the project has a tight timeline. 
We have been designated as a resource to set up a BIND chroot jail with a forward DNS zone.

To complete this lab we'll need to set up a chroot jail and then create a forward zone file that contains the following records:

* TTL Record
* SOA Record
* A Records:
    * nameserver
    * mailprod
    * mailbackup
* CNAME Record:
    * dns = nameserver.mylabserver.com.

## Logging In

Use the credentials on the hands-on lab page to log in, via SSH, as cloud_user to the provided server.
Gain root privileges with sudo -i.

**Note** : As mentionned in [fw zone summary](p2-1-summary-configure-forward-zone.md) and 
[rev zone summary](p2-2-summary-configure-reverse-zone.md), 
we consider setup is already done as in the lab otherwise do steps described in [dns cache section](p1-1-dns-cache.md) after login an root.

## Set up the chroot Jail for the BIND Service

In CentOS all we need to do is run

````shell script
yum install bind-chroot -y
```` 
and then ensure that the normal BIND service isn't set to run:

````shell script
systemctl stop named
systemctl disable named
systemctl enable named-chroot
````

Note:

````shell script
[root@server1 ~]# systemctl stop named
[root@server1 ~]# systemctl disable named
Removed symlink /etc/systemd/system/multi-user.target.wants/named.service.
[root@server1 ~]# systemctl enable named-chroot
Created symlink from /etc/systemd/system/multi-user.target.wants/named-chroot.service to /usr/lib/systemd/system/named-chroot.service.
````
I have no symlink when it is not the `named-chroot`

Everything in hidden section is exactly the same as [fw zone summary(2nd part)](p2-1-summary-configure-forward-zone.md).
Except they change zone name to chroot-zone (this we do not care)
AND THAT AT THE END WE RESTART named-chroot and not named:

````shell script
systemctl restart named-chroot
````

Thus I will apply it instead.

<details>
<summary>Details...</summary>
<p>


Add the Forward Zone Configuration to the `/etc/named.conf` File,
Then Run the `named-checkconf` Command to Verify the Configuration
Open `/etc/named.conf` for editing: `vim /etc/named.conf`
Insert the zone configuration just before the include statements at the bottom of the file:

````shell script
zone "mylabserver.com" {
        type master;
        file "/var/named/chroot-zone.db";
};
````

Then run the named-checkconf command to verify the configuration:

````shell script
named-checkconf
````

Create the Forward Zone File and Check the Configuration for Syntax Errors with named-checkzone
Create the forward zone file:

````shell script
vim /var/named/chroot-zone.db


 $TTL    86400
 @       IN      SOA     nameserver.mylabserver.com. root.mylabserver.com. (
                           10030         ; Serial
                            3600         ; Refresh
                            1800         ; Retry
                          604800         ; Expiry
                           86400         ; Minimum TTL
 )
 ; Name Server
 @        IN      NS       nameserver.mylabserver.com.

 nameserver       IN      A       172.31.18.93
 mailprod         IN      A       172.31.18.30
 mailbackup       IN      A       172.31.18.72

 dns        IN    CNAME    nameserver.mylabserver.com.

 @        IN    MX    10    mailprod.mylabserver.com.
 @        IN    MX    20    mailbackup.mylabserver.com.
````
Save the document with :wq!.

Run the named-checkzone command to check the zone file for syntax errors:
````shell script
named-checkzone mylabserver.com /var/named/chroot-zone.db
````
Change the File Permissions and the Group Owner for `/var/named/fwd.mylabserver.com.db`

Change the file permissions for `/var/named/chroot-zone.db`
````shell script
chmod 760 /var/named/chroot-zone.db
````

Change the group owner of the file to named:

````shell script
chgrp named /var/named/chroot-zone.db
````

Start the Newly Configured named-chroot Service

````shell script
systemctl start named-chroot
````

Test Name Resolution

We'll test things with a couple of nslookup commands:

````shell script
nslookup mailprod.mylabserver.com localhost
nslookup dns.mylabserver.com localhost
````

</p>
</details>

To make sure we're actually running BIND in a chrooted jail, run this:

````shell script
mount | grep chroot
````

We'll see that all of the BIND-related things are mounted in `/var/named/chroot`.

Output is:

````shell script
[root@server1 ~]# mount | grep chroot
/dev/xvda2 on /var/named/chroot/etc/localtime type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/xvda2 on /var/named/chroot/etc/named.root.key type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/xvda2 on /var/named/chroot/etc/named.conf type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/xvda2 on /var/named/chroot/etc/named.rfc1912.zones type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/xvda2 on /var/named/chroot/etc/rndc.key type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/xvda2 on /var/named/chroot/etc/named.iscdlv.key type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/xvda2 on /var/named/chroot/etc/protocols type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/xvda2 on /var/named/chroot/etc/services type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/xvda2 on /var/named/chroot/etc/named type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
/dev/xvda2 on /var/named/chroot/usr/lib64/bind type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
tmpfs on /var/named/chroot/run/named type tmpfs (rw,nosuid,nodev,seclabel,mode=755)
/dev/xvda2 on /var/named/chroot/var/named type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
````

Note we do conf in normal place and bind is doing it for us.

Stop here!
DNX LXA OK completed
