# Others

## Use split horizon rather than DNS override

Rather than using a DNS override. 
We could use split DNS mechanism.
If the query is coming from the LAN (private IP) we answer with application server's machine private IP and answer with public IP if coming from external IP.

For this We would use DNS horizon split/view feature.

To target always my DNS instead of SFR,  we would disable SFR dhcp server and configure mine, to point to my DNS.

See [part c to configure DHCP server](6-use-linux-nameserver-part-c.md#configure-dhcp-server).

We will not implement it.

## SFR service button

If service button is broken we can access via:
u/p: admin / WPA KEY

**Source**: https://assistance.sfr.fr/internet-tel-fixe/box-nb4/configurer-acces-interface-web-administration.html

Also we can not expose admin via NAT :(. `192.168.1.1` is invalid.

## CURISOITY 

- We could expose hue bridge via 
- android app for DNS does not use network DNS
- If several A record it is doing [round-robin (A != AAAA)](../../3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md#we-can-also-create-several-a-with-the-same-name-and-different-ip)
- [2 CNAME with same name](../../3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md#we-can-not-have-2-cname-with-the-same-name-in-infoblox-unlike-some-other-providers)

## Corp

Some corp setup where we are part of local network, while we have VPN etc + VM (https://www.virtualbox.org/manual/ch06.html#networkingmodes, use NAT) out of scope.
<!-- can access other machine via dns name. useful for jupyter -->

<!-- this is concluded and next.md is removed as done -->



## we can override with sfr router dns but can use host file

````shell script
➤ cat /etc/hosts
# Static table lookup for hostnames.
# See hosts(5) for details.
127.0.0.1       host.minikube.internal
10.0.2.15       control-plane.minikube.internal
0.0.0.0         coulombel.it

[16:46] ~
➤ ping coulombel.it
PING coulombel.it (127.0.0.1) 56(84) bytes of data.
64 bytes from host.minikube.internal (127.0.0.1): icmp_seq=1 ttl=64 time=0.039 ms
64 bytes from host.minikube.internal (127.0.0.1): icmp_seq=2 ttl=64 time=0.085 ms
^C
--- coulombel.it ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1016ms
rtt min/avg/max/mdev = 0.039/0.062/0.085/0.023 ms
[16:46] ~
➤ curl coulombel.it
curl: (7) Failed to connect to coulombel.it port 80: Connection refused
[16:46] ~
````


See https://vitux.com/linux-hosts-file/

<!-- skip normal ip -->

## Nating

1. nat map: (Single ip public:  `k` port) -> (`k` ip prive : `n` port),
2. le port fowarding vm   (host OS localhost:  `k` port) -> (` Guest OS localhost : `n` port) 
3. et sur docker   (machine localhost:  `k` port) -> (` docker localhost : `n` port) (or kubernetes port forwarding cf. https://github.com/scoulomb/myk8s/blob/master/Deployment/advanced/container-port.md#without-containerport
, nodeport, lb service, or ingress to service)

So NAT has more dimension has can take any IP on private network. 
We can combine 1+2+3, in our lab we did 1+3.

Synlogy can also do NAT: https://www.synology.com/fr-fr/knowledgebase/DSM/help/DSM/AdminCenter/connection_routerconf

<!-- OK -->

## Explo future?

- DNS over https 
- DNSSEc
- See also https://www.infoblox.com/dns-security-resource-center/dns-security-faq/is-dns-tcp-or-udp-port-53
<!--
(in my implem in kube I have AAAA, but below 512 and from here: https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/4-about-the-standard/7-valid-fqdn-2-length.md, AAAA alone seems not included)
-->