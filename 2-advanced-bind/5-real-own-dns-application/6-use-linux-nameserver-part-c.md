# Complementary comments

## DNS resolution is also made internally when on same LAN and using router DNS

In
- [part A](6-use-linux-nameserver-part-a.md#use-dns-name-to-switch) 
- [part B](6-use-linux-nameserver-part-b.md#use-dns-name-to-switch)

We have used DNS name to switch between public IP when outside the LAN and private IP when inside the LAN.
It avoids traffic to go outside when in same LAN,

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

When we will use the [view](link to add), if traffic is kept inside, resolution via TLD needs Internet access.

Note if we unplug and restart the box:
http://192.168.1.1/maintenance/system

we have a preservation of private IP by DHCP server.
Public IP may me kept (here it is DHCP of ISP)

## Configure DHCP server

Before read those 2 sections:
- [Resolution details](6-use-linux-nameserver-part-a.md#first-we-should-understand-the-resolution-in-details)'
- [Note on resolution conf](6-use-linux-nameserver-part-a.md#note-on-resolv-conf)

We follow that procedure to configure our DHCP server: https://ubuntu.com/server/docs/network-dhcp

### Install
```shell script
sudo apt install isc-dhcp-server
```

NOTE: dhcpd’s messages are being sent to syslog. Look there for diagnostics messages.

### Configuration

change the default configuration by editing `/etc/dhcp/dhcpd.conf` to suit your needs and particular configuration.


sudo mv  /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.original


````shell script
sudo su
cat <<EOF >  /etc/dhcp/dhcpd.conf 
# minimal sample /etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;

subnet 192.168.1.0 netmask 255.255.255.0 {
 range 192.168.1.150 192.168.1.200;
 option routers 192.168.1.1;
 # https://en.wikipedia.org/wiki/Public_recursive_name_server
 option domain-name-servers 8.8.8.8, 208.67.222.22;
 option domain-name "sylvain.coulombel.it";
}
EOF
exit
````


This will result in the DHCP server giving clients an IP address from the range 192.168.1.150-192.168.1.200. 
It will lease an IP address for 600 seconds if the client doesn’t ask for a specific time frame. 
Otherwise the maximum (allowed) lease will be 7200 seconds. 
The server will also “advise” the client to use 192.168.1.1 as the default-gateway and
8.8.8.8 and 208.67.222.22 as its DNS servers.

You also may need to edit `/etc/default/isc-dhcp-server` to specify the interfaces dhcpd should listen to.

Find ethernet interface for instance (ifconfig). In my case it is eno1.

Thus

```shell script
INTERFACESv4="eno1"
```

After changing the config files you have to restart the dhcpd service:


```shell script
sudo systemctl restart isc-dhcp-server.service
```


### Tests DHCP

- In `192.168.1.1/network/dhcp` ensure router DHCP server is activated with a range from 20 to 100
- And stop ours `sudo systemctl stop isc-dhcp-server.service`

- On laptop different (dell d430) from where DHCP server is deployed (hp) do

````shell script
sudo service network-manager restart
ifconfig | grep -A 4 wlan0
nmcli dev show | grep DNS
````

Output is

```shell script
sylvain@sylvain-Latitude-D430:~$ ifconfig | grep -A 4 wlan0
wlan0     Link encap:Ethernet  HWaddr 00:1f:e1:cc:95:2c  
          inet addr:192.168.1.30  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: 2a02:8434:595:ca01:8e6:a744:4081:80d/64 Scope:Global
          inet6 addr: 2a02:8434:595:ca01:21f:e1ff:fecc:952c/64 Scope:Global
          inet6 addr: fe80::21f:e1ff:fecc:952c/64 Scope:Link

sylvain@sylvain-Latitude-D430:~$ nmcli dev show | grep DNS
IP4.DNS[1]:                             192.168.1.1
IP6.DNS[1]:                             2a02:8434:595:ca01::1
```

We can see DNS is the one of the box



- Stop box DHCP and start our `sudo systemctl start isc-dhcp-server.service`
- Repeat same operations,

Output is 

```shell script

sylvain@sylvain-Latitude-D430:~$ ifconfig | grep -A 4 wlan0
wlan0     Link encap:Ethernet  HWaddr 00:1f:e1:cc:95:2c  
          inet addr:192.168.1.150  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: 2a02:8434:595:ca01:8e6:a744:4081:80d/64 Scope:Global
          inet6 addr: 2a02:8434:595:ca01:21f:e1ff:fecc:952c/64 Scope:Global
          inet6 addr: fe80::21f:e1ff:fecc:952c/64 Scope:Link


sylvain@sylvain-Latitude-D430:~$ nmcli dev show | grep DNS
IP4.DNS[1]:                             8.8.8.8
IP4.DNS[2]:                             208.67.222.22
IP6.DNS[1]:                             2a02:8434:595:ca01::1
```

We are now pointing to Google DNS and Open DNS as specified in our DHCP configuration.
Note also the IP in the new range (`192.168,150`).

We can also check DHCP server logs

```shell script
sylvain@sylvain-hp:~$ sudo systemctl status isc-dhcp-server.service
● isc-dhcp-server.service - ISC DHCP IPv4 server
     Loaded: loaded (/lib/systemd/system/isc-dhcp-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2020-10-29 11:45:06 CET; 9min ago
       Docs: man:dhcpd(8)
   Main PID: 16708 (dhcpd)
      Tasks: 4 (limit: 9357)
     Memory: 5.0M
     CGroup: /system.slice/isc-dhcp-server.service
             └─16708 dhcpd -user dhcpd -group dhcpd -f -4 -pf /run/dhcp-server/dhcpd.pid -cf /etc/dhcp/dhcpd.conf
[...]
oct. 29 11:51:03 sylvain-hp dhcpd[16708]: DHCPREQUEST for 192.168.1.150 from <wifi mac> (sylvain-Latitude-D430) via eno1
oct. 29 11:51:03 sylvain-hp dhcpd[16708]: DHCPACK on 192.168.1.150 to <wifi mac> (sylvain-Latitude-D430) via eno1
```

We can see we have ip6 configuration it is coming from DHCP server v6 which is still activated on the box unlike v4.
If v4 DHCP non started in box and hp we will see no ipv4 address.

We can wonder what happens if we have 2 DHCP server in same LAN, here is the answer:
https://serverfault.com/questions/904055/how-does-a-client-choose-between-two-dhcp-servers-in-the-same-network

> DHCP is first-come, first-serve. You should not have two competing DHCP servers on the same network without some form of fail-over or HA between them, otherwise you run the risk of having duplicate IP's on the same network.

This reminds me [Phoenix project book](https://itrevolution.com/wp-content/uploads/files/PhoenixProjectExcerpt.pdf) (chapter 6, page 79)

Note `/etc/resolv.conf` outputs nameserver but abstracted IP as explained here [Resolution details](6-use-linux-nameserver-part-a.md#first-we-should-understand-the-resolution-in-details)'.
Same principle as `systemd-resolve`, whereas when editing it manually (and avoids override), we would put `8.8.8.8` directly there.


<!-- win corp
ip address taken from my dhcp server but ip in router
see logs in dhcp 
see win cmd => ipconfig /all, wireless lan.
vagrant => nmcli not present, systemd-resolve --status => usual ip in 10 which same in cat /etc/resolv.conf
totally weird
see in next -->

### Set initial config :)

- stop our DHCP `sudo systemctl stop isc-dhcp-server.service`
- In `192.168.1.1/network/dhcp` ensure router DHCP server is activated with a range from 20 to 100
