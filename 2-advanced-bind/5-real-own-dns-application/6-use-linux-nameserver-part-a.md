# Use linux nameserver: Part A - Deploy application in local network, configure a reverse NAT and dynamic DNS to access those applications externally

## Application deployment

We deploy for the example on a Ubuntu server machine
- A SSH server 
- A simple HTTP server
- A Jupyter notebook server

For now we assume firewall is disabled

````shell script
sudo ufw disable
````

### Deploy ssh server 

**Source**:
- https://doc.ubuntu-fr.org/ssh
- https://askubuntu.com/questions/1161579/ssh-server-cannot-be-found-even-though-installed

On the server
````shell script
sudo apt-get remove --purge openssh-server
sudo apt-get update
sudo apt-get install openssh-server
sudo systemctl start ssh
ip addr | grep eno1 # tp get the IP address or in SFR box at url http://192.168.1.1/network
````

On the client we can do

And curl on that machine or another in the LAN gives
<!-- tested with dell -->
````shell script
ssh sylvain@192.168.1.32
$ ssh sylvain@192.168.1.32
sylvain@192.168.1.32's password: 
Welcome to Ubuntu 20.04 LTS (GNU/Linux 5.4.0-52-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

 * Introducing autonomous high availability clustering for MicroK8s
   production environments! Super simple clustering, hardened Kubernetes,
   with automatic data store operations. A zero-ops HA K8s for anywhere.

     https://microk8s.io/high-availability

````

This will open a SSH connexion.

### Deploy a simple python server


https://docs.python.org/3/library/http.server.html

````shell script
ssh sylvain@192.168.1.32
python3 -m http.server 8080
````

And curl on that machine or another in the LAN gives
<!-- tested with dell -->

````shell script
$ curl 192.168.1.32:8080 | head -n 2
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   777  100   777    0     0   758k      0 --:--:-- --:--:-- --:--:--  758k
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>

````

### Deploy Jupyter 

Rater than using simple http server we could have used Jupyter.


#### Launch Jupyter

````
# on 192.168.1.32 (ssh not working with Jupyter)
pip3 install --upgrade pip
pip3 install jupyter
jupyter notebook 
````

But if doing only this notebook is not accessible via private IP and thus public IP.
We will have to give it as parameter the private IP 

````
jupyter notebook --ip 192.168.1.32 --port 8888
# or actually as discovered in Windows version
jupyter notebook --ip 0.0.0.0 --port 8888
````

**source**: https://stackoverflow.com/questions/39155953/exposing-python-jupyter-on-lan


To make it convenient I recommend to setup a password rather than using a token

````
jupyter notebook password
````

And curl on that machine or another in the LAN gives
<!-- tested with dell -->

````shell script
$ curl -L 192.168.1.32:8888 | head -n 4
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
<!DOCTYPE HTML>
100<html>
  6777
<head>
  100  6777    0     0   827k      0 --:--:-- --:--:-- --:--:--  827k
(23) Failed writing body

````


<details><summary>Note on bash kernel and VM</summary>
<p>

#### Note on bash kernel

To use bash kernel you have to setup it: https://github.com/takluyver/bash_kernel

````shell script
sudo systemd-resolve --flush-caches  
sudo pip install bash_kernel   # or pip3
python -m bash_kernel.install # or python3
````

For asciidoc generation, pandoc is needed unlike markdown.
We can generate via UI or do 

````shell script
jupyter nbconvert demo.ipynb --to markdown --output=demo-md
# if use jq do jq -m to remove color at export time
````

Note Jupyter can open a terminal access as SSH,.
When we will configure the NAT this can be convenient.


#### Note Jupyter on Archlinux VM on windows

``````shell script
sudo pacman -Syu # in particular if 404 error
sudo pacman -S jupyter-notebook
jupyter notebook password # or use token
jupyter notebook --ip 0.0.0.0 --port=8080
``````


Check you forwarded port 8080 to 8980 in VM. Note that ip must be all interface, `127.0.0.1` will work only inside the VM.
Check https://stackoverflow.com/questions/38545198/access-jupyter-notebook-running-on-vm.
We can also edit the configuration.

Open your navigator to ~~http://archlinux:8080/~~ http://127.0.0.1:8980.

We can also use private ip in 192 (given by box or ipconfig/ethernet adapter).

External access seems blocked (windows firewall?, I did not push windows + vm investigations)


</p>
</details>



## Configure a reverse NAT simple example

We can access deployed application on any device on the LAN from application server private IP address.
For instance `192.168.1.32`.

<!-- except policy on client -->

Our objective is to access those application from public internet (client not in same LAN).


### Configure router

For this we need to provide following NAT configuration in the router (SFR box):
It is in http://192.168.1.1/network/nat

````shell script
hp-ssh      TCP	Port	22      192.168.1.32    22
hp-server   TCP	Port	8080    192.168.1.32	8080
hp-jupyter  TCP	Port	8888    192.168.1.32	8888
````

We could change entry port when using public IP (forwarding, for instance `80` -> `8888`) 

### Test it

We can now use public IP.
It is visible here in the box configuration.

http://192.168.1.1/state/wan.

For instance it can be: `109.29.148.109`.

We will test it on a client with the two modes using public IP:
- connected to Wifi LAN
- connection to Wifi phone teetering with 4G.

Queries are
```shell script
ssh 109.29.148.109
curl -L 109.29.148.109:8080 | head -n 3
curl -L 109.29.148.109:8888 | head -n 3
```

All 3 were successful. Note private IP did not work with 4G.

<!-- use dell laptop --> 


**Source**: https://www.infraworld.fr/2014/09/30/routage-nat-et-redirection-de-port-sur-box-sfr/


Note that when using public IP with client in the LAN we go outside to come back inside for nothing.

## Configure a Dynamic DNS to abstract dynamic IP

In previous [example](#Test-it), we were using:
- box private IP: `192.168.1.x`
- box public IP: `109.x.y.z`.
Those IP are dynamic and can change.

Thus we can not provide it to a customer (internal or external)

To solve this issue we will configure a DynDNS.

Among provider, I decided to use noip: https://my.noip.com/#!/dynamic-dns

### Dynamic DNS for public IP with router configuration

It will provide a FQDN (here `scoulomb.ddns.net`) and update the IP dynamically
with the one of the box (when box ip/router change, it trigger a DNS entry update).

<!-- account is s****@gmail.com -->

For this dynamic update configure your router/box to link it to no-ip service (look for dynamic dns in the router configuration).
In my case I use a [NB6 SFR box (doc in French)](https://assistance.sfr.fr/internet-tel-fixe/box-nb6/activer-fonction-dyndns-box-nb6.html).

We go there : http://192.168.1.1/network/ddns ( Home > Réseau v4 > DynDNS)

In my case config is

```shell script
Service: no-ip.com
Nom utilisateur: s****@gmail.com
mdp: #
nom de domaine: scoulomb.ddns.net
```

For other router it is also possible: Cf. Netgear [doc](https://kb.netgear.com/23860/How-do-I-set-up-a-NETGEAR-Dynamic-DNS-account-on-my-NETGEAR-Nighthawk-router)

**Note**: noip proposes to downlaod a soft on your PC, but it would be useful for the private IP.
For box public IP update, it is managed by the router.

Now if we do:

````
sylvain@sylvain-hp:~/myDNS$ nslookup scoulomb.ddns.net 8.8.8.8
Server:		8.8.8.8
Address:	8.8.8.8#53

Non-authoritative answer:
Name:	scoulomb.ddns.net
Address: 109.29.148.109

``````

We find the box IP.

In box: http://192.168.1.1/state/wan ( Home > Etat > Internet)

It matches: `Adresse IP	109.29.148.109`.


And I can access Jupyter by doing:

[http://scoulomb.ddns.net:8888](http://scoulomb.ddns.net:8888)

Note you can update only one 1 IP with the router unlike the DUC below.

### Dynamic DNS for public IP with the DUC

If your router does not support no-ip/
You can use the DUC.

*Source*:
- https://my.noip.com/#!/dynamic-dns/duc
- https://www.noip.com/support/knowledgebase/installing-the-linux-dynamic-update-client-on-ubuntu/ (used that one)

#### Install 
```shell script
cd /usr/local/src/
sudo wget http://www.noip.com/client/linux/noip-duc-linux.tar.gz
sudo tar xf noip-duc-linux.tar.gz
cd noip-2.1.9-1/
make install
```

#### Configure 

Mote: you already did a configure after the install

Display the help

```shell script
cd /usr/local/src/noip-2.1.9-1/
cat README.FIRST | grep -A 14 -B 2 Options
sudo /usr/local/bin/noip2 -h
```

Show the config data

```shell script
sudo /usr/local/bin/noip2 -S
```

Configure and start

````shell script
sudo /usr/local/bin/noip2 -C 
sudo /usr/local/bin/noip2 
````

Note you can configure several no-ip FQDN with one machine unlike box.


### Dynamic DNS for private IP with the DUC

We can also use dynamic DNS for private IP.
Here the traffic would stay inside the LAN.
But we would need external for DNB resolution (DNS is a gtm and not a ltm).

To configure DUC to expose private IP we should use `-F` option to disable NAT at DUC level.
We also use additional option to pre-fill info.


```shell script
# kill no IP
sudo kill $(ps -aux | grep '/usr/local/bin/noip2'| awk '!/grep/' | awk {'print $2'})
# if do sudo /usr/local/bin/noip2 -C  you will get the PID

export NOIP_USER="@gmail.com"
export NOIP_PWD="xxxx
sudo /usr/local/bin/noip2 -C -F -u  $NOIP_USER -p $NOIP_PWD -I eno1 -U 1
sudo /usr/local/bin/noip2 -S
# launch it
sudo /usr/local/bin/noip2 
```

That way I can navigate to [http://ubuntu-privateip.ddns.net:8888](http://ubuntu-privateip.ddns.net:8888).

### Alternative to dynamic DNS only for private IP 

We can require box DHCP server to give a static IP for a given mac address.
For this get mac address

```
cat /sys/class/net/*/address
cat /sys/class/net/eno1/address
```

And provide this configuration here:
http://192.168.1.1/network/dhcp

We can then also configure router DNS to always point to that IP

http://192.168.1.1/network/dns

```shell script
192.168.1.32	hp.cbl # we need a domain
```

So that we can do inside the LAN

http://hp.cbl:8888

## Abstract dynamic DNS via a CNAME 

### Basic CNAME 

Then we could define a CNAME (in our Gandi Live DNS nameserver) for instance to abstract the dynamic DNS.

````
home 300 IN CNAME scoulomb.ddns.net.
````

So that we can access depending on the configured zone:

[http://home.coulombel.site](http://home.coulombel.site).
[http://home.coulombel.it](http://home.coulombel.it).

Here we use public IP which required a go outside to get inside when client is in the LAN.


### Could we use the DNS as switch 

So that if client device is plugged on same LAN as a server use private IP.
Otherwise use public IP.
This would avoid to send traffic trough public IP when inside the LAN (go outside to get inside when client is in the LAN).

#### First we should understand the resolution in details

If we have a look at resolution pattern here

```
$ nslookup home.coulombel.site
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
home.coulombel.site	canonical name = scoulomb.ddns.net.
Name:	scoulomb.ddns.net
Address: 109.29.148.109
```

1. Laptop get IP and default DNS by DHCP server contained in router : `127.0.0.53` 
Note that it is abstracted by Ubuntu systemd-resolve.
We can see it is the box by doing: `systemd-resolve --status` >  `Current DNS Server: 192.168.1.1`. (cf. [So question](https://stackoverflow.com/questions/50299241/ubuntu-18-04-server-how-to-check-dns-ip-server-setting-being-used)).
2. The DNS acquired is also embedded in the router
3. DNS resolution (gtm):
    1. DNS from router `127.0.0.53:53` -> Forward to DNS recursive SFR (Router DNS could also do the recursion). Those DNS are visible here: http://192.168.1.1/state/wan (`109.0.66.20`, `109.0.66.10`) and we can not change them. (**)	
    2. Recursion: home.coulombel.it/site [1] -> Gandi Live DNS [2] -> Box public IP `109.29.148.109` [3]
            1. recursive server ask `it/site` tld to find nameserver for coulombel.it/site via 173.246.100.253`NS` record 
            2. Answer is `ns-219-[a,b,c].gandi.net` [2] which is resolved to an IP `173.246.100.253`
            3. Recursive server asks machine with  IP `173.246.100.253` nameserver to resolve home.coulombel.it/site
            4. From record `home IN CNAME scoulomb.ddns.net.`
            5. It returns `scoulomb.ddns.net` which is resolved to Box public IP `109.29.148.109` [3]
            6. Thus the answer with Box public IP `109.29.148.109`
4. Box public IP `109.29.148.109`:<NAT application-port> -> NAT -> machine private IP `192.168.1.32`:`<application-port>


##### Note on resolution in details

- In step 1 we can find this IP in `/etc/resolve.conf`, and can edit it.
For example to target Google recursive DNS `8.8.8.8`.

To avoid override by network manager do:
**source**: ttps://askubuntu.com/questions/623940/network-manager-how-to-stop-nm-updating-etc-resolv-conf

One way to stop Network Manager from adding dns-servers to `/etc/resolv.conf` file is to do this: 

First open the nm conf file `/etc/NetworkManager/NetworkManager.conf`:

    sudo vim /etc/NetworkManager/NetworkManager.conf
And add this to the `[main]` section:

    dns=none
Save and exit.

Apply the conf `sudo service network-manager restart`, after manaual edit and laptop restart unchanged!
If remove `dns=none`, and restart service it is overriden (not olv version of Ubuntu does not use nm)

<!-- we can configure static ip on laptop to request dhcp server same IP which is different to the use-case where DHCP server binds a mac to an ip 
https://www.techrepublic.com/article/how-to-prevent-ubuntu-from-overwriting-etcresolv-conf/,
imo not needed to use static here
-->

To have this config performed automatically on device (and have it filled by network manager),
and not use DNS of router which forwards to SFR recursive server.
We could configure our own DHCP server, to provide a DNS of our choice. We will explore [this](6-use-linux-nameserver-part-c.md#configure-dhcp-server).

Ideally the box could allow to change the DNS it forward the traffic to but it is not allowed.

- Step 3.2.3 details.

````shell script
$ nslookup -type=A home.coulombel.site 173.246.100.253
Server:		173.246.100.253
Address:	173.246.100.253#53

home.coulombel.site	canonical name = scoulomb.ddns.net.`
````

`scoulomb.ddns.net` is resolved to box public IP `109.29.148.109` by following normal A resolution mechanism.
And Non static box ip is updated by no-ip (using box or the DUC).

- If tethering the connexion with phone using LAN Wifi and perform `systemd-resolve --status`, we have a DNS server at `192.168.43.1`.
Which is Android built-in server. 
If tethering the connexion with phone 4G and perform `systemd-resolve --status`, we will see same, we have a DNS server at `192.168.43.1`.
Then Android redirect to the box DNS (which redirect to provider DNS) when in Wifi and provider DNS in 4G
It is adding a layer of indirection.

<!-- guess could do same as first bulled for phone LAN -->

- By doing a long press on the connexion and we can configure the Android client to request DHCP server a specific IP address (not a static IP at DHCP server level) and an request a DNS.
To not be confused with what we did at DHCP server level [above](#alternative-to-dynamic-dns-only-for-private-ip).
In prefilled info it seems we can change phone nameserver to `8.8.8.8` when using wifi. 

#### Use DNS name to switch between public IP when outside the LAN and private IP when inside the LAN using router internal DNS

Previously there is no difference if client is in the same LAN as the application server or not.

But when we are inside the local network. We could improve the flow to not go outside to come back inside the LAN.
Thus not use the Box public IP + NAT and only rely on private IP.

For this purpose we can apply the trick used in section [alternative to dynamic DNS which waa working for private IP](#alternative-to-dynamic-dns-only-for-private-ip) configure entry in DNS from router.
Where we keep static IP but here
http://192.168.1.1/network/dns


we define:
```shell script
192.168.1.32	home.coulombel.it/site
```

That way local resolution in LAN is 

1. Laptop get IP and default DNS by DHCP server contained in router : `127.0.0.53`
2. The DNS acquired is also embedded in the router
3. DNS resolution (gtm):
    1. DNS from router `127.0.0.53:53` -> is authoritative for `home.coulombel.it/site`
    2. returns entry `192.168.1.32`
4. Machine private IP `192.168.1.32`:`<application-port>`

This is not a forwarding or recursion, but a definition of authoritative record in targeted DNS.
It is what we did when we [override google](../../1-basic-bind-lxa/p2-1-xx-questions.md#can-i-override-a-public-entry-in-my-local-dns)

If client is not in the LAN, we go through the previous resolution pattern (with some modif DNS from router can become dns from 4g)
Tp prove it we will do following experiment in a different laptop (equivalent to the Android phone):
- connected to wifi in the BOX LAN

```shell script
sylvain@sylvain-Latitude-D430:~$ nslookup home.coulombel.site
Server:		127.0.1.1
Address:	127.0.1.1#53

Name:	home.coulombel.site
Address: 192.168.1.32

sylvain@sylvain-Latitude-D430:~$ ping home.coulombel.site
PING home.coulombel.site (192.168.1.32) 56(84) bytes of data.
64 bytes from home.coulombel.site (192.168.1.32): icmp_seq=1 ttl=64 time=3.07 ms
64 bytes from home.coulombel.site (192.168.1.32): icmp_seq=2 ttl=64 time=7.60 ms
^C
--- home.coulombel.site ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 3.071/5.340/7.609/2.269 ms
```
- connected to phone tethering with 3G connection (WARN: if phone is in Wifi it will return private address) 
Note the authoritative answer.

````shell script
sylvain@sylvain-Latitude-D430:~$ nslookup home.coulombel.site
;; connection timed out; no servers could be reached

sylvain@sylvain-Latitude-D430:~$ nslookup home.coulombel.site
Server:		127.0.1.1
Address:	127.0.1.1#53

Non-authoritative answer:
home.coulombel.site	canonical name = scoulomb.ddns.net.
Name:	scoulomb.ddns.net
Address: 109.29.148.109

sylvain@sylvain-Latitude-D430:~$ ping home.coulombel.site
PING scoulomb.ddns.net (109.29.148.109) 56(84) bytes of data.
64 bytes from 109.148.29.109.rev.sfr.net (109.29.148.109): icmp_seq=1 ttl=55 time=64.9 ms
64 bytes from 109.148.29.109.rev.sfr.net (109.29.148.109): icmp_seq=2 ttl=55 time=68.9 ms
64 bytes from 109.148.29.109.rev.sfr.net (109.29.148.109): icmp_seq=3 ttl=55 time=80.1 ms
^C
--- scoulomb.ddns.net ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 64.931/71.333/80.126/6.436 ms
sylvain@sylvain-Latitude-D430:~$ date
lundi 26 octobre 2020, 23:06:20 (UTC+0100)
````

- connected to phone tethering with Wifi connection 

It returns `192.168.1.32` as expected.
I tried to change DNS server on the phone as suggested here:
[Note on resolution in details](#note-on-resolution-in-details). It does not have effect and use DNS in the gateway.
<!-- same with terminal emulator ping -->

<!-- there was some issue with this test on hp machine but on dell switch from one to another worked like a charm => OK 
Doing systemctl status systemd-resolved.service
Using degraded feature set (UDP) for DNS server 192.168.1.1.

sylvain@sylvain-hp:~$ nslookup home.coulombel.site 192.168.1.1
Server:		192.168.1.1
Address:	192.168.1.1#53

Name:	home.coulombel.site
Address: 192.168.1.32
home.coulombel.site	canonical name = scoulomb.ddns.net.

sylvain@sylvain-hp:~$ nslookup home.coulombel.site
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
home.coulombel.site	canonical name = scoulomb.ddns.net.
Name:	scoulomb.ddns.net
Address: 109.29.148.109

From https://ubuntuforums.org/showthread.php?t=2371249
It is due to old config, I wont go beyond and consider it is working
And also the fact we query from the machine own DNS.
-->

I also tested with Android app Terminal Emulator (https://github.com/jackpal/Android-Terminal-Emulator) with ping using wifi/4G and switch was done which confirms the approach.

This is exactly what we want.
DNS can perform the switch with public and private IP.

<!-- glue not need as ddns.net used and not coulombel.it in it tld OK-->


We will be back on this concept in next [section b](6-use-linux-nameserver-part-b.md#add-record-for-application-deployed-behind-the-box).


<!--
https://lafibre.info/sfr-espace-technique/changer-les-dns-sfr-sur-box-nb6v/
https://fr.wikipedia.org/wiki/Dnsmasq#:~:text=Dnsmasq%20est%20un%20serveur%20l%C3%A9ger,service%20DNS%20d'Internet).
-->


### Firewall config

I will add a firewall 
https://linuxize.com/post/how-to-disable-firewall-on-ubuntu-18-04/

## We can add a firewall

Reference:

- https://www.digitalocean.com/community/questions/how-to-reset-the-firewall-on-ubuntu
- https://help.ubuntu.com/community/UFW#Allow_Access
````
sudo ufw --force reset
sudo ufw enable
sudo ufw default deny incoming
````

After machine and jupyter restart (for firewall to work) access is not working anymore via public IP (`scoulomb.ddns.net`).
Access via `192.168.1.32:8888` is working from machine when jupyter started but not from another machine.


We need to add rules

```
sudo ufw allow from any to any port 8080
sudo ufw allow from any to any port 8888
sudo ufw allow from any to any port 22
```

By doing this I could access via `192.168.1.32:8888` from another machine.
`http://scoulomb.ddns.net/tree?` is also back.

Apply this to DNS in [part B](6-use-linux-nameserver-part-b.md).