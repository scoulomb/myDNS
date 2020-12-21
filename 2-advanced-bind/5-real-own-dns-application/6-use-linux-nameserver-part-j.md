# NAT, IPv4 and DNS, and move to IPv6

## IPV4: reminder we used NAT  

When we use IPV4, our internal IP was `192.168.1.32`.
While external IPV4 was `109.29.148.109`.

We were using NAT rules like

````shell script
Nom 	Protocole 	Type 	Ports externes 	IP de destination 	Ports de destination
9443 	TCP 	Port 	9443 	192.168.1.32 	9443
````

we had a dymamic DNS pointing to `109.29.148.109`.
See [part b, CNAME](6-use-linux-nameserver-part-b.md#achieve-with-our-own-dns-the-same-service-performed-by-gandi).

In [part b, use DNS name to switch](6-use-linux-nameserver-part-b.md#use-dns-name-to-switch), we had seen how to switch between public IP and private IP using DNS.
And in [part c](6-use-linux-nameserver-part-c.md), we saw how to use router DNS to also make the resolution internally.

## Experience to show internal traffic can use public IP

I made following experience:

- We have `9443` NAT rule
- We deploy the previous script version made in [part h](6-use-linux-nameserver-part-h.md#step-2-configure-the-server-to-use-https)

````shell script
cd ./2-advanced-bind/5-real-own-dns-application/6-part-h-use-certificates-signed-by-ca
sudo python3 http_server.py
````

- Access from phone on same LAN (connected to local wifi) by using `https` (`http` will not work and we have no redirection in place)

<! -- (do not use windows as corp) -->

- [https://109.29.148.109:9443](https://109.29.148.109:9443)
- [https://192.168.1.32:9443](https://192.168.1.32:9443)

working (we have certificate name mismatch warning).

In server logs

````shell script
192.168.1.1 - - [21/Dec/2020 15:49:40] "GET / HTTP/1.1" 200 - => when public IP is used
192.168.1.22 - - [21/Dec/2020 15:49:24] "GET / HTTP/1.1" 200 - => when private IP is used
````

unplug the Box Internet wire and we can see it is still working locally.

For same reason SSH is working when on same machine:

````shell script
# From vagrant (even if internal it is external as corpo)
➤ ssh sylvain@109.29.148.109
sylvain@109.29.148.109's password:
Welcome to Ubuntu 20.04 LTS (GNU/Linux 5.4.0-58-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

 * Introducing self-healing high availability clusters in MicroK8s.
   Simple, hardened, Kubernetes for production, from RaspberryPi to DC.

     https://microk8s.io/high-availability

310 updates can be installed immediately.
0 of these updates are security updates.
To see these additional updates run: apt list --upgradable

Your Hardware Enablement Stack (HWE) is supported until April 2025.
Last login: Sat Dec 19 20:49:21 2020 from 192.168.1.1
````
Unplug Internet wire, and do 

````shell script
sylvain@sylvain-hp:~$ ssh sylvain@109.29.148.109
The authenticity of host '109.29.148.109 (109.29.148.109)' can't be established.
ECDSA key fingerprint is SHA256:agqwrddl9FkED7kQxP/wiROg6I/gtnGSNc41oo5SesI.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '109.29.148.109' (ECDSA) to the list of known hosts.
sylvain@109.29.148.109's password:
Welcome to Ubuntu 20.04 LTS (GNU/Linux 5.4.0-58-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

 * Introducing self-healing high availability clusters in MicroK8s.
   Simple, hardened, Kubernetes for production, from RaspberryPi to DC.

     https://microk8s.io/high-availability

310 updates can be installed immediately.
0 of these updates are security updates.
To see these additional updates run: apt list --upgradable

Your Hardware Enablement Stack (HWE) is supported until April 2025.
Last login: Sun Dec 20 18:49:20 2020 from 192.168.1.1
````

where `ssh sylvain@192.168.1.32` give same output.


So router can route internally inside the lan with public IP, so we could always use the public IP.
But what we show before is still a good practise IMO.

## Can we make DNS resolution internally

For the resolution to work internally (internal DNS) with public IP we could think to use [internal DNS](http://192.168.1.1/network/dns).
 
 ````shell script
3 	109.29.148.109 	home.coulombel.it 
````

But if we go on phone in same LAN and do

````shell script
- [https://109.29.148.109:9443](https://109.29.148.109:9443) => OK with cert warning
- [https://home.coulombel.it:9443](https://home.coulombel.it:9443) => KO
````
Then clean: remove DNS entry.

So not working

## Can we cheat on certificate 

Add this entry to [internal DNS](http://192.168.1.1/network/dns).

````shell script
3 	192.168.1.32  home.coulombel.it 
````

We reboot the box, add the wire, reboot  phone to flush entry (and if not sufficient use chrome if used firefox before on the phone).
Ensure phone is connected to local wifi.

- [https://192.168.1.32:9443](https://192.168.1.32:9443) => OK with cert warning, `ERR_CERT_COMMMON_NAME_INVALID`
- [https://home.coulombel.it:9443](https://home.coulombel.it:9443) => OK <!-- retested 21 dec 2020, 15:45 OK -->

It is interesting because if the used DNS (the one configured by DHCP => `etc/resolv.conf`), has the capability to have entry and then forward to recursive (this whayt SFR is doing).
We can override DNS entry and cheat on certificate.

## DNS entry override

In previous section DNS server was off. If I start DNS server 

````shell script
./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
````

and do 

````shell script
nslookup -type=A home.coulombel.it
nslookup -type=A home.coulombel.it 8.8.8.8
````

As the DNS is  `127.0.0.53` it is SFR box DNS which is configured by SFR Box DHCP.
This SFR box DNS has internal entry and then forward to DNS recursive server, which targets my authoritative DNS.

Output is 

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ nslookup -type=A home.coulombel.it
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   home.coulombel.it
Address: 192.168.1.32

sylvain@sylvain-hp:~/myDNS_hp$ nslookup -type=A home.coulombel.it 8.8.8.8
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
home.coulombel.it       canonical name = scoulomb.ddns.net.
Name:   scoulomb.ddns.net
Address: 109.29.148.109
````

- In SFR DNS answer, entry in authoritative DNS in Kubernetes was overridden
- Google DNS go to our authoritative DNS in Kubernetes

In output above we can see override.

Here it was A and CNAME (which can not conflict, see [here](../../3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md).

What about 2 A?

In SFR DNS:http://192.168.1.1/network/dns

````shell script
4 	43.43.43.43 	toto.coulombel.it
````

and in our authoritative nameserver:

````shell script
echo 'toto IN A 42.42.42.42' >> ./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db
./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
````

Then 

````shell script
nslookup -type=A toto.coulombel.it
nslookup -type=A toto.coulombel.it 8.8.8.8
````

output is 

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ nslookup -type=A toto.coulombel.it
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   toto.coulombel.it
Address: 43.43.43.43

sylvain@sylvain-hp:~/myDNS_hp$ nslookup -type=A toto.coulombel.it 8.8.8.8
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   toto.coulombel.it
Address: 42.42.42.42
````

It is the same behavior.

## We were using NAT, dyndns and IPv4, an alternative is to use ipv6


### Concept

In Box: http://192.168.1.1/networkv6

We can see assigned IPV6 address

````shell script
# 	Adresse MAC 	Adresse IPv6 	
1 	aa:aa:aa:aa:aa:aa 	xxxx:xxxx:xxxx:xxxx:uuuu:uuuu:uuuu:uuuu 
2 	bb:bb:bb:bb:bb:bb 	xxxx:xxxx:xxxx:xxxx:vvvv:vvvv:vvvv:vvvv 
````

A part of IPv6 address is unique and assigned to me  `xxxx:xxxx:xxxx:xxxx`.
As second part `:uuuu:uuuu:uuuu:uuuu` and `vvvv:vvvv:vvvv:vvvv` is computed from the mac address.

See:
- https://ben.akrin.com/?p=1347
- http://www.sput.nl/internet/ipv6/ll-mac.html

It seems SFR algorithm is a bit different.

As IP space is wider: NAT is not needed, and same for DynDNS in theory

(but it seems SFR could changes destination IP of device after box reboot?)

### Adapt to use v6 and test with localhost

Client and server on same machine.

As a reminder localhost is 

````shell script
sylvain@sylvain-hp:~$ nslookup localhost
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   localhost
Address: 127.0.0.1
Name:   localhost
Address: ::1
````

The python application needs to be adapted to work in IPv6.
See [SO question](https://stackoverflow.com/questions/25817848/python-3-does-http-server-support-ipv6) for more details.

We adapted [httpS server](6-part-j-use-ipv6/http_server.py) from [part h](6-part-h-use-certificates-signed-by-ca/http_server.py) to work in IPV6 and deploy it:
It exposes port 9443.

````shell script
cd ./2-advanced-bind/5-real-own-dns-application/6-part-j-use-ipv6
sudo python3 http_server.py
````

At the same time I will deploy a IPv4 HTTP server on port 8080 (port 8080 is natted).

````shell script
sudo python3 -m http.server 8080
````

Note ipv4 and ipv6 shares same port range.

````shell script
sylvain@sylvain-hp:~$ sudo python3 -m http.server 9443
[...]
  File "/usr/lib/python3.8/socketserver.py", line 466, in server_bind
    self.socket.bind(self.server_address)
OSError: [Errno 98] Address already in use
````

So we can curl our v6 server, and v4

````shell script
curl --insecure -g -6 https://[::1]:9443 | head -n 4
curl --insecure -g -6 https://localhost:9443 | head -n 4
curl --insecure http://localhost:8080 | head -n 4
````

output is 

````shell script
sylvain@sylvain-hp:~$ curl --insecure -g -6 https://[::1]:9443 | head -n 4
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   350  100   350    0     0  21875      0 --:--:-- --:--:-- --:--:-- 21875
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
sylvain@sylvain-hp:~$ curl --insecure -g -6 https://localhost:9443 | head -n 4
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   350  100   350    0     0  21875      0 --:--:-- --:--:-- --:--:-- 21875
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
sylvain@sylvain-hp:~$ curl --insecure http://localhost:8080 | head -n 4
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
1<html>
0<head>
0 <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
 5906  100  5906    0     0   720k      0 --:--:-- --:--:-- --:--:--  720k
(23) Failed writing body
sylvain@sylvain-hp:~$
````

Actually ipv6 application will also receive ipv4 but reciprocal is wrong.
As a proof:

````shell script
curl --insecure -g -6 https://localhost:9443 | head -n 4
curl --insecure -g -6 https://[::1]:8080 | head -n 4
````

output is 

````shell script
sylvain@sylvain-hp:~$ curl --insecure -g -6 https://localhost:9443 | head -n 4
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   350  100   350    0     0  20588      0 --:--:-- --:--:-- --:--:-- 20588
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
sylvain@sylvain-hp:~$ curl --insecure -g -6 https://[::1]:8080 | head -n 4
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
curl: (7) Failed to connect to ::1 port 8080: Connection refused
````

### Use ipv6 address from the box

#### In LAN

Using IPv6 given here: http://192.168.1.1/networkv6

````shell script
curl --insecure -g -6 https://[2a02:8434:595:ca01:2132:de66:c3e1:269]:9443
````

output is

````shell script
sylvain@sylvain-hp:~$ curl --insecure -g -6 https://[2a02:8434:595:ca01:2132:de66:c3e1:269]:9443 | head -n 4
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   350  100   350    0     0  23333      0 --:--:-- --:--:-- --:--:-- 25000
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
````


Using phone with Wifi in same network it is working (tips send ip hyperlink via gmail).
<!-- corp blocks ERR_NETWORK_ACCESS_DENIED -->

#### via 4g (not same LAN)

If going via 4G it does not work.
We need to activate it in firewall: http://192.168.1.1/networkv6/firewall?

````shell script
9443-fw 	* 	TCP 	Port 	9443 	2a02:8434:595:ca01:2132:de66:c3e1:269 
````

But it still does not work because 4G operator (SFR) seems to not support this IPv6 address.
More here: https://www.echosdunet.net/breve/la-disponibilite-de-lipv6-sameliore-sauf-chez-sfr

#### Via external VM 

 I took a katacoda console: https://www.katacoda.com/openshift/courses/subsystems/container-internals-lab-2-0-part-1

````shell script
$ curl --insecure -g -6 https://109.29.148.109:9443 | head -n 4
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   350  100   350    0     0   1102      0 --:--:-- --:--:-- --:--:--  1107
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
$ curl --insecure -g -6 https://[2a02:8434:595:ca01:2132:de66:c3e1:269]:9443
curl: (7) Failed to connect to 2a02:8434:595:ca01:2132:de66:c3e1:269: Network is unreachable
````

We can see it works via ipv4 (NAT) but not ipv6 (ipv6 is also not supported there).

### Configure DNS for ipv6 usage

From previous observations, ipv6 not working when using 4g.
And for DNS resolution to work via tld we have to be connected to internet.

We will test ipv6 and DNS behavior.

Below:

- We remove also in SFR DNS, any entry matching `home.coulombel.it`
- We add ipv6 entry for `home.coulombel.it`

```shell script
ssh sylvain@109.29.148.109
cd /path/to/repo
sudo chmod 777 ./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db
# we remove CNAME home.coulombel.it, as we can ot have a A and CNAME with same name, oterwise error. Validatio would fail, see https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md
sed -i '/^home/d' ./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db
echo 'home IN AAAA 2a02:8434:595:ca01:2132:de66:c3e1:269' >> ./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db
# Restart for change to take effect
./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
```

So that 

````shell script
nslookup home.coulombel.it 8.8.8.8 # we have ipv6 as not cached
nslookup home.coulombel.it # all record still in the cache, we have to wait
````

output is 

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ nslookup home.coulombel.it 8.8.8.8
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   home.coulombel.it
Address: 2a02:8434:595:ca01:2132:de66:c3e1:269

sylvain@sylvain-hp:~/myDNS_hp$ nslookup home.coulombel.it
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
home.coulombel.it       canonical name = scoulomb.ddns.net.
Name:   scoulomb.ddns.net
Address: 109.29.148.109
````

After a while it is updated

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ nslookup home.coulombel.it
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   home.coulombel.it
Address: 2a02:8434:595:ca01:2132:de66:c3e1:269
````

So we can test on phone with wifi and 4G. Result is:

````shell script
https://home.coulombel.it:9443 # wifi ->working
https://home.coulombel.it:9443 # 4g -> Not working as explained before, 4g can not use ipv6
````

I will add ipv4 address (not via a CNAME) in DNS

````shell script
echo 'home IN A 109.29.148.109' >> ./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db
./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
````


output of `nslookup home.coulombel.it`

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ nslookup home.coulombel.it
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   home.coulombel.it
Address: 109.29.148.109
Name:   home.coulombel.it
Address: 2a02:8434:595:ca01:2132:de66:c3e1:269
````

then on phone with wifi and 4g, repeating same experience both are working.

````shell script
https://home.coulombel.it:9443 # wifi -> was able to use ipv6 
https://home.coulombel.it:9443 # 4g -> could not use ipv6 and fallback to ipv4
````

Here are server output as a proof 

````shell script
2a02:8434:595:ca01:8946:c570:750b:3a84 - - [21/Dec/2020 20:38:02] "GET / HTTP/1.1" 200 -
::ffff:81.185.165.187 - - [21/Dec/2020 20:40:06] "GET / HTTP/1.1" 200 -
````

See https://serverfault.com/questions/824803/make-firefox-and-other-clients-prefer-ipv6


## Ipv6 and other app 

- ssh: https://superuser.com/questions/236993/how-to-ssh-to-a-ipv6-ubuntu-in-a-lan
- vlc: https://wiki.videolan.org/Documentation:Streaming_HowTo/Streaming_over_IPv6/

<!-- all this document is concluded and clear - 21/12/2020 stop -->
