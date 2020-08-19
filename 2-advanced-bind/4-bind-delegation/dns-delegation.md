# DNS delegation

## Idea

Objective is to show the concept of DNS delegation via `NS` record.

We will

- Deploy a first DNS pod with bind in k8s cluster which is authoritative for domain `coulombel.it`.
 Let's say authoritative DNS for this domain is managed by Gandi.
- Deploy a second DNS pod which represents `it` top level domain. 
  
In the picture [here](../../1-basic-bind-lxa/p2-1-zz-note-on-recursive-and-authoritative-dns.md#Recursive-DNS-and-authoritative-DNS).
We are the com and Cisco umbrella level.

We will also explain the concept of glue record. Some good explanations can be found here:
- [AFNIC website](https://www.afnic.fr/ext/dns/html/cours245.html) (in french).
- [DNS Simple](https://support.dnsimple.com/articles/ns-record).
- [Gandi](https://docs.gandi.net/en/domain_names/advanced_users/glue_records.html)
- [Zytrax](https://www.zytrax.com/books/dns/ch8/ns.html)

Ensure you understand comment in tld [zone file](docker-bind-dns-it-cc-tld/fwd.it.db.tpl).

## Reset env

```shell script
sudo minikube start --vm-driver=none
cd dev/myDNS/2-advanced-bind/4-bind-delegation/
sudo su 

alias k='kubectl'
kubectl delete deployment --all
kubectl delete po --all --force --grace-period=0
kubectl delete svc --all 
```

And fix potential [build issue](../debug/fix-docker-build-issue.md)
 
## Start gandi DNS server

````shell script
cd docker-bind-dns-gandi
docker build . -f dns-gandi.Dockerfile -t dns-gandi 
kubectl run dns-gandi --image=dns-gandi --restart=Never --image-pull-policy=Never 
kubectl expose pod dns-gandi --port 53 --protocol=UDP
````

For investigation use 

````shell script
k exec -it dns-gandi -- /bin/sh
````

We will check everything is working in the pod

````shell script
# systemctl status named
named.service - BIND Domain Name Server
    Loaded: loaded (/usr/lib/systemd/system/named.service, enabled)
    Active: active (running)
# nslookup coulombel.it 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

Name:   coulombel.it
Address: 42.42.42.42

# exit
````

We can make a lookup from the node using the service

```shell script
DNS_GANDI_SVC_CLUSTER_IP=$(kubectl get svc dns-gandi -o jsonpath={'.spec.clusterIP'})
nslookup coulombel.it $DNS_GANDI_SVC_CLUSTER_IP
````

Output is

````shell script
[root@archlinux docker-bind-dns-gandi]# nslookup coulombel.it $DNS_GANDI_SVC_CLUSTER_IP
Server:         10.109.194.116
Address:        10.109.194.116#53

Name:   coulombel.it
Address: 42.42.42.42

````

Note that the fact we target this DNS explicitly return the authoritative value it contains, rather than performing a recursion.

## Start it cc tld DNS server


````shell script
cd ../docker-bind-dns-it-cc-tld
`````

Before we need to set the glue record pointing to Gandi DNS

````shell script
sed "s/xx.xx.xx.xx/$DNS_GANDI_SVC_CLUSTER_IP/g"  fwd.it.db.tpl > fwd.it.db
````

Check it is correct by doing `k get svc`.

````shell script
docker build . -f dns-tld.Dockerfile -t dns-tld 
kubectl delete po dns-tld --force --grace-period=0
kubectl run dns-tld --image=dns-tld --restart=Never --image-pull-policy=Never 
kubectl expose pod dns-tld --port 53 --protocol=UDP
````


We will check everything is working in the pod

````shell script

k exec -it dns-tld -- nslookup test.it 127.0.0.1
k exec -it dns-tld -- nslookup coulombel.it 127.0.0.1
k exec -it dns-tld --  cat /etc/bind/fwd.it.db | grep 42 # to show 42 coming from delegated
k exec -it dns-tld --  cat /etc/bind/fwd.it.db | grep myns1
k exec -it dns-tld -- dig coulombel.it @127.0.0.1
k exec -it dns-tld -- nslookup override.coulombel.it 127.0.0.1 # to show return value in delegated
````


Output is 

````shell script
[root@archlinux docker-bind-dns-it-cc-tld]# k exec -it dns-tld -- nslookup test.it 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

Name:   test.it
Address: 43.43.43.43

[root@archlinux docker-bind-dns-it-cc-tld]# k exec -it dns-tld -- nslookup coulombel.it 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

Non-authoritative answer:
Name:   coulombel.it
Address: 42.42.42.42
** server can't find coulombel.it: SERVFAIL

command terminated with exit code 1
[root@archlinux docker-bind-dns-it-cc-tld]# k exec -it dns-tld --  cat /etc/bind/fwd.it.db | grep 42
[root@archlinux docker-bind-dns-it-cc-tld]# k exec -it dns-tld --  cat /etc/bind/fwd.it.db | grep myns1
; If the domain name for the DNS which is resolving coulombel.it was not in .it domain like myns1.gandi.net. the glue would not be needed.
coulombel         IN      NS       myns1.gandi.it.
myns1.gandi.it.   IN      A        10.104.113.215
[root@archlinux docker-bind-dns-it-cc-tld]# k exec -it dns-tld -- dig coulombel.it @127.0.0.1
[...]
;coulombel.it.                  IN      A
[...]
[root@archlinux docker-bind-dns-it-cc-tld]# k exec -it dns-tld -- nslookup override.coulombel.it 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

Non-authoritative answer:
Name:   override.coulombel.it
Address: 90.90.90.90
** server can't find override.coulombel.it: SERVFAIL

command terminated with exit code 1

````

We have an error SERVFAIL but resolution actually works.

We can make a lookup from the node using the service

```shell script
DNS_TLD_SVC_CLUSTER_IP=$(kubectl get svc dns-tld -o jsonpath={'.spec.clusterIP'})
nslookup coulombel.it $DNS_TLD_SVC_CLUSTER_IP
nslookup test.it $DNS_TLD_SVC_CLUSTER_IP
````


Output is

````shell script
[root@archlinux docker-bind-dns-it-cc-tld]# nslookup coulombel.it $DNS_TLD_SVC_CLUSTER_IP
Server:         10.100.25.111
Address:        10.100.25.111#53

Non-authoritative answer:
*** Can't find coulombel.it: No answer

[root@archlinux docker-bind-dns-it-cc-tld]# nslookup test.it $DNS_TLD_SVC_CLUSTER_IP
Server:         10.100.25.111
Address:        10.100.25.111#53

Name:   test.it
Address: 43.43.43.43
````

We can see here delgation did not work (subnet issue)
I will try from another client pod 

## Test from a client pod the delegation process
 

````shell script
cd ../client
docker build . -f client.Dockerfile -t dns-client
kubectl delete po dns-client --force --grace-period=0
kubectl run dns-client --image=dns-client --restart=Never --image-pull-policy=Never 
````
And run

````shell script
k exec -it dns-client   -- nslookup test.it $DNS_TLD_SVC_CLUSTER_IP
k exec -it dns-client   -- nslookup coulombel.it $DNS_TLD_SVC_CLUSTER_IP
````

Output shows it working

````shell script
[root@archlinux client]# k exec -it dns-client   -- nslookup test.it $DNS_TLD_SVC_CLUSTER_IP
Server:         10.100.25.111
Address:        10.100.25.111#53

Name:   test.it
Address: 43.43.43.43

[root@archlinux client]# k exec -it dns-client   -- nslookup coulombel.it $DNS_TLD_SVC_CLUSTER_IP
Server:         10.100.25.111
Address:        10.100.25.111#53

Non-authoritative answer:
Name:   coulombel.it
Address: 42.42.42.42
** server can't find coulombel.it: SERVFAIL

command terminated with exit code 1
[root@archlinux client]#
````

Note that we could also do:

````shell script
kubectl run temp -it --image=busybox --restart=Never   --env="DNS_TLD_SVC_CLUSTER_IP=$DNS_TLD_SVC_CLUSTER_IP" --rm 
nslookup coulombel.it $DNS_TLD_SVC_CLUSTER_IP
````

<!-- I did not try with an entrypoint like busybox for custom img -->


As as we are running in pod we can DNS resolution by k8s CoreDNS for DNS service itself:

````shell script
k exec -it dns-client -- nslookup coulombel.it dns-tld
````

I use a custom pod (not busybox) to have dig (but not running a recursive server here)

````shell script
k exec -it dns-client   -- dig coulombel.it @$DNS_TLD_SVC_CLUSTER_IP
````

Output is

````shell script
[root@archlinux client]# k exec -it dns-client   -- dig coulombel.it @$DNS_TLD_SVC_CLUSTER_IP

; <<>> DiG 9.16.1-Ubuntu <<>> coulombel.it @10.100.25.111
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 6765
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 6c8ac86f80552684010000005f3a69be8147fa4ee05e4acb (good)
;; QUESTION SECTION:
;coulombel.it.                  IN      A

;; ANSWER SECTION:
coulombel.it.           85919   IN      A       42.42.42.42

;; Query time: 3 msec
;; SERVER: 10.100.25.111#53(10.100.25.111)
;; WHEN: Mon Aug 17 11:27:58 UTC 2020
;; MSG SIZE  rcvd: 85

````

If adding `+norecurse` we will not have the A record.

Finally note that when not specifying DNS it will go for normal resolution (root server).
Same when using trace.

Working as expected.
Tough this part is weird:

````shell script
** server can't find coulombel.it: SERVFAIL
````


## Do we always need a glue record?

From [Gandi](https://docs.gandi.net/en/domain_names/advanced_users/glue_records.html)
> A glue record provides the IP address of a nameserver so that the domain can be resolved in
> **the case where the name server is hosted at the same domain as the domain name itself.**

> For example, let’s same the domain name example.com has the nameserver ns1.example.com.
> When requests for example.com are sent to the registry they will point to ns1.example.com.
> This, in turn, will point back to example.com, which points to ns1.example.com, which points to example.com,
> and so on. This creates a dependency loop and makes the domain name unresolvable.
> Glue records include the IP address of the nameserver along with the name of the nameserver,
> preventing this problem from happening.

Is the nameserver is not in the same zone we do not need the glue. for instance if nameserver is not in `it` but `net` zone.

````shell script
cd ../docker-bind-dns-it-cc-tld-no-glue
sed "s/xx.xx.xx.xx/$DNS_GANDI_SVC_CLUSTER_IP/g"  fwd.gandi.net.db.tpl > fwd.gandi.net.db
docker build . -f dns-tld-noglue.Dockerfile -t dns-tld-no-glue
kubectl delete po dns-tld-no-glue --force --grace-period=0 
kubectl run dns-tld-no-glue --image=dns-tld-no-glue --restart=Never --image-pull-policy=Never 
k exec -it dns-tld-no-glue -- cat /etc/bind/fwd.gandi.net.db
k exec -it dns-tld-no-glue -- nslookup coulombel.it 127.0.0.1
````

Output is

````shell script
[root@archlinux docker-bind-dns-it-cc-tld-no-glue]# k exec -it dns-tld-no-glue -- nslookup coulombel.it 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

Non-authoritative answer:
Name:   coulombel.it
Address: 42.42.42.42
** server can't find coulombel.it: SERVFAIL

command terminated with exit code 1
````

Changing `sed "s/xx.xx.xx.xx/$DNS_GANDI_SVC_CLUSTER_IP/g"  fwd.gandi.net.db.tpl > fwd.gandi.net.db` will lead to no resolution.
This it is working well.

Here I defined to simplify `gandi.net` directly in named conf file.
But in reality it will resolve `net` root server, which would resolve `gandi.net` and then `ns-something-x.gandi.net`.
And in this process, glue could be needed. Real config is more similar to this. We will see in [next section where will apply concept in real workd](../5-real-own-dns-application/README.md).

Here we have shown a subpart of the recursion mechanism starting at tld.

From this we understand the glue can help to speed-up queries.
In particular we will see it [next section when talking about glue](../5-real-own-dns-application/2-modify-tld-ns-record.md#Glue-in-Gandi).

This is why Zytrax definition here: https://www.zytrax.com/books/dns/ch8/ns.html is
> Strictly glue records are essential only with referrals which occur only at a **point of delegation** which may be in the zone's parent or in this zone where a subdomain is being delegated. In practice glue records are used for two purposes:
> - To speed up queries - and consequently reduce DNS load - by providing the name and IP addresses (the glue) for all authoritative name servers, both within and external to the domain name being queried. The root and TLD servers for example provide this information in all referrals. In the case of the TLD servers the glue data is not obtained from the domain zone file but from the Registrar when the domain name is registered.
> - To break the query deadlock for referrals which return name servers within the domain being queried. Assume a query for a domain, say the A RR for www.example.com, returns a referral containing the name but not the IP address of a name server, say ns1.example.com, which lies within the domain example.com. Since the IP address of the name server is not known this will naturally result in a query for the A RR of ns1.example.com which will return, again, a referral with the name but not the IP of ns1.example.com which result in another query ..... and so on in an endless loop! When the glue address record is provided this problem does not occur.

Wen looking at forwarding [file](../1-bind-in-docker-and-kubernetes/docker-bind-dns/fwd.mylabserver.com.db).
We can see that we can only define a glue when domain referrals (NS record) is in the same zone as bind in `named.conf` link a zone to zone file.
So for right part before `IN` it is only related to the zone.
But we can use short synthax.

````shell script
nameserver       IN      A       172.31.18.93
;<=> 
nameserver.mylabserver.com. IN      A       172.31.18.93
;  with a dot otherwise nameserver.mylabserver.com.mylabserver.com is defined
````


If doing (cf in forwarding file of start up [example](../1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md).

````shell script
; [1]
scoulomb.fr.         IN      A       42.42.42.42
; [2]
@                    IN      NS      nameserver
````

- [1] This example shows we can use long synthax but we restricted to the zone
- [2] shorty synthax working on right part (same for CNAME)

````shell script
[root@archlinux docker-bind-dns]# kubectl exec -it ubuntu-dns -- nslookup scoulomb.fr localhost
Server:         localhost
Address:        127.0.0.1#53

** server can't find scoulomb.fr: NXDOMAIN

command terminated with exit code 1
[root@archlinux docker-bind-dns]# kubectl exec -it ubuntu-dns -- nslookup -type=NS mylabserver.com localhost
Server:         localhost
Address:        127.0.0.1#53

mylabserver.com nameserver = nameserver.mylabserver.com.
````

## Example of google glue

````shell script
root@archlinux docker-bind-dns]# dig +trace google.com @8.8.8.8 +additional

; <<>> DiG 9.16.0 <<>> +trace google.com @8.8.8.8 +additional
;; global options: +cmd
.                       45749   IN      NS      a.root-servers.net.
.                       45749   IN      NS      b.root-servers.net.
.                       45749   IN      NS      c.root-servers.net.
.                       45749   IN      NS      d.root-servers.net.
.                       45749   IN      NS      e.root-servers.net.
.                       45749   IN      NS      f.root-servers.net.
.                       45749   IN      NS      g.root-servers.net.
.                       45749   IN      NS      h.root-servers.net.
.                       45749   IN      NS      i.root-servers.net.
.                       45749   IN      NS      j.root-servers.net.
.                       45749   IN      NS      k.root-servers.net.
.                       45749   IN      NS      l.root-servers.net.
.                       45749   IN      NS      m.root-servers.net.
.                       45749   IN      RRSIG   NS 8 0 518400 20200901050000 20200819040000 46594 . yUP/6mD0IiLV9KAEm5c6eH2wnx6p0hjgiacLi9NbtAtWdVP4lj395iOh XlxT+hRAqd52NY1cpxwHHwpGtdbYdjoIQ7Qu98QZYAiErgb+RGO5Wjkj t5BjnjnJ1dV+Rrr2QTZIuoIbqUUc9JpPoxvHcyjyXURIp2LpoYauSuzR 2HjmXSRA22SxMIfP6Tm1AWKdevuAA1v70QM2ckuJNHSbAgR1DTRiARje YZNtdARvY55Jtw9tngrWA3jN7PSSfgad0NK9hQjy/ZtOwjbd3uqsZfIs oPXj9A0+hWkhmtXeXDvgbSyHPM9cAgTyMRVfKFUN5ZA+kb6eYE48LOsD 5mdojw==
;; Received 525 bytes from 8.8.8.8#53(8.8.8.8) in 40 ms

com.                    172800  IN      NS      e.gtld-servers.net.
com.                    172800  IN      NS      j.gtld-servers.net.
com.                    172800  IN      NS      m.gtld-servers.net.
com.                    172800  IN      NS      b.gtld-servers.net.
com.                    172800  IN      NS      i.gtld-servers.net.
com.                    172800  IN      NS      a.gtld-servers.net.
com.                    172800  IN      NS      h.gtld-servers.net.
com.                    172800  IN      NS      d.gtld-servers.net.
com.                    172800  IN      NS      f.gtld-servers.net.
com.                    172800  IN      NS      k.gtld-servers.net.
com.                    172800  IN      NS      g.gtld-servers.net.
com.                    172800  IN      NS      l.gtld-servers.net.
com.                    172800  IN      NS      c.gtld-servers.net.
com.                    86400   IN      DS      30909 8 2 E2D3C916F6DEEAC73294E8268FB5885044A833FC5459588F4A9184CF C41A5766
com.                    86400   IN      RRSIG   DS 8 1 86400 20200901200000 20200819190000 46594 . ToDSxXWfZ4I3FMjnxgKH0MMzOB3EbtiiXu8hAZOviVQs+WuP+jrA3odE yDgS0u46GWfucsCD13uX8FBln177oIM4DAy7kapUo7E4359MF9KHwESj TRiM05tW4hlEX8WOCzPm9Fqf0LPbfE5oZnj47wDjWa7s6igOOflsVlhU svdgjUEOAStQsITI57TF9deUdQU+AOE4To5D0XMHW68aU72cj16xApWY /mRp5pRGPcYOoFPdswLR767Td8ULMOkK9q1+H6+qLgmNcq6pR2ulc87r q/IKIoGF193cX3OEy6abTvFCvu2e1gE7BPAXRK4ZdhNBz46OtIJtflnL jaqVyg==
a.gtld-servers.net.     172800  IN      A       192.5.6.30
b.gtld-servers.net.     172800  IN      A       192.33.14.30
c.gtld-servers.net.     172800  IN      A       192.26.92.30
d.gtld-servers.net.     172800  IN      A       192.31.80.30
e.gtld-servers.net.     172800  IN      A       192.12.94.30
f.gtld-servers.net.     172800  IN      A       192.35.51.30
g.gtld-servers.net.     172800  IN      A       192.42.93.30
h.gtld-servers.net.     172800  IN      A       192.54.112.30
i.gtld-servers.net.     172800  IN      A       192.43.172.30
j.gtld-servers.net.     172800  IN      A       192.48.79.30
k.gtld-servers.net.     172800  IN      A       192.52.178.30
l.gtld-servers.net.     172800  IN      A       192.41.162.30
m.gtld-servers.net.     172800  IN      A       192.55.83.30
a.gtld-servers.net.     172800  IN      AAAA    2001:503:a83e::2:30
b.gtld-servers.net.     172800  IN      AAAA    2001:503:231d::2:30
c.gtld-servers.net.     172800  IN      AAAA    2001:503:83eb::30
d.gtld-servers.net.     172800  IN      AAAA    2001:500:856e::30
e.gtld-servers.net.     172800  IN      AAAA    2001:502:1ca1::30
f.gtld-servers.net.     172800  IN      AAAA    2001:503:d414::30
g.gtld-servers.net.     172800  IN      AAAA    2001:503:eea3::30
h.gtld-servers.net.     172800  IN      AAAA    2001:502:8cc::30
i.gtld-servers.net.     172800  IN      AAAA    2001:503:39c1::30
j.gtld-servers.net.     172800  IN      AAAA    2001:502:7094::30
k.gtld-servers.net.     172800  IN      AAAA    2001:503:d2d::30
l.gtld-servers.net.     172800  IN      AAAA    2001:500:d937::30
m.gtld-servers.net.     172800  IN      AAAA    2001:501:b1f9::30
;; Received 1170 bytes from 202.12.27.33#53(m.root-servers.net) in 66 ms

google.com.             172800  IN      NS      ns2.google.com.
google.com.             172800  IN      NS      ns1.google.com.
google.com.             172800  IN      NS      ns3.google.com.
google.com.             172800  IN      NS      ns4.google.com.
CK0POJMG874LJREF7EFN8430QVIT8BSM.com. 86400 IN NSEC3 1 1 0 - CK0Q1GIN43N1ARRC9OSM6QPQR81H5M9A NS SOA RRSIG DNSKEY NSEC3PARAM
CK0POJMG874LJREF7EFN8430QVIT8BSM.com. 86400 IN RRSIG NSEC3 8 2 86400 20200825044255 20200818033255 24966 com. UeS6YPMjS6Tm5+AkjoiI3IVxhxLmKOtRgSzpXsY75nxZm2dbKeyQUX5m 4sHdEeLLVo3J+RV3u0jUj7QSNVUMVKav7okJNre5Ua4EzEjzP2qksnoG e8t5L/EZDs/DQ+E9z1Cl1fewruqxC+v4EQjeirbhzSsgOO1jujs+tA9H PRfloC1KiPMJeLeT+g3CgWGmLqHACR3E8bYqm3qQQu1UYQ==
S84BDVKNH5AGDSI7F5J0O3NPRHU0G7JQ.com. 86400 IN NSEC3 1 1 0 - S84CDVS9VPREADFD6KK7PDADH0M6IO8H NS DS RRSIG
S84BDVKNH5AGDSI7F5J0O3NPRHU0G7JQ.com. 86400 IN RRSIG NSEC3 8 2 86400 20200826043746 20200819032746 24966 com. C8XCbOMM5MXWHvKfApDAep4N2/N2kFXBxqKjHro8+w5UL+seHs/H0SrS D3T5ULTngjCNYBuyUfvWa+b99YsD1YPwmY9TWn0Jh2iEWr/xMYdCMODB pTC8VZ/sNeBP7Kqii1VC1XPbCJYiOJzoBu3ZS4oeErTyETCyRwZaYSAQ n+uX4SBde+E+o2BA9P8jJ2mxzz0kc+oQP+fxpw4gAeaXIQ==
ns2.google.com.         172800  IN      AAAA    2001:4860:4802:34::a
ns2.google.com.         172800  IN      A       216.239.34.10
ns1.google.com.         172800  IN      AAAA    2001:4860:4802:32::a
ns1.google.com.         172800  IN      A       216.239.32.10
ns3.google.com.         172800  IN      AAAA    2001:4860:4802:36::a
ns3.google.com.         172800  IN      A       216.239.36.10
ns4.google.com.         172800  IN      AAAA    2001:4860:4802:38::a
ns4.google.com.         172800  IN      A       216.239.38.10
;; Received 836 bytes from 192.5.6.30#53(a.gtld-servers.net) in 56 ms

google.com.             300     IN      A       216.58.215.46
;; Received 55 bytes from 216.239.36.10#53(ns3.google.com) in 43 ms

````


1. The recursive DNS has an hardcode of the 12 root servers.
    - `nslookup -type=ns . 8.8.8.8` -> `m.root-servers.net.`. (returned by 8.8.8.8)
    - `nslookup -type=A  m.root-servers.net 8.8.8.8` -> `202.12.27.33`.
    
    Note it has a TTL because actually the hardcode is a hint: https://serverfault.com/questions/692713/dns-root-record-hardcoded-then-why-it-has-ttl
    ````shell script
    [root@archlinux docker-bind-dns]# nslookup m.root-servers.net a.root-servers.net
    Server:         a.root-servers.net
    Address:        198.41.0.4#53
    
    Name:   m.root-servers.net
    Address: 202.12.27.33
    Name:   m.root-servers.net
    Address: 2001:dc3::35
    ````
   Then from https://www.iana.org/domains/root/files   
   > Operators who manage a DNS recursive resolver typically need to configure a "root hints file".   
   > This file contains the names and IP addresses of the authoritative name servers for the root zone, so the software can bootstrap the DNS resolution process. 

2. The recursive DNS queries one of the DNS root nameserver (`.`) 
The root server then responds to the resolver with the hostname (in the `NS` record) of Top Level Domain (TLD) DNS server (com) 
    - a. `nslookup -type=ns com 202.12.27.33` -> ` a.gtld-servers.net.`
    - b. `nslookup a.gtld-servers.net. @8.8.8.8` -> `192.5.6.30` 
    (unlike `site`, cf [real own DNS resolution example](../5-real-own-dns-application/1-real-own-dns-resolution-example.md)).
     It's not hosted in same domain, no glue here. We have an indirection (details in 6).
3. The resolver then makes a request to the `.com` TLD.
    - `nslookup -type=ns google.com 192.5.6.30` -> `ns3.google.com.`
    - The TLD server then responds with the hostname (NS record) of the domain’s nameserver for `google.com` which is,  `ns3.google.com`.

4, We come back to step 3 `nslookup -type=ns google.com 192.5.6.30`  to resolve `ns3.google.com` 
      - The name server `ns3.google.com.` is hosted at the same domain as the domain being queried (`google.com`).
    - The query would loop again `nslookup -type=ns google 192.5.5.241`, but actually there is a glue record. -> break the deadlock
    - It is visible in additional section `dig ns3.google.com @192.5.6.30 +norecurse` (but not returned by a nslookup at root).
    - It is clearer in second dig query with `+additional`: `ns3.google.com.         172800  IN      A       216.239.36.10`

5. The recursive resolver sends a query to the domain’s nameserver.
    - `nslookup -type=ns google.com 216.239.36.10` -> Delegate to himself (glue is defined in 2nd nameserver, same as [AFNIC website](https://www.afnic.fr/ext/dns/html/cours245.html))
    - `nslookup -type=A google.com 216.239.36.10` -> `216.58.215.46`
    - The IP address google.com is then returned to the resolver from the nameserver.

6. details to resolve `a.gtld-servers.net.` in step 2.
    1. The recursive DNS has an hardcode of the 12 root servers.
        - `nslookup -type=ns . 8.8.8.8` -> `m.root-servers.net.`.
        - `nslookup -type=A  m.root-servers.net. 8.8.8.8` -> `202.12.27.33`.
    2. `nslookup -type=ns net 202.12.27.33` ->  `a.gtld-servers.net.` (note it is not a delegation here for `g.gtld-servers`)
    3. nameserver `a.gtld-servers.net` has the same domain as the domain being queried but we have a glue
       `dig +norecurse a.gtld-servers.net @202.12.27.33` -> `192.5.6.30` (I can not get it with nslookup)
       
      Here it is particular case where we the glue is on the root server itself (as root server and `a.gtld-servers.net` in same domain being queried `.net`) with an indirection (unlike site).
      This why in `dig` everything is returned in one shot.
      Here unlike site, we would not deadlock at `com` (orginal tld in query) but at `net` level.OK
           
To be compared with [real own DNS resolution example](../5-real-own-dns-application/1-real-own-dns-resolution-example.md).

## My glue definition

So my definition of glue it that it provides IP of the nameserver if it has the same domain as the domain being queries to avoid deadlock,
This can alsp speed-up queries.

See [next section where will apply concept in real workd](../5-real-own-dns-application/real-world-application.md).


<!--
I will not do generic image
-->