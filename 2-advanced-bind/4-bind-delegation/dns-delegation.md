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
And in this process, glue could be needed. Real config is more similar to this.

Here we have shown a subpart of the recursion mechanism starting at tld.

See [next section where will apply concept in real workd](../5-real-world-application/real-world-application.md).


<!--
I will not do generic image
-->