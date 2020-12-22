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

Some corp setup where we are part of local network, while we have VPN etc + VM out of scope.
<!-- can access other machine via dns name. useful for jupyter -->

<!-- this is concluded and next.md is removed as done -->



