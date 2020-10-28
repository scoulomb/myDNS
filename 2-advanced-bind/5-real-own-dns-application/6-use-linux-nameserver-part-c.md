# Complementary comments

## DNS resolution is also made internally when on same LAN and using router DNS

In
- [part A](6-use-linux-nameserver-part-b.md#use-dns-name-to-switch-between-public-ip-when-outside-the-lan-and-private-ip-when-inside-the-lan) 
- [part B](6-use-linux-nameserver-part-b.md#use-dns-name-to-switch-between-public-ip-when-outside-the-lan-and-private-ip-when-inside-the-lan)

We have used DNS name to switch between public IP when outside the LAN and private IP when inside the LAN.
It avoids traffic to go outisde when in same LAN,

Note that the option to use box nameserver enables to also stay in the LAN for DNS resolution (gtm).

For example starting from part B.
Keep DNS entry in the box: `home.coulombel.it`

- Do a `ns lookup home.coulombel.it` (with DNS from DHCP, default) from another machine as DNS with the LAN and box connected to Internet

<!--
Given issue with 192.168.1.32
Search part A / there was some issue with this test on hp machine 
-->
=> it outputs private IP

- Remove DNS entry in the box
`192.168.1.32	home.coulombel.site`
=> It outputs public IP

- Unplug wire between box and phone plug (Internet is cut a box level). It is yellow wire.
=> it outputs 
`;; connection timed out`

It has to perform resolution outside

- Adding the record back output private IP

When we will use the view, if traffic is kept inside, resolution via TLD needs Internet access.

Note if we unplug and restart the box:
http://192.168.1.1/maintenance/system

we have a preservation of private IP by DHCP server.
Public IP may me kept (here it is DHCP of ISP)

## Configure DHCP server

See [here](6-use-linux-nameserver-part-a.md#note-on-resolution-in-details)