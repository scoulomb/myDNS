# Use linux nameserver via NAT - part B

## Apply this to the DNS !

From lesson learnt in [part A](6-use-linux-nameserver-part-a.md).
We will modify IT TLD (ns record) to target our own DNS (we could have also delegated a subzone).
 
Our own DNS will be deployed as a container and orchestrated by [Kubernetes in VM deployed with Vagrant](https://github.com/scoulomb/myk8s/blob/master/Setup/ArchDevVM/archlinux-dev-vm-with-minikube.md).

As a results we will have seen 3 ways to deploy a DNS:
- DNS on Docker in bare metal/VM (which can be in the cloud) (example here)
- Infoblox on premise or deployed in the cloud
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

We can see it is working as an external DNS from this output using public IP via ddns

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
[I AM HERE]

### Configure the registrar to target the DNS via the DynDNS
(if too long will use suddomain stop there)

As Gandi requires to have 2 NS record, I created a second record for training purpose pointing to Box IP.
https://my.noip.com/#!/dynamic-dns
Note this record is not updated automatically and pointing to same nameserver (in a real environment it should be another one). 

I will then switch to my NS record in gandi: 
https://admin.gandi.net/domain/69ba17f6-d4b2-11ea-8b42-00163e8fd4b8/coulombel.it/nameservers

So that rather than doing 

````
nslookup scoulomb.coulombel.it scoulomb.ddns.net
````
As registrar is configured I can do

````
nslookup scoulomb.coulombel.it 8.8.8.8
````

Then test with dig 


And can access guthub with owb dns


Side node:
- could show this demo via Jupyter bash 
- could prepare a DNS presentation with this using Jupyter (or MST in Ubuntu)

<!-- not explored dns in ipconfig
And possibility to configure a DNS in box itself, how to change SFR DNS -->
