# Bind views

In this section we will study bind views.

From [networking_2ndEd](https://docstore.mik.ua/orelly/networking_2ndEd/dns/ch10_06.htm):
> BIND 9 introduced views, another mechanism that's very useful in firewalled environments. Views allow you to present one name server configuration to one community of hosts and a different configuration to another community. 

It means that DNS response will depends on source IP (the subnet it belongs) of the requestor.

Previous [section](../1-bind-in-docker-and-kubernetes/1-intro.md), is a prerequisite, but this should be self-sufficient.
Views are also know as [Split horizon DNS, cf. Wikipedia](https://en.wikipedia.org/wiki/Split-horizon_DNS).

Using this article: https://docstore.mik.ua/orelly/networking_2ndEd/dns/ch10_06.htm
I modified my [Docker bind DNS](../1-bind-in-docker-and-kubernetes/docker-bind-dns) to support views.
Similarly to [Step3: Deploy named in a pod](../1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md), I will repeat here the same operations.

## Protocol

We have 3 views:

- `172.17.0.1` to `172.17.0.14`: `acl "view1" { 172.17.0.0/28; };` where `scoulomb IN A 41.41.41.41` 
- `10.0.0.1` to `10.0.255.254`: `acl "view2" { 10.0.0.0/16; };` where `scoulomb IN A 42.42.42.42` 
- and a `default view` where `scoulomb IN A 43.43.43.43` 

To simulate hosts with different subnets, we will 
- Deploy a pod with bind in k8s cluster
- Query this DNS server with query `nslookup scoulomb.mylabserver.com $OUR_DNS_SERVER` from:
    - its pod itself (as we would have done if DNS would be deployed in node directly) (source ip is [`127.0.0.1`](./2-understand-source-ip-in-k8s.md#Deploy-special-nginx-showing-source-ip)).
    Thus we expect `43.43.43.43`.
    - a node 
        - using service with type ClusterIP (source ip is  [`10.0.2.15`](./2-understand-source-ip-in-k8s.md#target-source-ip-app-from-the-node)).
        Thus we expect `42.42.42.42`.
        - using POD IP   (source ip is  [`172.17.0.1`](./2-understand-source-ip-in-k8s.md#target-source-ip-app-from-the-node)).
        Thus we expect `41.41.41.41`.
     - another pod
        - using service with type ClusterIP (source ip is  [`172.17.0.0/16`](./2-understand-source-ip-in-k8s.md#target-source-ip-app-from-another-pod)).
        Thus we expect `41.41.41.41` as long as POD IP < `14` 
        - using POD IP  (source ip is  [`172.17.0.0/16`](./2-understand-source-ip-in-k8s.md#target-source-ip-app-from-another-pod)).
        Thus we expect `41.41.41.41` as long as POD IP <= `14` 
`172.17.0.0/16` is POD CIDR (pod IP address range).
    
This DNS pod with bind replaces the [nginx showing source ip](2-understand-source-ip-in-k8s.md) from previous section
Client will perform `nslookup` instead of `curl` queries.

As observed before the source IP would be different if coming from a node or a given pod.
We can also deploy 50 client pod to have different IP range with `172.17.0.0/16`.
When IP range will go beyond > 14, queries from POD will return `43.43.43.43` instead of `41.41.41.41` when using service or pod IP.



## Deploy a container with a bind server in K8s cluster 

### Reset env

```shell script
sudo su 
alias k='kubectl'
kubectl delete deployment --all
kubectl delete po --all --force --grace-period=0
kubectl delete svc --all
```

### Write docker file

See source code [here](docker-bind-dns)

### Build docker image

```
cd misc-notes/understand-dns/2-advanced-bind/2-bind-views/docker-bind-dns
sudo docker build . -f dns-ubuntu.Dockerfile -t dns-ubuntu-view
```

### Deploy in k8s

````
kubectl run ubuntu-dns --image=dns-ubuntu-view --restart=Never --image-pull-policy=Never -- /bin/sh -c "systemctl start named;systemctl enable named;sleep 3600"
````

Be careful with the tag to load last image.

Then we can target it from pod itself

````
kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup google.fr localhost' # retry if issue
kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup scoulomb.mylabserver.com localhost' 
````

Output is 

````
[root@archlinux docker-bind-dns]# kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup google.fr localhost' # retry if issue
Server:         localhost
Address:        127.0.0.1#53

Non-authoritative answer:
Name:   google.fr
Address: 216.58.201.227
Name:   google.fr
Address: 2a00:1450:4007:816::2003

[root@archlinux docker-bind-dns]# kubectl exec -it ubuntu-dns --  /bin/sh -c 'nslookup scoulomb.mylabserver.com localhost'
Server:         localhost
Address:        127.0.0.1#53

Name:   scoulomb.mylabserver.com
Address: 43.43.43.43
````

We have `43.43.43.43` as expected.

```shell script
kubectl expose pod ubuntu-dns --port 53 --protocol=UDP
```


###  Get DNS service and pod ip

#### Service IP is 

```shell script
[root@archlinux docker-bind-dns]# k get svc ubuntu-dns
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
ubuntu-dns   ClusterIP   10.96.242.57   <none>        53/UDP    74s
```

We can save it

```shell script
DNS_SVC_CLUSTER_IP=$(kubectl get svc ubuntu-dns -o jsonpath={'.spec.clusterIP'})

```
So that 

```shell script
[root@archlinux docker-bind-dns]#  echo $DNS_SVC_CLUSTER_IP
10.96.242.57
```


### POD IP

```shell script
[root@archlinux docker-bind-dns]# k get pods -o wide | grep dns
ubuntu-dns   1/1     Running   0          3m21s   172.17.0.3   archlinux   <none>           <none>
```

We can save it

```shell script
DNS_POD_IP=$( kubectl get pods ubuntu-dns -o jsonpath={.status.podIP})
```
So that 

```shell script
[root@archlinux docker-bind-dns]#  echo $DNS_POD_IP
172.17.0.3
```

### target DNS from the node

#### SVC CLUSTER IP

```shell script
[root@archlinux docker-bind-dns]# nslookup scoulomb.mylabserver.com $DNS_SVC_CLUSTER_IP
Server:         10.96.242.57
Address:        10.96.242.57#53

Name:   scoulomb.mylabserver.com
Address: 42.42.42.42
```

`42.42.42.42` as expected.

Note that for this case only when doing recursion it is STILL forbidden 

````
[root@archlinux docker-bind-dns]# nslookup google.com $DNS_SVC_CLUSTER_IP
Server:         10.96.242.57
Address:        10.96.242.57#53

** server can't find google.com: REFUSED
````


#### POD IP directly

```shell script
[root@archlinux docker-bind-dns]# nslookup scoulomb.mylabserver.com $DNS_POD_IP
Server:         172.17.0.3
Address:        172.17.0.3#53

Name:   scoulomb.mylabserver.com
Address: 41.41.41.41
```

`41.41.41.41` as expected.


### target source-ip-app from another pod

We will run DNS query from this client pod which has `nslookup` pre-installed:

```shell script
kubectl run busybox -it --image=busybox --restart=Never   --env="DNS_SVC_CLUSTER_IP=$DNS_SVC_CLUSTER_IP" --env="DNS_POD_IP=$DNS_POD_IP" --rm
```

We ensure address is <14:

```shell script
/ # ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
217: eth0@if218: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:ac:11:00:04 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.4/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```


#### SVC CLUSTER IP

If you don't see a command prompt, try pressing enter.

```shell script
/ #  echo $DNS_SVC_CLUSTER_IP
10.96.242.57
/ # nslookup scoulomb.mylabserver.com $DNS_SVC_CLUSTER_IP
Server:         10.96.242.57
Address:        10.96.242.57:53

Name:   scoulomb.mylabserver.com
Address: 41.41.41.41

*** Can't find scoulomb.mylabserver.com: No answer
```

`41.41.41.41` as expected.

### POD IP directly

```shell script
/ # echo $DNS_POD_IP
172.17.0.3
/ # nslookup scoulomb.mylabserver.com $DNS_POD_IP
Server:         172.17.0.3
Address:        172.17.0.3:53

Name:   scoulomb.mylabserver.com
Address: 41.41.41.41

*** Can't find scoulomb.mylabserver.com: No answer
```

`41.41.41.41` as expected.

### Generate a range

We can also deploy 50 clients pods and have different range of IP and in particular > 14.

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

No we will get POD name of of pod which has IP > 14.

```shell script
[root@archlinux docker-bind-dns]# k get pods -o wide | grep "172.17.0.20"
many-6b49f78958-l4z24   1/1     Running   0          10m   172.17.0.20   archlinux   <none>           <none>
```

We will record it

```shell script
POD_NAME=$(k get pods -o wide | grep "172.17.0.20" | awk '{ print $1 }')
```

So 
```shell script
[root@archlinux docker-bind-dns]# echo $POD_NAME
many-6b49f78958-l4z24
```

And perform a nslookup

```shell script
k exec $POD_NAME -- /bin/sh -c "echo $DNS_SVC_CLUSTER_IP; nslookup scoulomb.mylabserver.com $DNS_SVC_CLUSTER_IP; echo $DNS_POD_IP; nslookup scoulomb.mylabserver.com $DNS_POD_IP;"
``` 

Output is

````shell script
[root@archlinux docker-bind-dns]# k exec $POD_NAME -- /bin/sh -c "echo $DNS_SVC_CLUSTER_IP; nslookup scoulomb.mylabserver.com $DNS_SVC_CLUSTER_IP; echo $DNS_POD_IP; nslookup scoulomb.mylabserver.com $DNS_POD_IP;"
10.96.242.57
Server:         10.96.242.57
Address:        10.96.242.57:53

Name:   scoulomb.mylabserver.com
Address: 43.43.43.43

*** Can't find scoulomb.mylabserver.com: No answer

172.17.0.3
Server:         172.17.0.3
Address:        172.17.0.3:53

Name:   scoulomb.mylabserver.com
Address: 43.43.43.43

*** Can't find scoulomb.mylabserver.com: No answer

[root@archlinux docker-bind-dns]#
````
As expected when IP range will go beyond > 14, queries from POD will return `43.43.43.43` instead of `41.41.41.41` when using service or pod IP.

Switch is performed from 16 ([range calculator](http://www.subnet-calculator.com/subnet.php?net_class=A) is confusing).

````shell script
[root@archlinux docker-bind-dns]# k exec $POD_NAME -- /bin/sh -c "echo $DNS_SVC_CLUSTER_IP; nslookup scoulomb.mylabserver.com $DNS_SVC_CLUSTER_IP; echo $DNS_POD_IP; nslookup scoulomb.mylabserver.com $DNS_POD_IP;"
10.96.242.57
Server:         10.96.242.57
Address:        10.96.242.57:53

Name:   scoulomb.mylabserver.com
Address: 43.43.43.43

*** Can't find scoulomb.mylabserver.com: No answer

172.17.0.3
Server:         172.17.0.3
Address:        172.17.0.3:53

Name:   scoulomb.mylabserver.com
Address: 43.43.43.43

*** Can't find scoulomb.mylabserver.com: No answer

[root@archlinux docker-bind-dns]# POD_NAME=$(k get pods -o wide | grep "172.17.0.15" | awk '{ print $1 }')
[root@archlinux docker-bind-dns]# k exec $POD_NAME -- /bin/sh -c "echo $DNS_SVC_CLUSTER_IP; nslookup scoulomb.mylabserver.com $DNS_SVC_CLUSTER_IP; echo $DNS_POD_IP; nslookup scoulomb.mylabserver.com $DNS_POD_IP;"
10.96.242.57
Server:         10.96.242.57
Address:        10.96.242.57:53

Name:   scoulomb.mylabserver.com
Address: 41.41.41.41

*** Can't find scoulomb.mylabserver.com: No answer

172.17.0.3
Server:         172.17.0.3
Address:        172.17.0.3:53

Name:   scoulomb.mylabserver.com
Address: 41.41.41.41

*** Can't find scoulomb.mylabserver.com: No answer
````

Note that in BIND API we have view/zone.
Zone are inside a view.

See [next section where will do DNS forwarding](../3-bind-forwarders/dns-forwarding.md).



<!--
Views are understood and tested.
Stop
-->