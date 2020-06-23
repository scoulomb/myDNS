# Bind in docker and kubernetes 

## Source IP in Kubernetes

### Objective

Objective is to understand what is the source IP when targeting a pod from:
- a node 
    - using service with type ClusterIP
    - using POD IP
 - another pod
    - using service with type ClusterIP
    - using POD IP

    
The part of `using service with type ClusterIP`  is covered in K8s website in the section [Using Source IP/Source IP for Services with Type=ClusterIP](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-clusterip).


### Setup

````shell script
sudo su 
minikube start --vm-driver=none
alias k='kubectl'
kubectl delete deployment --all
kubectl delete po --all
````

### Deploy special nginx showing source ip

I will start a pod running a nginx which showing source ip address:

````shell script
kubectl create deployment source-ip-app --image=k8s.gcr.io/echoserver:1.4
````

We can target it directly

```shell script
# kubectl exec -it source-ip-app-7c79c78698-tv6ft -- /bin/sh -c 'curl 127.0.0.1:8080'
CLIENT VALUES:
client_address=127.0.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://127.0.0.1:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=127.0.0.1:8080
user-agent=curl/7.47.0
BODY:
-no body in request-[root@archlinux docker-bind-dns]#
```

Note the `client_address=127.0.0.1`

And expose it through a service

````shell script
kubectl expose deployment source-ip-app --name=clusterip --port=80 --target-port=8080
````

### Get nginx service and pod ip

#### Service IP is 

````shell script
[root@archlinux myDNS]# kubectl get svc clusterip
NAME        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
clusterip   ClusterIP   10.100.147.242   <none>        80/TCP    55m
````



````shell script
SVC_CLUSTER_IP=$(kubectl get svc clusterip -o jsonpath={.spec.clusterIP})
````
So that 

````shell script
[root@archlinux myDNS]# echo $SVC_CLUSTER_IP
10.100.147.242
````


#### POD IP

````shell script
[root@archlinux myDNS]# kubectl get pods -o wide
NAME                             READY   STATUS    RESTARTS   AGE    IP           NODE        NOMINATED NODE   READINESS GATES
source-ip-app-7c79c78698-c956w   1/1     Running   0          7m4s   172.17.0.5   archlinux   <none>           <none> [root@archlinux myDNS]#
````

We can store it

````shell script
POD_IP=$( kubectl get pods source-ip-app-7c79c78698-c956w -o jsonpath={.status.podIP})

````shell script
[root@archlinux myDNS]# echo $POD_IP
172.17.0.5
````

### target source-ip-app from the node

#### SVC CLUSTER IP

````shell script
[root@archlinux myDNS]# curl $SVC_CLUSTER_IP
CLIENT VALUES:
client_address=10.0.2.15
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://10.100.147.242:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=10.100.147.242
user-agent=curl/7.69.1
BODY:
````
	
#### POD IP directly 

````shell script
[root@archlinux myDNS]# curl $POD_IP:8080
CLIENT VALUES:
client_address=172.17.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://172.17.0.5:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=172.17.0.5:8080
user-agent=curl/7.69.1
BODY:
-no body in request-[root@archlinux myDNS]#
````


#### Get node source ip

````shell script
[root@archlinux myDNS]# ip addr | grep eth0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0

[root@archlinux myDNS]# ip addr | grep -A 2 docker0:
4: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:bb:f2:66:8f brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
````

IP of the VM is `10.0.2.15`.


### CCL

Source ip is persevered only when using service Cluster Ip (VM eth0 interface).
When using POD IP it returns as a source first address of VM docker0 interface (shared subnet with pod).

### target source-ip-app from another pod

We will start a pod where we give as environment IP of of source-ip-app POD and Service to source-ip-app POD.

````shell script
kubectl run busybox -it --image=busybox --restart=Never   --env="SVC_CLUSTER_IP=$SVC_CLUSTER_IP" --env="POD_IP=$POD_IP" --rm

````


#### SVC CLUSTER IP

````shell script
/ # echo $SVC_CLUSTER_IP
10.100.147.242
/ # wget -qO - $SVC_CLUSTER_IP
CLIENT VALUES:
client_address=172.17.0.6
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://10.100.147.242:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
connection=close
host=10.100.147.242
user-agent=Wget
BODY:
-no body in request-/ #
````

### POD IP directly

````shell script
/ # echo $POD_IP
172.17.0.5

/ # wget -qO - $POD_IP:8080
CLIENT VALUES:
client_address=172.17.0.6
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://172.17.0.5:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
connection=close
host=172.17.0.5:8080
user-agent=Wget
BODY:
-no body in request-/ #
````

### Get pod ip

````shell script
/ # ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
31: eth0@if32: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:ac:11:00:06 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.6/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
````	   
or 

````shell script
scoulombel@NCEL96011 MINGW64 ~/dev/dev_vm (custom)
$ vagrant ssh
Last login: Sat Jun 20 11:54:34 2020 from 10.0.2.2
Welcome to fish, the friendly interactive shell
Type `help` for instructions on how to use fish
[13:24] ~
➤ sudo -i                                                                                            
[root@archlinux ~]# kubectl get pods -o wide
NAME                             READY   STATUS    RESTARTS   AGE     IP           NODE        NOMINATED NODE   READINESS GATES
busybox                          1/1     Running   0          4m44s   172.17.0.6   archlinux   <none>           <none>
source-ip-app-7c79c78698-c956w   1/1     Running   0          21m     172.17.0.5   archlinux   <none>           <none>
[root@archlinux ~]#
````


### CCL

Source ip is always preserved 

## DOC typo

Note here there is a typo in the [doc](https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-type-clusterip).

> `# Replace 10.0.170.92 with the Pod's IPv4 address` where it should be `# Replace 10.0.170.92 with your service clusterip address`.


We could also improve with env var as done here.


## Initially I wanted to test DNS view, with a DNS running on host node from pod

So the DNS would be deployed in same VM as Minikube (master/worker node)
 
Thus I could create a service targeting the DNS deployed on minikube node, and source ip would be different when coming from various pod or node itself

````shell script


cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: dns-service
spec:
  ports:
    - protocol: TCP
      port: 53
      targetPort: 53
EOF
````

and 

````
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Endpoints
metadata:
  name: dns-service
subsets:
  - addresses:
      - ip: 127.0.0.1
    ports:
      - port: 53
EOF
````

I can not! do this because

````
The Endpoints "dns-service" is invalid: subsets[0].addresses[0].ip: Invalid value: "127.0.0.1": may not be in the loopback range (127.0.0.0/8)
````

So we have to find another strategy.
See [next section](3-deploy-named-in-a-pod.md).

