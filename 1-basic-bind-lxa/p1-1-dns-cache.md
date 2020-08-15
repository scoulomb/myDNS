# DNS 

## DNS: Configure a Caching Only Name Server

It is a local recursive DNS server 

````
$ ssh cloud_user@<"public server IP">
````

After, we need to use `sudo -i` to gain root access in the terminal, which will ask for the password we used before:

````
$ sudo -i
````
Then enter in id:

````
# id
uid=0(root) gid=0(root) groups=0(root) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023id
````

Create the Caching Only Name Server
Install the bind and bind-utils packages using yum:

````
# yum install -y bind bind-utils
````

Verify the named configuration for localhost with cat and checking that port 53 appears under the options section:

````
# cat /etc/named.conf
````

Check the configuration for syntax errors with the named-checkconf command:

````
# named-checkconf
````

If nothing appears, then we're good to go.

Start and enable the named service:

````
# systemctl start named
# systemctl enable named
````

Run a DNS query against the DNS server defined in /etc/resolv.conf:

````
cat `/etc/resolv.conf`
````
Next, perform a lookup to run a query against the default name server:
````
# nslookup google.com
````

Finally, run a DNS query against localhost:
````
# nslookup google.com localhost
````

Our cached result appears. (when hit twice from localhost)

### Personal Notes

Doing
````
nslookup google.com localhost
````

We could have reached same result by doing `nslookup google.com` and change  in `/etc/resolv.conf` the DNS server to localhost

Similarly as localhost we can replace Amazon recursive DNS server by google one `8.8.8.8` with this 2 ways

At home in `/etc/resolv.conf` DNS server of ISP provider, but on coprprate laptop it can be corporate DNS server (can be different if vpn/premise or not as ip can be priv/pub; cf confl ipv6/4) 

Conclusion of this is that rather than using a remote recursive DNS server we can use our own

It is  what is in orange here so that we have in our own cache
https://umbrella.cisco.com/blog/difference-authoritative-recursive-dns-nameservers
https://serverfault.com/questions/118020/running-a-recursive-dns-server-on-localhost
