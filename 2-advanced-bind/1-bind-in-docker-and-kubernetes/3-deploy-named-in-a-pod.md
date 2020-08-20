# Bind in docker and kubernetes 

## Idea

To simulate hosts with different subnets, my idea is to:
- Deploy a pod with bind in k8s cluster
- Query this DNS server from:
    - its pod itself (as we would have done if DNS would be deployed in node directly) (source ip is [`127.0.0.1`](2-understand-source-ip-in-k8s.md#Deploy-special-nginx-showing-source-ip))
    - a node 
        - using service with type ClusterIP (source ip is  [`10.0.2.15`](2-understand-source-ip-in-k8s.md#target-source-ip-app-from-the-node))
        - using POD IP   (source ip is  [`172.17.0.1`](2-understand-source-ip-in-k8s.md#target-source-ip-app-from-the-node))
     - another pod
        - using service with type ClusterIP (source ip is  [`172.17.0.0/16`](2-understand-source-ip-in-k8s.md#target-source-ip-app-from-another-pod))
        - using POD IP  (source ip is  [`172.17.0.0/16`](2-understand-source-ip-in-k8s.md#target-source-ip-app-from-another-pod))

`172.17.0.0/16` is POD CIDR (pod IP address range).
    
This DNS pod with bind replaces the [nginx showing source ip](2-understand-source-ip-in-k8s.md) from previous section
Client will perform `nslookup` instead of `curl` queries.

As observed before the source IP would be different if coming from a node or a given pod.
We can also deploy 50 client pod to have different IP range with `172.17.0.0/16`

In a first we will deploy see how to deploy a POD with basic bind configuration.

## Deploy a container with a bind server in K8s cluster 

<!--
I can not use archlinux image because of certificate issue...
I will use Ubuntu with bind9 as in Ubuntu laptop.
-->

### Write docker file

See source code [here](docker-bind-dns)


At the beginning I had deployed the pod with few layers and start from this [guide](../../1-basic-bind-lxa/with-archlinux-p2-1-summary-configure-forward-zone.md).
And add layers iteratively, we can see the difference with ArchLinux conf.


### Build docker image

```
cd 2-advanced-bind/1-bind-in-docker-and-kubernetes/docker-bind-dns
sudo docker build . -f dns-ubuntu.Dockerfile -t dns-ubuntu
```

### Deploy in k8s

````
kubectl delete po ubuntu-dns --force --grace-period=0
kubectl run ubuntu-dns --image=dns-ubuntu --restart=Never --image-pull-policy=Never -- /bin/sh -c "systemctl start named;systemctl enable named;sleep 3600"
````

Be careful with the tag to load last image.

Then we can target it from pod itself

````
kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup google.fr localhost' # retry later if issue
kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup scoulomb.mylabserver.com localhost' 
kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup sub.scoulomb.mylabserver.com localhost' 
````

<!--
kubectl create deployment archlinux-dns --image=archlinux # crashloop as no sleep
-->


Output is 

````
[root@archlinux docker-bind-dns]# kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup google.fr localhost' # retry if isse
Server:         localhost
Address:        127.0.0.1#53

Non-authoritative answer:
Name:   google.fr
Address: 216.58.209.227
Name:   google.fr
Address: 2a00:1450:4007:80f::2003

[root@archlinux docker-bind-dns]# kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup scoulomb.mylabserver.com localhost' # retry if isse
Server:         localhost
Address:        127.0.0.1#53

Name:   scoulomb.mylabserver.com
Address: 42.42.42.42

[root@archlinux docker-bind-dns]# kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup sub.scoulomb.mylabserver.com localhost'
Server:         localhost
Address:        127.0.0.1#53

Name:   sub.scoulomb.mylabserver.com
Address: 50.68.8.8
````


Note it is another source IP!
First query to google is a recursion.
Second query is an authoritative answer.

Last example `sub.scoulomb.mylabserver.com` show we can define subdomain in zone, and it is also not to be confused with [delegation](../../2-advanced-bind/4-bind-delegation/docker-bind-dns-it-cc-tld/fwd.it.db.tpl).
In that [example](../../2-advanced-bind/4-bind-delegation/dns-delegation.md#Start-it-cc-tld-DNS-server) we saw record define in higher level were overriden (`override.coulombel`).


<!-- tested with infoblox and why zone is distinct, do not go further with delegation test but from fw file we can guess delegation will have the priority -->


We will also expose this DNS pod with a service:


```shell script
kubectl expose pod ubuntu-dns --port 53 --protocol=UDP
```

Operation made above are similar to [2-understand-source-ip-in-k8s/deploy section](2-understand-source-ip-in-k8s.md#Deploy-special-nginx-showing-source-ip).
And operations below are similar to the remaining of this same [document](2-understand-source-ip-in-k8s.md#Get-nginx-service-and-pod-ip).

### Note on NS records

If we remove this line in forwarding zone:

````shell script
@        IN      NS       nameserver.mylabserver.com.
````

`named-checkzone` will raise this error:

````shell script
zone fwd.mylabserver.com/IN: has no NS records
````

However removing this line

````shell script
nameserver       IN      A       172.31.18.93
````

Which is equivalent to `nameserver.mylabserver.com.` will not raise a validation error but a lookup will not work:

````shell script
# kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup scoulomb.mylabserver.com localhost'
;; Got SERVFAIL reply from 127.0.0.1, trying next server
Server:         localhost
Address:        127.0.0.1#53

** server can't find scoulomb.mylabserver.com: SERVFAIL

````

The `NS` record defines the DNS which authoritative for this domain.

From: https://www.cloudflare.com/learning/dns/dns-records/dns-ns-record/

> NS stands for 'name server' and this record indicates which DNS server is authoritative for that domain (which server contains the actual DNS records).

We need to define corresponding glue record, but it is not used when querying `scoulomb.mylabserver.com` as this record is available is not under `nameserver` domain.

We will study delegation in  [section 4](../4-bind-delegation/dns-delegation.md)
In particular see delegation [zone file example](../4-bind-delegation/docker-bind-dns-it-cc-tld/fwd.it.db).

###  Get DNS service and pod ip

#### Service IP is 

```shell script
[root@archlinux myDNS]# kubectl expose pod ubuntu-dns --port 53 --protocol=UDP
service/ubuntu-dns exposed
[root@archlinux myDNS]# k get svc ubuntu-dns
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
ubuntu-dns   ClusterIP   10.102.106.236   <none>        53/UDP    55s
```

We can save it

```shell script
DNS_SVC_CLUSTER_IP=$(kubectl get svc ubuntu-dns -o jsonpath={'.spec.clusterIP'})

```
So that 

```shell script
[root@archlinux myDNS]# echo $DNS_SVC_CLUSTER_IP
10.102.106.236
```


### POD IP

```shell script
[root@archlinux myDNS]# k get pods -o wide | grep dns
ubuntu-dns              1/1     Running   0          7m38s   172.17.0.45   archlinux   <none>           <none>
```

We can save it

```shell script
DNS_POD_IP=$( kubectl get pods ubuntu-dns -o jsonpath={.status.podIP})
```
So that 

```shell script
[root@archlinux myDNS]# echo $DNS_POD_IP
172.17.0.45
```

### target DNS from the node

#### SVC CLUSTER IP

```shell script
[root@archlinux docker-bind-dns]# nslookup scoulomb.mylabserver.com $DNS_SVC_CLUSTER_IP
Server:         10.102.106.236
Address:        10.102.106.236#53

Name:   scoulomb.mylabserver.com
Address: 42.42.42.42
```

###### Google refused

Note that for this case only when doing recursion it is forbidden 

````
[root@archlinux docker-bind-dns]# nslookup google.com $DNS_SVC_CLUSTER_IP
Server:         10.102.106.236
Address:        10.102.106.236#53

** server can't find google.com: REFUSED
````

Due to bind default settings, probably because from ths souce IP no recursion is allowed.
Hopefully it is working for authoritative record.

#### POD IP directly

```shell script
[root@archlinux docker-bind-dns]# nslookup scoulomb.mylabserver.com $DNS_POD_IP
Server:         172.17.0.45
Address:        172.17.0.45#53

Name:   scoulomb.mylabserver.com
Address: 42.42.42.42
```

Note the DNS server address which is service ip and pod ip

### target DNS from another pod

We will run DNS query from this client pod which has `nslookup` pre-installed:

```shell script
kubectl run busybox -it --image=busybox --restart=Never   --env="DNS_SVC_CLUSTER_IP=$DNS_SVC_CLUSTER_IP" --env="DNS_POD_IP=$DNS_POD_IP" --rm
```

#### SVC CLUSTER IP

If you don't see a command prompt, try pressing enter.

```shell script
/ # echo $DNS_SVC_CLUSTER_IP
10.102.106.236
/ # nslookup scoulomb.mylabserver.com $DNS_SVC_CLUSTER_IP
Server:         10.102.106.236
Address:        10.102.106.236:53

Name:   scoulomb.mylabserver.com
Address: 42.42.42.42

*** Can't find scoulomb.mylabserver.com: No answer


/ #
```

### POD IP directly

```shell script
/ # echo $DNS_POD_IP
172.17.0.45
/ # nslookup scoulomb.mylabserver.com $DNS_POD_IP
Server:         172.17.0.45
Address:        172.17.0.45:53

Name:   scoulomb.mylabserver.com
Address: 42.42.42.42

*** Can't find scoulomb.mylabserver.com: No answer
\
```

As a consequence we will be able to play on source ip address (src is node, pod) and the view 
We see an error but resolution is performed.


Here :

```shell script
Address:        172.17.0.45:53
```
We understand 53 is the port!

### Generate a range

We can also deploy 50 clients pods and have different range of IP

```shell script
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: many
  name: many
spec:
  replicas: 50
  selector:
    matchLabels:
      app: many
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: many
    spec:
      containers:
      - name: busy
        image: busybox
        command:
        - sleep
        - "3600"
EOF

```
http://www.subnet-calculator.com/subnet.php?net_class=B


Note the DNS server address which is service IP when service is used, and POD IP when POD IP is used in the answer.

### Note on Core DNS

From a pod, if we do 

```shell script

root@archlinux docker-bind-dns]# kubectl run busybox -it --image=busybox --restart=Never  --rm
If you don't see a command prompt, try pressing enter.
/ # nslookup scoulomb.mylabserver.com ubuntu-dns
Server:         ubuntu-dns
Address:        10.102.106.236:53

Name:   scoulomb.mylabserver.com
Address: 42.42.42.42

*** Can't find scoulomb.mylabserver.com: No answer

/ # cat /etc/resolv.conf
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
/ #

```

We are using k8s dns to resolve the DNS name matching the service IP.

<!--
though here weird answer

```shell script
/ # nslookup ubuntu-dns
Server:         10.96.0.10
Address:        10.96.0.10:53

** server can't find ubuntu-dns.default.svc.cluster.local: NXDOMAIN

*** Can't find ubuntu-dns.svc.cluster.local: No answer
*** Can't find ubuntu-dns.cluster.local: No answer
*** Can't find ubuntu-dns.default.svc.cluster.local: No answer
*** Can't find ubuntu-dns.svc.cluster.local: No answer
*** Can't find ubuntu-dns.cluster.local: No answer
```
-->

See [next section](../2-bind-views/bind-views.md).