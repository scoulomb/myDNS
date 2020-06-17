## DNS 

### SOA record

See notes [here](./p2-1-zz-note-on-recursive-and-authoritative-dns.md)

### What is a ns record? 

Going back to forward zone lab env and running [summary](./p2-1-summary-configure-forward-zone.md).
We have defined a ns in a soa.
And the command:

````shell script
[root@server1 cloud_user]# nslookup nameserver.mylabserver.com -type=ns localhost
Server:         localhost
Address:        ::1#53

Name:   nameserver.mylabserver.com
Address: 172.31.18.93
````

It returns the A record

````shell script
[root@server1 cloud_user]# nslookup nameserver.mylabserver.com -type=A localhost
Server:         localhost
Address:        ::1#53

Name:   nameserver.mylabserver.com
Address: 172.31.18.93
````

This is why here in [forward zone question](./p2-1-xx-questions.md#Can-I-remove-entry-with-same-name-as-the-zone),
I could not remove it.
Also [reverse zone question](./p2-2-xx-questions.md#Can-I-remove-entry-with-same-name-as-the-zone),
Note we were able to remove it.
STOP HERE OK