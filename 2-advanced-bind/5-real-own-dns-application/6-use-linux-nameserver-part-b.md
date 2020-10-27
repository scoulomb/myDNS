# Use linux nameserver via NAT - part B

Apply this to the DNS !

## Introduction

We will use lesson learnt in [part A](6-use-linux-nameserver-part-a.md) to:
- Deploy our local DNS which becomes our application (as done [here in 6 part A](6-use-linux-nameserver-part-a.md#application-deployment)
Our own DNS will be deployed as a container and orchestrated by [Kubernetes in VM deployed with Vagrant](https://github.com/scoulomb/myk8s/blob/master/Setup/ArchDevVM/archlinux-dev-vm-with-minikube.md).
- Configure a reverse NAT to make this DNS public via router dynamic public IP (as done [here in 6 part A](6-use-linux-nameserver-part-a.md#configure-a-reverse-nat-simple-example))
- Use dynamic DNS (`scoulomb.ddns.net`) to abstract this dynamic public IP (as done [here in 6 part A](6-use-linux-nameserver-part-a.md#dynamic-dns-for-public-ip-with-router-configuration))
- We will modify IT tld NS record to target our own DNS (we could have also delegated a subzone).
We had done exactly the same with route 53 in section:
    - [modify tld NS record](./2-modify-tld-ns-record.md)
    - [delegate subzone](./5-delegate-subzone.md)


 
- Finally we will achieve with our own DNS the same service performed by Gandi for application deployed in section part A to abstract dynamic DNS name.
This what was described [here in 6 part A](6-use-linux-nameserver-part-a.md#abstract-dynamic-dns-via-a-cname)
(we could use another DNS to abstract our own DNS name itself)


As a results we will have seen 3 ways to deploy a DNS:

- DNS on Docker in bare metal/VM (which can be in the cloud) (example here)
- Infoblox on premise
- Managed DNS (AWS, GCP, Azure, Gandi) (what we did in 2. and 5. with AWS)
- DNS on bare metal/VM (which can be in the cloud)

Let's start!


## Configure local DNS with Kube


We will apply same technique as in this [Advanced bind section](../../2-advanced-bind).
This will deploy a Docker DNS with Kubernetes and exposed it via a Node Port service.

It will also perform test (`nslookup` via multiple methods).
You can check the [script](6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh).

Service node port for DNS is set to  `nodePort: 32048` in the script.


````shell script
sudo rm -rf /tmp; sudo mkdir /tmp # If issue JUJU_LOCK_DENIED
sudo minikube start --vm-driver=none # need to use sudo

chmod u+x ~/myDNS/2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
~/myDNS/2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
````


## Configure a reverse NAT to make this DNS public via router dynamic public IP 


Make nameserver available on public internet by performing following NAT configuration in box: 

```
hp-dns	UDP	Port	53	192.168.1.32	32048
```

````shell script
$ nslookup scoulomb.coulombel.it 109.29.148.109
Server:		109.29.148.109
Address:	109.29.148.109#53

Name:	scoulomb.coulombel.it
Address: 41.41.41.41
````


## Use dynamic DNS (`scoulomb.ddns.net`) to abstract this dynamic public IP

We reuse the one performed [here in 6 part A](6-use-linux-nameserver-part-a.md#dynamic-dns-for-public-ip-with-router-configuration))

````
$ nslookup scoulomb.coulombel.it scoulomb.ddns.net
Server:		scoulomb.ddns.net
Address:	109.29.148.109#53

Name:	scoulomb.coulombel.it
Address: 41.41.41.41
````

This also worked from another machine in same LAN with public and private IP.
<!-- tested with dell d430 laptop, office not working -->

Note: those lookup was also made in the original script which will work after this configuration being applied.


## We will modify IT tld NS record to target our own DNS 

We will configure the registrar to target the DNS via the DynDNS

#### Change nameserver

As Gandi requires to have 2 NS record, I created a second record for training purpose pointing to Box IP.
https://my.noip.com/#!/dynamic-dns
Note this record is not updated automatically and pointing to same nameserver (in a real environment it should be another one). 

I then  switch to my NS record in gandi: 
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

Here are example of change needed to make the test pass.

- SOA record to match nameserver in tld
```shell script
- @       IN      SOA     nameserver.coulombel.it. root.coulombel.it.
+ @       IN      SOA     scoulomb.ddns.net. root.coulombel.it. 
```
- NS record defined in tld define zone file
```shell script
- @        IN      NS       nameserver.coulombel.it.
+ @        IN      NS       scoulomb.ddns.net.
+ @        IN      NS       scoulomb2.ddns.net.
```
- Waring if no MX defined
```shell script
+ @                IN      MX   10  scoulomb.ddns.net.
```

You can check the diff
````
commit_after=$(git log | grep -A 2 -B 4 "Upgrade zone file, in particular to pass nic test at https://dns-check.nic.it" | grep commit | head -n 1 | awk {'print $2'})
commit_before=$(git log | grep -A 2 -B 4 "Upgrade zone file, in particular to pass nic test at https://dns-check.nic.it" | grep commit | tail -n 1 | awk {'print $2'})

git diff $commit_before $commit_after
````

<!-- if remove glue still pass, osef better to remove it -->

After launching the script with that modif test pass.

Then I let my laptop turned on for test to pass less than 1 hour (kubectl delete --all po will make test fail)
And registrar was updated.

Here is amazing Gandi answer on that topic:

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

After we wait config being finally applied (even if Gandi gui say it is ok we have to wait)


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

In second query we can see nameservers have been updated.
 
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


<details>
  <summary>Click to expand!</summary>

````shell script
$ dig +trace scoulomb.coulombel.it @8.8.8.8

; <<>> DiG 9.16.1-Ubuntu <<>> +trace scoulomb.coulombel.it @8.8.8.8
;; global options: +cmd
.			86508	IN	NS	e.root-servers.net.
.			86508	IN	NS	h.root-servers.net.
.			86508	IN	NS	l.root-servers.net.
.			86508	IN	NS	i.root-servers.net.
.			86508	IN	NS	a.root-servers.net.
.			86508	IN	NS	d.root-servers.net.
.			86508	IN	NS	c.root-servers.net.
.			86508	IN	NS	b.root-servers.net.
.			86508	IN	NS	j.root-servers.net.
.			86508	IN	NS	k.root-servers.net.
.			86508	IN	NS	g.root-servers.net.
.			86508	IN	NS	m.root-servers.net.
.			86508	IN	NS	f.root-servers.net.
.			86508	IN	RRSIG	NS 8 0 518400 20201109050000 20201027040000 26116 . dqwWHEzNFoCOSuR5nuvnENktpDrpI+YhlDKMIKOEawruLrQw6VLH2E8k jHNUT4F2bUckWARyLfWVfEiCXp6hDPJLjOlPgQoeoQ/dYsE5GbF16cS0 QtphziClTk0H3HUkWk1nDp+4oCjJ2T2x5V1tvQBkRgsIn7QRXtmIkKT1 IrVPEl47ezz60DamPjH8A5Qlj6cWlRCiHc5ofmbaCdBCObg6hU3LHPOt guht0qGvmHCs+ry8aOChHiFiFebJf2+b8yyS8rvYDrXyldqeTkCnePbx bNWKB4l9a/dwo0/Vrm1CW+2GuCLFZbQwLS6LKmfQ4hTN/RGPBUi8XFy9 ohsLwA==
;; Received 525 bytes from 8.8.8.8#53(8.8.8.8) in 40 ms

it.			172800	IN	NS	a.dns.it.
it.			172800	IN	NS	m.dns.it.
it.			172800	IN	NS	r.dns.it.
it.			172800	IN	NS	s.dns.it.
it.			172800	IN	NS	dns.nic.it.
it.			172800	IN	NS	nameserver.cnr.it.
it.			86400	IN	DS	41901 10 2 47F7F7BA21E48591F6172EED13E35B66B93AD9F2880FC9BADA64F68C E28EBB90
it.			86400	IN	RRSIG	DS 8 1 86400 20201109050000 20201027040000 26116 . PSU7LL36eWD36+3R9LGFz3uED8hJMS4gi5ntKycW4PEpCK1sLAiUljIL N/GYx+3ON3ek4e5THJv5/IFyfLwJ7+H8cEEFXenmakDk508KjZr0WuFr 2EuccZ8I55axLAAgLUReYvIHgLsA9UwwK1InqvKica0eplcVzjsoDRXU GyPtBNm8cBcd6tbHZWwTJNY4kuqk9Us1cQUKAko/J7YxNSxMn9SEXBjR bvpGmXWnpzQxmG1vmTiQd+rXbMQQMMr0DD/AKGdEiL7puNfgh/gymudf Ah6WdnnjTTI30Bv9NtZbaXuVc7J1kQpN1k2JFzmRf5XdGvvAk5cbHRSB TqT5ug==
;; Received 768 bytes from 2001:500:1::53#53(h.root-servers.net) in 60 ms

coulombel.it.		10800	IN	NS	scoulomb2.ddns.net.
coulombel.it.		10800	IN	NS	scoulomb.ddns.net.
I5VDNMTKA1FBMFMC0LV5MA81TBQQDTTJ.it. 3600 IN NSEC3 1 1 10 50855F81B28B5243 I600V0OSM3EDAG9NN3MRE5QM63KHO3M6 NS SOA RRSIG DNSKEY NSEC3PARAM
I5VDNMTKA1FBMFMC0LV5MA81TBQQDTTJ.it. 3600 IN RRSIG NSEC3 10 2 3600 20201126100326 20201027100326 18395 it. CK6PJUR5hUfgS3xZGMmag1HRxhEN2N2FgXoxJnKQt7jXjD1dgG7XxjTR 54C7IhoYlmVdvCdSqlWEL9HXF5lWUSrSCU07M6jbyLG1lqTv8yCh8ueN 2x0LOaFWO6VAxMUT8GYN1c0+Np72Btky7tIUWE1GVLjF4fq5G8pivcuX tc9u1HoJPw7M4j7iGjNMLJbRvSQaTH6xleAybYsEJj++EYuuxgcYgQMP j32bjyxTkKiPTf8QvSLbR4GiWSFXUTsVsxnwyN1TF6F4sI09x1iw/MI8 rxJkKJsSpGzx5iM+s9ua0RNbRdGlnB6IVb5hbhcVwZ3IA4apxoErXFax RPkrmA==
T374152R7HPQAFJMN95BCO1I5TIMG1JB.it. 3600 IN NSEC3 1 1 10 50855F81B28B5243 T39GB2T2BVLC46DJJ0K786KDTBVK3E0K NS DS RRSIG
T374152R7HPQAFJMN95BCO1I5TIMG1JB.it. 3600 IN RRSIG NSEC3 10 2 3600 20201126100326 20201027100326 18395 it. d++0QC0Pi2CdLbvXOR4EbM03sokX9VFVaT+1SyrFYFzSZPkr6g2xy31f mXLNTVHz6IoUnNbkol+iSsGWokP332OBJIu0+kC+5SsyuWdkkOT4JKYb v2NKoHCUJm1olbmqZL5hBsxeC4YtYDAehcg6bhd6HludwYkvHFkNuhk4 J0ywLqMFZ9z48AjrDYUq6mElx1lgIcsp1HqeCnUW9vmEeKfmGf6aBPCM 7rGSVUg44dytCDwF2LdE098wSpI5KX26x2ee5stCHos+W1C++hVkrwWp UwCzbsLMR5wKvXIq9G5rqiG676bBOj9K2gxrMxIXiZGxOiT4e+oC0ZqY Tb9Yfw==
;; Received 888 bytes from 2001:760:ffff:ffff::ca#53(r.dns.it) in 76 ms

scoulomb.coulombel.it.	300	IN	A	41.41.41.41
coulombel.it.		300	IN	NS	scoulomb.ddns.net.
coulombel.it.		300	IN	NS	scoulomb2.ddns.net.
;; Received 149 bytes from 109.29.148.109#53(scoulomb.ddns.net) in 0 ms

````

Not dig makes the client doing the recursion, this can impact source IP as will see [here](6-z-appendice-of-use-linux-nameserver-part-b.md).

</details>

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


## Achieve with our own DNS the same service performed by Gandi for application deployed in section part A to abstract dynamic DNS name.
 
We want to achieve what we did [here in 6 part A](6-use-linux-nameserver-part-a.md#abstract-dynamic-dns-via-a-cname)

### Basic CNAME

Add record for application (Jupyter, Python server, SSH) deployed behind the box 

For this purpose in forwarding zone [file](./6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db).
Following record is present:

````
; here we use scoulomb.ddns.net. for application deployed behind the box and not for the DNS itself
home             IN      CNAME     scoulomb.ddns.net.
````

We assume for the moment `home.coulombel.it`, not defined in SFR DNS.

Therefore doing:


````
$ nslookup home.coulombel.it
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
home.coulombel.it	canonical name = scoulomb.ddns.net.
Name:	scoulomb.ddns.net
Address: 109.29.148.109
````


If we have a look at resolution pattern here.
It is a variant with our own DNS of what we had [in section 6](6-use-linux-nameserver-part-a.md#first-we-should-understand-the-resolution-in-details).

1. Laptop get IP and default DNS by DHCP server contains in router : `127.0.0.53`
2. The DNS acquired is also embedded in the router
3. DNS resolution (gtm):
    1. DNS from router `127.0.0.53:53` -> Forward to DNS recursive SFR (Router DNS could also do the recursion) 
    2. Recursion: home.coulombel.it [1] -> scoulomb.ddns.net [2] -> Box public IP `109.29.148.109` [3]
        - Details for `home.coulombel.it` [1] resolution:
            1. recursive server ask `it` tld to find nameserver for coulombel.it via `NS` record 
            2. Answer is `scoulomb.ddns.net` [2] which is resolved to box public IP `109.29.148.109`
            3. Recursive server asks machine with box public IP `109.29.148.109` nameserver to resolve home.coulombel.it
            4. Box public IP `109.29.148.109`:`32048` -> NAT ->  machine with DNS server private IP `192:168.1.32`:`53`
            5. `192:168.1.32`:`53` -> k8s NodePort service -> k8s Pod IP of `ubuntu-dns` pod
            6. From record `home IN CNAME scoulomb.ddns.net.`
            7. It returns `scoulomb.ddns.net` which is resolved to Box public IP `109.29.148.109` [3]
            8. Thus the answer with Box public IP `109.29.148.109`
4. Box public IP `109.29.148.109`:<NAT application-port> -> NAT -> machine private IP `192.168.1.32`:`<application-port>

It is the particular case where application is hosted on same machine as nameserver (see `3.2.7`).


Comparing with Gandi resolution in [in section 6](6-use-linux-nameserver-part-a.md#first-we-should-understand-the-resolution-in-details).
We have replaced:
`Recursion: home.coulombel.it [1] -> Gandi Live DNS  [2] -> Box public IP `109.29.148.109` [3]`
by
`Recursion: home.coulombel.it [1] -> scoulomb.ddns.net [2] -> Box public IP `109.29.148.109` [3]`

And have control on the NAT.

<!-- keep this intermediary step for explanations and 4g resolution explained in A -->

### Use DNS name to switch between public IP when outside the LAN and private IP when inside the LAN

We define in SFR box internal DNS.
`192.168.1.32	home.coulombel.it`

And verify switch happens with another laptop as before 

<!--
(given issue with 192.168.1.32).
-->

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

- And be careful when connected to phone but phone is on Wifi

```shell script
sylvain@sylvain-Latitude-D430:~$ nslookup home.coulombel.it
Server:		127.0.1.1
Address:	127.0.1.1#53

Name:	home.coulombel.it
Address: 192.168.1.32
```

<!-- glue not need as ddns.net used and not coulombel.it in it tld OK-->


We show an example where we apply concept of part A and B with VLC here:
https://github.com/scoulomb/music-streamer#cname-to-ddns-advanced

Advantage of this technique over view is that even for DNS resolution itself abd not only traffic we remain in LAN (gtm)!
And need Internet.