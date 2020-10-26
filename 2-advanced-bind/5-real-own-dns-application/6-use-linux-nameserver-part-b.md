# Use linux nameserver via NAT - part B

## Apply this to the DNS !

From lesson learnt in [part A](6-use-linux-nameserver-part-a.md).
We will modify IT TLD (ns record) to target our own DNS (we could have also delegated a subzone).
 
Our own DNS will be deployed as a container and orchestrated by [Kubernetes in VM deployed with Vagrant](https://github.com/scoulomb/myk8s/blob/master/Setup/ArchDevVM/archlinux-dev-vm-with-minikube.md).

As a results we will have seen 3 ways to deploy a DNS:
- DNS on Docker in bare metal/VM (which can be in the cloud) (example here)
- Infoblox on premise
- Managed DNS (AWS, GCP, Azure, Gandi) (what we did in 2. and 5. with AWS)
- DNS on bare metal/VM (which can be in the cloud)


### Configure local DNS with Kube and make it available on public internet

We will apply same technique as in this [Advanced bind section](../../2-advanced-bind).
This will deploy a Docker DNS with Kubernetes and exposed it via a Node Port service.
It will also perform test (`nslookup` via multiple methods).
You can check the [script](6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh).

Service node port for DNS is set to  `nodePort: 32048` in the script.

Thus we will perform following NAT configuration in box: 

```
hp-dns	UDP	Port	53	192.168.1.32	32048
```

Then we run the script

````shell script
sudo rm -rf /tmp; sudo mkdir /tmp # If issue JUJU_LOCK_DENIED
sudo minikube start --vm-driver=none # need to use sudo

chmod u+x ~/myDNS/2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
~/myDNS/2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
````
fixed file dcocker path ; run nigth for gandi to update
We can see it is working as an external DNS from this output using public IP via ddns
pour demodelegmieux?
````
++ nslookup scoulomb.coulombel.it scoulomb.ddns.net
Server:		scoulomb.ddns.net
Address:	109.29.148.109#53

Name:	scoulomb.coulombel.it
Address: 41.41.41.41

````

This also worked from another machine in same LAN.
(Note that weirdly when using private IP from another machine in same LAN it did not lan even with inactive firewall STOP OK)

<!--
STOP OK in this file + script ok
-->

### Configure the registrar to target the DNS via the DynDNS

#### Change nameserver

As Gandi requires to have 2 NS record, I created a second record for training purpose pointing to Box IP.
https://my.noip.com/#!/dynamic-dns
Note this record is not updated automatically and pointing to same nameserver (in a real environment it should be another one). 

I will then switch to my NS record in gandi: 
https://admin.gandi.net/domain/69ba17f6-d4b2-11ea-8b42-00163e8fd4b8/coulombel.it/nameservers


#### Nameserver stuck

The nameserver change became stuck.
An assumption was that update was stuck because nameserver was off.
But not only.
It was due to the fact our nameservers was not passing the check.
We can run the check here: https://dns-check.nic.it/
Where we add our nameservers:

- scoulomb2.ddns.net.
- scoulomb.ddns.net.

Here is the diff to make the test pass.


````
commit_after=$(git log | grep -A 2 -B 4 "Fix zone file to pass checks on https://dns-check.nic.it" | grep commit | head -n 1 | awk {'print $2'})
commit_before=$(git log | grep -A 2 -B 4 "Fix zone file to pass checks on https://dns-check.nic.it" | grep commit | tail -n 1 | awk {'print $2'})

git diff $commit_before $commit_after
````
Output is

````shell script
sylvain@sylvain-hp:~/myDNS$ git diff --minimal --no-color $commit_before $commit_after 
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
modified: 2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
@ 2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db:2 @
$TTL    300
- @       IN      SOA     nameserver.coulombel.it. root.coulombel.it. (^M
+ @       IN      SOA     scoulomb.ddns.net. root.coulombel.it. (^M
                      10030         ; Serial
                       3600         ; Refresh
                       1800         ; Retry
@ 2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db:10 @ $TTL    300
                        300         ; Minimum TTL
)
; Name Server
- @        IN      NS       nameserver.coulombel.it.
+ @        IN      NS       scoulomb.ddns.net.
+ @        IN      NS       scoulomb2.ddns.net.
; A Record Definitions
- nameserver       IN      A       127.0.0.1^M
+ ; scoulomb.ddns.net.       IN      A       127.0.0.1^M
; not used because in good zone but this would be the glue
; Cf. https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/4-bind-delegation/docker-bind-dns-it-cc-tld/fwd.it.db#L26
scoulomb         IN      A       41.41.41.41
@ 2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db:24 @ scoulomb         IN      A       41.41.41.41
@                    IN      A       185.199.110.153
@                    IN      A           185.199.111.153

- ; We have zone TTL on top, and in SOA ttl for non match
\ No newline at end of file
+ ; We have zone TTL on top, and in SOA ttl for non match

+ @                IN      MX   10  scoulomb.ddns.net.
\ No newline at end of file
````

After launching the script with that modif test pass.
Then I let my laptop turned on for test to pass less than 1 hour (kubectl delete --all po will make test fail)
And registrar was updated.

Here is Gandi answer
<details>
  <summary>Click to expand!</summary>

> Selon les règles du registre .IT, il faudrait passer ce 'DNS check' avant tout changement DNS:
> https://dns-check.nic.it/

> Je viens de faire un test pour vous et le résultat est 'FAILED'. Je vous invite alors à faire le test en ligne et à corriger les erreurs listées sur la page.

> Votre domaine coulombel.it utilise actuellement Gandi LiveDNS et vous pouvez gérer vos enregistrements DNS ici:
> https://admin.gandi.net/domain/69ba17f6-d4b2-11ea-8b42-00163e8fd4b8/coulombel.it/records

> Si vous rencontrez d'autres problèmes, merci de nous donner plus de détails. 

</details>


#### Check DNS query

After we wait config being finally applied (even if Gandi gui say it is ok we have )


````
$ nslookup -type=NS  it
$ nslookup -type=NS coulombel.it dns.nic.it.
Server:		dns.nic.it.
Address:	192.12.192.5#53

Non-authoritative answer:
*** Can't find coulombel.it: No answer

Authoritative answers can be found from:
coulombel.it	nameserver = ns-142-b.gandi.net.
coulombel.it	nameserver = ns-142-c.gandi.net.
coulombel.it	nameserver = ns-161-a.gandi.net.
[wait 5min after GUI update]
$ nslookup -type=NS coulombel.it dns.nic.it.
Server:		dns.nic.it.
Address:	192.12.192.5#53

Non-authoritative answer:
*** Can't find coulombel.it: No answer

Authoritative answers can be found from:
coulombel.it	nameserver = scoulomb.ddns.net.
coulombel.it	nameserver = scoulomb2.ddns.net.
````

So finally rather than doing

````
nslookup scoulomb.coulombel.it scoulomb.ddns.net
````
As registrar is configured we can do


````
nslookup scoulomb.coulombel.it 8.8.8.8
nslookup scoulomb.coulombel.it # dns got by dhcp (sfr)
````
 And we have correct output :)
 
````shell script
$ nslookup scoulomb.coulombel.it 8.8.8.8
Server:		8.8.8.8
Address:	8.8.8.8#53

Non-authoritative answer:
Name:	scoulomb.coulombel.it
Address: 41.41.41.41

$ nslookup scoulomb.coulombel.it 
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	scoulomb.coulombel.it
Address: 41.41.41.41

````

and we can use dig, where it is highly visible we enter in my box

````shell script
$ dig +trace scoulomb.coulombel.it @8.8.8.8

; <<>> DiG 9.16.1-Ubuntu <<>> +trace scoulomb.coulombel.it @8.8.8.8
;; global options: +cmd
.			87082	IN	NS	e.root-servers.net.
.			87082	IN	NS	h.root-servers.net.
.			87082	IN	NS	l.root-servers.net.
.			87082	IN	NS	i.root-servers.net.
.			87082	IN	NS	a.root-servers.net.
.			87082	IN	NS	d.root-servers.net.
.			87082	IN	NS	c.root-servers.net.
.			87082	IN	NS	b.root-servers.net.
.			87082	IN	NS	j.root-servers.net.
.			87082	IN	NS	k.root-servers.net.
.			87082	IN	NS	g.root-servers.net.
.			87082	IN	NS	m.root-servers.net.
.			87082	IN	NS	f.root-servers.net.
.			87082	IN	RRSIG	NS 8 0 518400 20201105170000 20201023160000 26116 . t1+BwXbec50DLsWUcOLpMygGIkslmclYAtr/2pImVQYv9TevddyUywiA bUGjo35YGcoRqWz6rxDG15u3fRQKr3TYkNjOqbXj+G8ZhOptgQLbArCv ZmEIiZ6CMXtYMK+9xY7KwEzBZhB6Er3C4S9YzZTK4GLd38Gc7QOu0Bub Iu0Qb83/MrjfFzaC7nHL0Uq6ibMK8PTG1olk4Nz0mRjbxkL7dpCY0si2 8sUcIx7tdYV4Er38Anrxh/d/JaVwMQ6Y1hQylrOeXKFsmRUsIIdJwMUM kQDblkvue9THjh7BuGRRwU74x/uGGjRk4dhYemDRs96KBXQT6IkuKizb eu3cpg==
;; Received 525 bytes from 8.8.8.8#53(8.8.8.8) in 40 ms

it.			172800	IN	NS	a.dns.it.
it.			172800	IN	NS	m.dns.it.
it.			172800	IN	NS	r.dns.it.
it.			172800	IN	NS	s.dns.it.
it.			172800	IN	NS	dns.nic.it.
it.			172800	IN	NS	nameserver.cnr.it.
it.			86400	IN	DS	41901 10 2 47F7F7BA21E48591F6172EED13E35B66B93AD9F2880FC9BADA64F68C E28EBB90
it.			86400	IN	RRSIG	DS 8 1 86400 20201105170000 20201023160000 26116 . myEIsWqJsNafA1YePgdnDuHekKcwk3MBfIrZJrqIag0FcyZkWt+MQKxY OJEfHCuAjTQdaFSRJZFXZ91sZq78w9gNez3BZNUtHrhVp5YnIKZTlGz4 kwqPeBX6KSo2+4FrMLvGjVn673lIrWZR/3SLOA9c4Y4u/t3m+LJ4+e1y ZvqnUIALas93oRcTre3qF/IBYZKsVe0F+f+fAIvbcecDFg4c+uya4U6c kgjmJwfN64Ccw2/H0evN/9UpqK803fhF+WncuNt0gCqW0VylxcH7Q2BM TH3v4EJMiAAIoEeAucXpYcV1gtnofrJ9Tzt8TylKXTXBPtI9rrV+SVBK IFSjBg==
;; Received 768 bytes from 198.97.190.53#53(h.root-servers.net) in 48 ms

coulombel.it.		10800	IN	NS	scoulomb2.ddns.net.
coulombel.it.		10800	IN	NS	scoulomb.ddns.net.
M3UUN6EMAUDPL0KK2LB1MT3M5JTD4RKC.it. 3600 IN NSEC3 1 1 10 82C448EE8C9922FD M47BUOTATA5R66H82DDVPNEF63E144AL NS SOA RRSIG DNSKEY NSEC3PARAM
M3UUN6EMAUDPL0KK2LB1MT3M5JTD4RKC.it. 3600 IN RRSIG NSEC3 10 2 3600 20201122190338 20201023190338 18395 it. GO7+wneMZaQ9xUPJTpUyehaB0acWiZyk1NCSu094LoPM4PXFy92IFuAG DrD4edF5+WXjTwPIqYrer+d6/35FSfRqaj4onIpKe8UtPJDQTiyNyxhZ p6g6ptbhZwOekldHROcG7p1m/02qflr0uvKM5Js/gRRq9DHBM5dyUjtt cov5gdhYni+GsCgJKzoqrQ/M72qPZLh5XFD01bnhecc3+Kr4sbeyP8rd vVfkgkv9E639brG3FVUKp33AUDqpC9AaDhWxeM+sHILYmOZraazMjM+P VQXZ4262ft13NjAqkFAVq2ykYr7SghG7K6N2h5hou9lZTKgyQp6O8qkj uWaVlg==
JSPOS95NHRV9UCSKTN4G8VE5Q9TT4CIQ.it. 3600 IN NSEC3 1 1 10 82C448EE8C9922FD JSUVDS77SR1VVS3B3GEDLMDGVV6E1POS NS DS RRSIG
JSPOS95NHRV9UCSKTN4G8VE5Q9TT4CIQ.it. 3600 IN RRSIG NSEC3 10 2 3600 20201122190338 20201023190338 18395 it. ODDuQo0D3FrVcMIr29Xqt/XujmZyDivCoOCbgd1VOtvOePyTooJm+JoX gbNVYTJMpopEDlH4lgg/N/gofz2NAPesn4VEmlImcWH3wQbXr4Mfw1Jc HMKdaQbFF0ccE29I3OJBQsoU2CkeYmCEwlo7vSFLx0dh/+7APfepVu17 R/6NZTCT4tWc+T39IffTZsQzBMyNW8TbtQ8GnRy/dHe1ZM/3slMTwTZb qj178Gvmdwz6YS2gNl9nuDYRzidZeXNKzjOI3p/fvrPtp8OpTMin3CcH ZL4KmjXkdnhp6uaofVj1XjKGy9fdmHA7V8UI1L+e8ON0aVSvPhYZoySG uvwvLA==
;; Received 890 bytes from 194.146.106.30#53(s.dns.it) in 48 ms

scoulomb.coulombel.it.	300	IN	A	41.41.41.41
coulombel.it.		300	IN	NS	scoulomb.ddns.net.
coulombel.it.		300	IN	NS	scoulomb2.ddns.net.
;; Received 149 bytes from 109.29.148.109#53(scoulomb.ddns.net) in 0 ms

````

And can access github with my own dns (tested with phone in 3g)

Note on NS vs A query (we can see NS define at 2 level)

<details>
  <summary>Click to expand!</summary>


````shell script
sylvain@sylvain-hp:~/myDNS$ dig +trace coulombel.it @8.8.8.8 NS

; <<>> DiG 9.16.1-Ubuntu <<>> +trace coulombel.it @8.8.8.8 NS
;; global options: +cmd
.			86954	IN	NS	m.root-servers.net.
.			86954	IN	NS	b.root-servers.net.
.			86954	IN	NS	c.root-servers.net.
.			86954	IN	NS	d.root-servers.net.
.			86954	IN	NS	e.root-servers.net.
.			86954	IN	NS	f.root-servers.net.
.			86954	IN	NS	g.root-servers.net.
.			86954	IN	NS	h.root-servers.net.
.			86954	IN	NS	a.root-servers.net.
.			86954	IN	NS	i.root-servers.net.
.			86954	IN	NS	j.root-servers.net.
.			86954	IN	NS	k.root-servers.net.
.			86954	IN	NS	l.root-servers.net.
.			86954	IN	RRSIG	NS 8 0 518400 20201105170000 20201023160000 26116 . t1+BwXbec50DLsWUcOLpMygGIkslmclYAtr/2pImVQYv9TevddyUywiA bUGjo35YGcoRqWz6rxDG15u3fRQKr3TYkNjOqbXj+G8ZhOptgQLbArCv ZmEIiZ6CMXtYMK+9xY7KwEzBZhB6Er3C4S9YzZTK4GLd38Gc7QOu0Bub Iu0Qb83/MrjfFzaC7nHL0Uq6ibMK8PTG1olk4Nz0mRjbxkL7dpCY0si2 8sUcIx7tdYV4Er38Anrxh/d/JaVwMQ6Y1hQylrOeXKFsmRUsIIdJwMUM kQDblkvue9THjh7BuGRRwU74x/uGGjRk4dhYemDRs96KBXQT6IkuKizb eu3cpg==
;; Received 525 bytes from 8.8.8.8#53(8.8.8.8) in 36 ms

it.			172800	IN	NS	a.dns.it.
it.			172800	IN	NS	m.dns.it.
it.			172800	IN	NS	r.dns.it.
it.			172800	IN	NS	s.dns.it.
it.			172800	IN	NS	dns.nic.it.
it.			172800	IN	NS	nameserver.cnr.it.
it.			86400	IN	DS	41901 10 2 47F7F7BA21E48591F6172EED13E35B66B93AD9F2880FC9BADA64F68C E28EBB90
it.			86400	IN	RRSIG	DS 8 1 86400 20201105170000 20201023160000 26116 . myEIsWqJsNafA1YePgdnDuHekKcwk3MBfIrZJrqIag0FcyZkWt+MQKxY OJEfHCuAjTQdaFSRJZFXZ91sZq78w9gNez3BZNUtHrhVp5YnIKZTlGz4 kwqPeBX6KSo2+4FrMLvGjVn673lIrWZR/3SLOA9c4Y4u/t3m+LJ4+e1y ZvqnUIALas93oRcTre3qF/IBYZKsVe0F+f+fAIvbcecDFg4c+uya4U6c kgjmJwfN64Ccw2/H0evN/9UpqK803fhF+WncuNt0gCqW0VylxcH7Q2BM TH3v4EJMiAAIoEeAucXpYcV1gtnofrJ9Tzt8TylKXTXBPtI9rrV+SVBK IFSjBg==
;; Received 759 bytes from 198.41.0.4#53(a.root-servers.net) in 44 ms

coulombel.it.		10800	IN	NS	scoulomb2.ddns.net.
coulombel.it.		10800	IN	NS	scoulomb.ddns.net.
M3UUN6EMAUDPL0KK2LB1MT3M5JTD4RKC.it. 3600 IN NSEC3 1 1 10 82C448EE8C9922FD M47BUOTATA5R66H82DDVPNEF63E144AL NS SOA RRSIG DNSKEY NSEC3PARAM
M3UUN6EMAUDPL0KK2LB1MT3M5JTD4RKC.it. 3600 IN RRSIG NSEC3 10 2 3600 20201122190338 20201023190338 18395 it. GO7+wneMZaQ9xUPJTpUyehaB0acWiZyk1NCSu094LoPM4PXFy92IFuAG DrD4edF5+WXjTwPIqYrer+d6/35FSfRqaj4onIpKe8UtPJDQTiyNyxhZ p6g6ptbhZwOekldHROcG7p1m/02qflr0uvKM5Js/gRRq9DHBM5dyUjtt cov5gdhYni+GsCgJKzoqrQ/M72qPZLh5XFD01bnhecc3+Kr4sbeyP8rd vVfkgkv9E639brG3FVUKp33AUDqpC9AaDhWxeM+sHILYmOZraazMjM+P VQXZ4262ft13NjAqkFAVq2ykYr7SghG7K6N2h5hou9lZTKgyQp6O8qkj uWaVlg==
JSPOS95NHRV9UCSKTN4G8VE5Q9TT4CIQ.it. 3600 IN NSEC3 1 1 10 82C448EE8C9922FD JSUVDS77SR1VVS3B3GEDLMDGVV6E1POS NS DS RRSIG
JSPOS95NHRV9UCSKTN4G8VE5Q9TT4CIQ.it. 3600 IN RRSIG NSEC3 10 2 3600 20201122190338 20201023190338 18395 it. ODDuQo0D3FrVcMIr29Xqt/XujmZyDivCoOCbgd1VOtvOePyTooJm+JoX gbNVYTJMpopEDlH4lgg/N/gofz2NAPesn4VEmlImcWH3wQbXr4Mfw1Jc HMKdaQbFF0ccE29I3OJBQsoU2CkeYmCEwlo7vSFLx0dh/+7APfepVu17 R/6NZTCT4tWc+T39IffTZsQzBMyNW8TbtQ8GnRy/dHe1ZM/3slMTwTZb qj178Gvmdwz6YS2gNl9nuDYRzidZeXNKzjOI3p/fvrPtp8OpTMin3CcH ZL4KmjXkdnhp6uaofVj1XjKGy9fdmHA7V8UI1L+e8ON0aVSvPhYZoySG uvwvLA==
;; Received 879 bytes from 217.29.76.4#53(m.dns.it) in 72 ms

coulombel.it.		300	IN	NS	scoulomb.ddns.net.
coulombel.it.		300	IN	NS	scoulomb2.ddns.net.
;; Received 124 bytes from 109.29.148.109#53(scoulomb2.ddns.net) in 4 ms

sylvain@sylvain-hp:~/myDNS$ dig +trace coulombel.it @8.8.8.8 A

; <<>> DiG 9.16.1-Ubuntu <<>> +trace coulombel.it @8.8.8.8 A
;; global options: +cmd
.			86426	IN	NS	m.root-servers.net.
.			86426	IN	NS	b.root-servers.net.
.			86426	IN	NS	c.root-servers.net.
.			86426	IN	NS	d.root-servers.net.
.			86426	IN	NS	e.root-servers.net.
.			86426	IN	NS	f.root-servers.net.
.			86426	IN	NS	g.root-servers.net.
.			86426	IN	NS	h.root-servers.net.
.			86426	IN	NS	a.root-servers.net.
.			86426	IN	NS	i.root-servers.net.
.			86426	IN	NS	j.root-servers.net.
.			86426	IN	NS	k.root-servers.net.
.			86426	IN	NS	l.root-servers.net.
.			86426	IN	RRSIG	NS 8 0 518400 20201105170000 20201023160000 26116 . t1+BwXbec50DLsWUcOLpMygGIkslmclYAtr/2pImVQYv9TevddyUywiA bUGjo35YGcoRqWz6rxDG15u3fRQKr3TYkNjOqbXj+G8ZhOptgQLbArCv ZmEIiZ6CMXtYMK+9xY7KwEzBZhB6Er3C4S9YzZTK4GLd38Gc7QOu0Bub Iu0Qb83/MrjfFzaC7nHL0Uq6ibMK8PTG1olk4Nz0mRjbxkL7dpCY0si2 8sUcIx7tdYV4Er38Anrxh/d/JaVwMQ6Y1hQylrOeXKFsmRUsIIdJwMUM kQDblkvue9THjh7BuGRRwU74x/uGGjRk4dhYemDRs96KBXQT6IkuKizb eu3cpg==
;; Received 525 bytes from 8.8.8.8#53(8.8.8.8) in 36 ms

it.			172800	IN	NS	a.dns.it.
it.			172800	IN	NS	m.dns.it.
it.			172800	IN	NS	r.dns.it.
it.			172800	IN	NS	s.dns.it.
it.			172800	IN	NS	dns.nic.it.
it.			172800	IN	NS	nameserver.cnr.it.
it.			86400	IN	DS	41901 10 2 47F7F7BA21E48591F6172EED13E35B66B93AD9F2880FC9BADA64F68C E28EBB90
it.			86400	IN	RRSIG	DS 8 1 86400 20201105170000 20201023160000 26116 . myEIsWqJsNafA1YePgdnDuHekKcwk3MBfIrZJrqIag0FcyZkWt+MQKxY OJEfHCuAjTQdaFSRJZFXZ91sZq78w9gNez3BZNUtHrhVp5YnIKZTlGz4 kwqPeBX6KSo2+4FrMLvGjVn673lIrWZR/3SLOA9c4Y4u/t3m+LJ4+e1y ZvqnUIALas93oRcTre3qF/IBYZKsVe0F+f+fAIvbcecDFg4c+uya4U6c kgjmJwfN64Ccw2/H0evN/9UpqK803fhF+WncuNt0gCqW0VylxcH7Q2BM TH3v4EJMiAAIoEeAucXpYcV1gtnofrJ9Tzt8TylKXTXBPtI9rrV+SVBK IFSjBg==
;; Received 759 bytes from 199.7.83.42#53(l.root-servers.net) in 36 ms

coulombel.it.		10800	IN	NS	scoulomb.ddns.net.
coulombel.it.		10800	IN	NS	scoulomb2.ddns.net.
M3UUN6EMAUDPL0KK2LB1MT3M5JTD4RKC.it. 3600 IN NSEC3 1 1 10 82C448EE8C9922FD M47BUOTATA5R66H82DDVPNEF63E144AL NS SOA RRSIG DNSKEY NSEC3PARAM
M3UUN6EMAUDPL0KK2LB1MT3M5JTD4RKC.it. 3600 IN RRSIG NSEC3 10 2 3600 20201122190338 20201023190338 18395 it. GO7+wneMZaQ9xUPJTpUyehaB0acWiZyk1NCSu094LoPM4PXFy92IFuAG DrD4edF5+WXjTwPIqYrer+d6/35FSfRqaj4onIpKe8UtPJDQTiyNyxhZ p6g6ptbhZwOekldHROcG7p1m/02qflr0uvKM5Js/gRRq9DHBM5dyUjtt cov5gdhYni+GsCgJKzoqrQ/M72qPZLh5XFD01bnhecc3+Kr4sbeyP8rd vVfkgkv9E639brG3FVUKp33AUDqpC9AaDhWxeM+sHILYmOZraazMjM+P VQXZ4262ft13NjAqkFAVq2ykYr7SghG7K6N2h5hou9lZTKgyQp6O8qkj uWaVlg==
JSPOS95NHRV9UCSKTN4G8VE5Q9TT4CIQ.it. 3600 IN NSEC3 1 1 10 82C448EE8C9922FD JSUVDS77SR1VVS3B3GEDLMDGVV6E1POS NS DS RRSIG
JSPOS95NHRV9UCSKTN4G8VE5Q9TT4CIQ.it. 3600 IN RRSIG NSEC3 10 2 3600 20201122190338 20201023190338 18395 it. ODDuQo0D3FrVcMIr29Xqt/XujmZyDivCoOCbgd1VOtvOePyTooJm+JoX gbNVYTJMpopEDlH4lgg/N/gofz2NAPesn4VEmlImcWH3wQbXr4Mfw1Jc HMKdaQbFF0ccE29I3OJBQsoU2CkeYmCEwlo7vSFLx0dh/+7APfepVu17 R/6NZTCT4tWc+T39IffTZsQzBMyNW8TbtQ8GnRy/dHe1ZM/3slMTwTZb qj178Gvmdwz6YS2gNl9nuDYRzidZeXNKzjOI3p/fvrPtp8OpTMin3CcH ZL4KmjXkdnhp6uaofVj1XjKGy9fdmHA7V8UI1L+e8ON0aVSvPhYZoySG uvwvLA==
;; Received 879 bytes from 194.0.16.215#53(a.dns.it) in 44 ms

coulombel.it.		300	IN	A	185.199.109.153
coulombel.it.		300	IN	A	185.199.110.153
coulombel.it.		300	IN	A	185.199.111.153
coulombel.it.		300	IN	A	185.199.108.153
coulombel.it.		300	IN	NS	scoulomb2.ddns.net.
coulombel.it.		300	IN	NS	scoulomb.ddns.net.
;; Received 188 bytes from 109.29.148.109#53(scoulomb.ddns.net) in 0 ms

````

</details>

### Add record for application deployed behind the box 

Application like Jupyter, Python server or VLC server.
(so NAT forwarding also performed as in [part A](6-use-linux-nameserver-part-a.md))

See forwarding zone [file](./6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db).

````
; here we use scoulomb.ddns.net. for application deployed behind the box and not for the DNS itself
home             IN      CNAME     scoulomb.ddns.net.
````

so that nslookup output is

````
$ nslookup home.coulombel.it
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
home.coulombel.it	canonical name = scoulomb.ddns.net.
Name:	scoulomb.ddns.net
Address: 109.29.148.109

````

If we have a look at resolution pattern here:
1. Laptop get IP and default DNS by DHCP server contains in router : `127.0.0.53`
2. The DNS acquired is also embedded in the router
3. DNS resolution (gtm):
    1. DNS from router `127.0.0.53:53` -> Forward to DNS recursive SFR (Router DNS could also do the recursion) 
    2. Recursion: home.coulombel.it [1] -> scoulomb.ddns.net [2] -> Box public IP `109.29.148.109` [3]
        - Details for `home.coulombel.it` [1] resolution:
            1. recursive server ask `IT` tld to find nameserver for coulombel.it via `NS` record 
            2. Answer is `scoulomb.ddns.net` [2] which is resolved to box public IP `109.29.148.109`
            3. Recursive server asks machine with box public IP `109.29.148.109` nameserver to resolve home.coulombel.it
            4. Box public IP `109.29.148.109`:`32048` -> NAT ->  machine with DNS server private IP `192:168.1.32`:`53`
            5. `192:168.1.32`:`53` -> k8s NodePort service -> k8s Pod IP of `ubuntu-dns` pod
            6. From record `home IN CNAME scoulomb.ddns.net.`
            7. It returns `scoulomb.ddns.net` which is resolved to Box public IP `109.29.148.109` [3]
            8. Thus the answer with Box public IP `109.29.148.109`
4. Box public IP `109.29.148.109`:<NAT application-port> -> NAT -> machine private IP `192.168.1.32`:`<application-port>


It is the particular case where application is hosted on same machine as nameserver (see `3.2.7`).

`scoulomb.ddns.net` is resolved to box public IP `109.29.148.109` by following normal A resolution mechanism.
Non static box ip is updated by no-ip (using box or the DUC).

If we were use using Gandi live DNS replace in all `3.2`. It would work the same.

`Recursion: home.coulombel.it [1] -> scoulomb.ddns.net [2] -> Box public IP `109.29.148.109` [3]`

by 

`Recursion: home.coulombel.it [1] ->Gandi Live DNS  [2] -> Box public IP `109.29.148.109` [3]`

### Use DNS name to switch between public IP when outisde the LAN and private IP when inside the LAN using router internal DNS

Here there is no difference if client is in the same LAN as the application server or not.

But when we are inside the local network. We could improve the flow to not go outside to come back inside the LAN.
Thus not use the Box public IP + NAT and only rely on private IP.

For this purpose we can configure entry in DNS from router.
http://192.168.1.1/network/dns

Here we define:
```shell script
192.168.1.32	home.coulombel.it
```

So that 

````shell script
$ nslookup home.coulombel.it
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
Name:	home.coulombel.it
Address: 192.168.1.32
````

That way local resolution in LAN is 

1. Laptop get IP and default DNS by DHCP server contains in router : `127.0.0.53`
2. The DNS acquired is also embedded in the router
3. DNS resolution (gtm):
    1. DNS from router `127.0.0.53:53` -> is authoritative for `home.coulombel.it`
    2. returns entry `192.168.1.32`
4. Machine private IP `192.168.1.32`:`<application-port>`

This is not a forwarding or recursion, but a definition of authoritative record in targeted DNS.
It is what we did when we [override google](../../1-basic-bind-lxa/p2-1-xx-questions.md#can-i-override-a-public-entry-in-my-local-dns)

If client is not in the LAN, we go through the previous resolution pattern (with some modif DNS from router can become dns from 3g)
Tp prove it we will do following experiment in a different laptop (equivalent to the Android phone):
- connected to wifi in the BOX LAN

````
sylvain@sylvain-Latitude-D430:~$ nslookup home.coulombel.it 
Server:		127.0.1.1
Address:	127.0.1.1#53

Name:	home.coulombel.it
Address: 192.168.1.32
````
- connected to phone tethering with 3G connection  

````shell script
sylvain@sylvain-Latitude-D430:~$ nslookup home.coulombel.it 
Server:		127.0.1.1
Address:	127.0.1.1#53

Non-authoritative answer:
home.coulombel.it	canonical name = scoulomb.ddns.net.
Name:	scoulomb.ddns.net
Address: 109.29.148.109
````


which is exactly what we want.
DNS can perform the switch with public and private IP.
This would also work with Gandi (no need to test).

We show an example how it is used with VLC here:

https://github.com/scoulomb/music-streamer#cname-to-ddns-advanced

<!-- glue not need as ddns.net used and not coulombel.it in it tld OK-->

We tested with our nameserver, it would work the same with Gandi (thus not tested here)

<!-- 25/10/2020, 3PM: All ok above and music streamer aligned see commit -->

## TODO


[I AM HERE] 
- music steamer todo: https://github.com/scoulomb/music-streamer
- use view as alternative Use DNS name to switch between public IP when outside the LAN and private IP when inside the LAN using router internal DNS + (cf. 6z)

- Could prepare a DNS presentation with this 

For demo could make more sense to perform domain delegation, but fine if updated before.
It would be the same principle!
DNS demo with AWS already in AWS demo and here show docker


<!-- not explored dns in ipconfig
And possibility to configure a DNS in box itself, how to change SFR DNS 

commit "Fix zone file to pass checks on https://dns-check.nic.it" + script from everywhere OK-->

- check 2 cname with same name
- when several A round robin

-We tested with our nameserver, it would work the same with Gandi (thus not tested here)
Check it?