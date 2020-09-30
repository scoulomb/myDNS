# DNS forwarding

## Idea

We will

- Deploy a first DNS pod with bind in k8s cluster which the one done in section [bind in docker and kubernetes](../1-bind-in-docker-and-kubernetes).
- Deploy a second DNS pod which forwards query to the first DNS pod. 
 
## Reset env

```shell script
sudo su 
alias k='kubectl'
kubectl delete deployment --all
kubectl delete po --all --force --grace-period=0
kubectl delete svc --all 
```

## Deploy bind server from section 1

```shell script
cd dev/myDNS/2-advanced-bind/2-bind-views/docker-bind-dns
sudo docker build . -f dns-ubuntu.Dockerfile -t dns-ubuntu-1
kubectl run ubuntu-dns-1 --image=dns-ubuntu-1 --restart=Never --image-pull-policy=Never -- /bin/sh -c "systemctl start named;systemctl enable named;sleep 3600"
```


We will also expose this DNS pod with a service:

```shell script
kubectl expose pod ubuntu-dns-1 --port 53 --protocol=UDP
```

and make a lookup from the node using the service as done [here](../1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md#target-dns-from-the-node).

```shell script
DNS_1_SVC_CLUSTER_IP=$(kubectl get svc ubuntu-dns-1 -o jsonpath={'.spec.clusterIP'})
nslookup scoulomb.mylabserver.com $DNS_1_SVC_CLUSTER_IP
```

And we have:

```shell script
[root@archlinux docker-bind-dns]# nslookup scoulomb.mylabserver.com $DNS_1_SVC_CLUSTER_IP
Server:         10.102.77.148
Address:        10.102.77.148#53

Name:   scoulomb.mylabserver.com
Address: 42.42.42.42
```

## Deploy bind forwarding DNS

Using same code base as [dns 1](../1-bind-in-docker-and-kubernetes), I will create a second DNS image with only forwarding options to DNS1.
Here are some doc on forwarding; https://docstore.mik.ua/orelly/networking_2ndEd/dns/ch10_05.htm

The seconds DNS docker file can be found [here](docker-bind-dns).
Where we replace IP by

```shell script
[root@archlinux docker-bind-dns]# echo $DNS_1_SVC_CLUSTER_IP
10.102.77.148
```
in `named.conf.options`


````
cd /home/vagrant/dev/misc-notes/understand-dns/2-advanced-bind/3-bind-forwarders/docker-bind-dns
sudo docker build . -f dns-ubuntu.Dockerfile -t dns-ubuntu-2-fw
kubectl delete po ubuntu-dns-2-fw --force --grace-period=0
kubectl run ubuntu-dns-2-fw --image=dns-ubuntu-2-fw --restart=Never --image-pull-policy=Never -- /bin/sh -c "systemctl start named;systemctl enable named;sleep 3600"
````

We also expose this DNS

```shell script
kubectl expose pod ubuntu-dns-2-fw --port 53 --protocol=UDP
DNS_2_FW_SVC_CLUSTER_IP=$(kubectl get svc ubuntu-dns-2-fw -o jsonpath={'.spec.clusterIP'})
```

## Thus make a look up from fw DNS pod 

As done [here](../1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md#Deploy-in-k8s)

```shell script
[root@archlinux docker-bind-dns]# k exec -it ubuntu-dns-2-fw -- /bin/sh
# cat "/etc/bind/named.conf.local";
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

# ^C
# exit
command terminated with exit code 130
[root@archlinux docker-bind-dns]# k exec -it ubuntu-dns-2-fw -- /bin/sh
# cat /etc/bind/named.conf.options
options {
        directory "/var/cache/bind";

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable
        // nameservers, you probably want to use them as forwarders.
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.

        forwarders {
            10.102.77.148;
        };

        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        dnssec-validation auto;

        listen-on-v6 { any; };
};#  cat /etc/bind/named.conf
// This is the primary configuration file for the BIND DNS server named.
//
// Please read /usr/share/doc/bind9/README.Debian.gz for information on the
// structure of BIND configuration files in Debian, *BEFORE* you customize
// this configuration file.
//
// If you are just adding zones, please do that in /etc/bind/named.conf.local

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";#
# nslookup scoulomb.mylabserver.com 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

Non-authoritative answer:
Name:   scoulomb.mylabserver.com
Address: 42.42.42.42

# dig @127.0.0.1  scoulomb.mylabserver.com

; <<>> DiG 9.16.1-Ubuntu <<>> @127.0.0.1 scoulomb.mylabserver.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 10118
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 190aa9004b6fbd10010000005eefa97ee20cf54749a5f348 (good)
;; QUESTION SECTION:
;scoulomb.mylabserver.com.      IN      A

;; ANSWER SECTION:
scoulomb.mylabserver.com. 85652 IN      A       42.42.42.42

;; Query time: 0 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Sun Jun 21 18:39:58 UTC 2020
;; MSG SIZE  rcvd: 97

#
```

This gives a weird output IMO
```shell script
dig +norecurse +trace  @127.0.0.1 scoulomb.mylabserver.com
```

This also good to debug;
- `systemctl status named`; Not started because bad options
- `base DNS` down

## And make a lookup from the node using the fw DNS service IP

As done [here](../1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md#target-dns-from-the-node)

```shell script
nslookup scoulomb.mylabserver.com $DNS_2_FW_SVC_CLUSTER_IP
```

But this is refused as from google [here](../1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md#google-refused)

## Make a look up from another pod using fw DNS service IP

As done [here](../1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md#target-dns-from-another-pod)

```shell script
kubectl run busybox -it --image=busybox --restart=Never   --env="DNS_2_FW_SVC_CLUSTER_IP=$DNS_2_FW_SVC_CLUSTER_IP" --rm
nslookup scoulomb.mylabserver.com $DNS_2_FW_SVC_CLUSTER_IP
```

Output is

```shell script
[root@archlinux docker-bind-dns]# kubectl run busybox -it --image=busybox --restart=Never   --env="DNS_2_FW_SVC_CLUSTER_IP=$DNS_2_FW_SVC_CLUSTER_IP" --rm
If you don't see a command prompt, try pressing enter.
/ # nslookup scoulomb.mylabserver.com $DNS_2_FW_SVC_CLUSTER_IP
Server:         10.99.120.86
Address:        10.99.120.86:53

Non-authoritative answer:
Name:   scoulomb.mylabserver.com
Address: 42.42.42.42

*** Can't find scoulomb.mylabserver.com: No answer

/ #
```

It is working

Note dig can not be setup with `apt-get` here.

Do not confuse forwarding with master and slave.

## Usage

Not tested (decided to not do it)

````shell script
nslookup corporate-git-website localhost # -> does not work
# Configure forward dns to company dns: https://docstore.mik.ua/orelly/networking_2ndEd/dns/ch10_05.htm
nslookup corporate-git-website localhost # -> working
````
<!--
This not tested ok
dig for trace osef
-->

## Questions

Can we forward only a zone and use forwarder a a cache. 
Yes for both.

From: https://docstore.mik.ua/orelly/networking_2ndEd/dns/ch10_05.htm

- Forward zone

> BIND 8.2 introduced a new feature, forward zones, that allows you to configure your name server to use forwarders only when looking up certain domain names. (BIND 9's support for forward zones was added in 9.1.0.)

- cache
> The idea is that the forwarders handle all the off-site queries generated at the site, building up a rich cache of information. For any given query in a remote zone, there is a high probability that the forwarder can answer the query from its cache, docstore.mik.ua/orelly/networking_2ndEd/dns/ch10_05.htm



See [next section where will do DNS delegation](../4-bind-delegation/dns-delegation.md).