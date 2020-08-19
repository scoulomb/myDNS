# DNS propgation effect 

Let's say we use Gandi Live DNS and define following A record:

````shell script
test-propagation 432000 IN A 55.56.57.58
````

With a TTL of 5 day 

Then I do 

````shell script
nslookup test-propagation.coulombel.it 8.8.8.8    
````

Ouput is 

````shell script
➤ nslookup test-propagation.coulombel.it 8.8.8.8                            vagrant@archlinuxServer:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   test-propagation.coulombel.it
Address: 55.56.57.58
````

I do it several time for it to be replicate in Google DNS server.
````shell script
while true; do
  nslookup test-propagation.coulombel.it 8.8.8.8    
done
ctrl+z
````


If I now  update the record

````shell script
test-propagation 432000 IN A 42.42.42.42
````

And run same command

````shell script
nslookup test-propagation.coulombel.it 8.8.8.8    
````

I have 


````shell script
[vagrant@archlinux myDNS]$ nslookup test-propagation.coulombel.it 8.8.8.8
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   test-propagation.coulombel.it
Address: 55.56.57.58

[vagrant@archlinux myDNS]$ nslookup test-propagation.coulombel.it 8.8.8.8
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   test-propagation.coulombel.it
Address: 42.42.42.42

[vagrant@archlinux myDNS]$ nslookup test-propagation.coulombel.it 8.8.8.8
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   test-propagation.coulombel.it
Address: 55.56.57.58

[vagrant@archlinux myDNS]$ nslookup test-propagation.coulombel.it 8.8.8.8
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   test-propagation.coulombel.it
Address: 55.56.57.58

````

One query return the good value (probably a google recursive server that was not hit),
but almost all queries returns old value.

To ensure new value is returned we can target another DNS like OpenDNS
https://use.opendns.com/ -> `208.67.222.222`

And nobody made a query before with it we have the good value

````shell script
[vagrant@archlinux myDNS]$ nslookup test-propagation.coulombel.it 208.67.222.222
Server:         208.67.222.222
Address:        208.67.222.222#53

Non-authoritative answer:
Name:   test-propagation.coulombel.it
Address: 42.42.42.42
[vagrant@archlinux myDNS]$ nslookup test-propagation.coulombel.it 208.67.222.222
Server:         208.67.222.222
Address:        208.67.222.222#53

Non-authoritative answer:
Name:   test-propagation.coulombel.it
Address: 42.42.42.42
````  

This is why sometimes we use a different DNS/laptop.
- https://github.com/scoulomb/github-page-helm-deployer/blob/master/appendix-github-page-and-dns.md#use-google-dns
- https://github.com/scoulomb/github-page-helm-deployer/blob/master/appendix-github-page-and-dns.md#mutildomain

And (OS/)browser cache.

Do we have a cache when there is no valid answer? 

Yes => https://tools.ietf.org/html/rfc2308


> 3 - Negative Answers from Authoritative Servers
>
>   Name servers authoritative for a zone MUST include the SOA record of
>   the zone in the authority section of the response when reporting an
>   NXDOMAIN or indicating that no data of the requested type exists.
>   This is required so that the response may be cached.  The TTL of this
>   record is set from the minimum of the MINIMUM field of the SOA record
>   and the TTL of the SOA itself, and indicates how long a resolver may
>   cache the negative answer.  The TTL SIG record associated with the
>   SOA record should also be trimmed in line with the SOA's TTL.