# Use Kubernetes ingress rule for application deployed behind the DNS

This is following [section e, Show we can deploy application behind DNS via Kubernetes](6-use-linux-nameserver-part-e.md#with-kubernetes)
We will now avoid NodePort exposure, and use ingress.

## Prerequisite

You can read this pages for a full understand on service and ingress with Kubernetes:
- https://github.com/scoulomb/myk8s/blob/master/Services/service_deep_dive.md (and in particular https://github.com/scoulomb/myk8s/blob/master/Services/service_deep_dive.md#and-target-the-ingress)
- https://github.com/scoulomb/myk8s/blob/master/Services/k8s_f5_integration.md

We will have to enable ingress in Minikube 

````shell script
sudo minikube addons enable ingress
````

**Source**: https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/


## Sample ingress

We prepared a [sample](6-part-e-contenarized-http-server/ingress.yaml) ingress.

And perform some tests.

````shell script
kubectl apply -f ./2-advanced-bind/5-real-own-dns-application/6-part-e-contenarized-http-server/ingress.yaml
````

<!--
https://kubernetes.io/docs/concepts/services-networking/ingress/#hostname-wildcards
--> 

We can perform some tests

````shell script
# route to A
curl -H "Host: a-server" 192.168.1.32
curl -H "Host: a-server" 192.168.1.32/
# route to b as we also route with path 
curl -H "Host: a-server" 192.168.1.32/tutu
# route to b
curl -H "Host: b-server" 192.168.1.32
# 404 error it is not defined
curl -H "Host: unknown" 192.168.1.32
````

output is 

````shell script
root@sylvain-hp:/home/sylvain/myDNS_hp# curl -H "Host: a-server" 192.168.1.32
Hello app A
root@sylvain-hp:/home/sylvain/myDNS_hp# curl -H "Host: a-server" 192.168.1.32/
Hello app A
root@sylvain-hp:/home/sylvain/myDNS_hp# curl -H "Host: a-server" 192.168.1.32/tutu
Hello app B
root@sylvain-hp:/home/sylvain/myDNS_hp# curl -H "Host: b-server" 192.168.1.32
Hello app B
root@sylvain-hp:/home/sylvain/myDNS_hp# curl -H "Host: unknown" 192.168.1.32
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.17.10</center>
</body>
</html>
root@sylvain-hp:/home/sylvain/myDNS_hp#
````

If we delete a service we will have a 503.

````shell script
root@sylvain-hp:/home/sylvain/myDNS_hp# kubectl delete svc b-server
service "b-server" deleted
root@sylvain-hp:/home/sylvain/myDNS_hp# curl -H "Host: b-server" 192.168.1.32
<html>
<head><title>503 Service Temporarily Unavailable</title></head>
<body>
<center><h1>503 Service Temporarily Unavailable</h1></center>
<hr><center>nginx/1.17.10</center>
</body>
</html>
````

The ingress server is exposing port 80, so I will configure NAT.

````shell script
ingress	TCP	Port	80	192.168.1.32	80
````

So that I can do (after service b [recreation as done i part e](6-use-linux-nameserver-part-e.md#kubernetes-with-own-dns))

````shell script
curl -H "Host: a-server" home.coulombel.it
curl -H "Host: b-server" home.coulombel.it
````

output is 

```shell script
root@sylvain-hp:/home/sylvain/myDNS_hp# curl -H "Host: a-server" home.coulombel.it
Hello app A
root@sylvain-hp:/home/sylvain/myDNS_hp# curl -H "Host: b-server" home.coulombel.it
Hello app B
```

but we can not use default host header.
Note in output below `> Host: home.coulombel.it`

````shell script
root@sylvain-hp:/home/sylvain/myDNS_hp# curl home.coulombel.it
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.17.10</center>
</body>
</html>

root@sylvain-hp:/home/sylvain/myDNS_hp# curl home.coulombel.it -v
*   Trying 109.29.148.109:80...
* TCP_NODELAY set
* Connected to home.coulombel.it (109.29.148.109) port 80 (#0)
> GET / HTTP/1.1
> Host: home.coulombel.it
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< Server: nginx/1.17.10
< Date: Wed, 25 Nov 2020 11:02:52 GMT
< Content-Type: text/html
< Content-Length: 154
< Connection: keep-alive
<
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.17.10</center>
</body>
</html>
* Connection #0 to host home.coulombel.it left intact
````

<!-- example  in doc is weird  curl http://a-server -->

We will now configure DNS and ingress to work in harmony.

## Use ingress to route to right applications with default Host header

### Observe

For this our DNS has the following record in [forwarding zone](6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db):

````shell script
; Ingress demo - part f
*.mypaas         IN      CNAME     scoulomb.ddns.net. ; here we could point to A directly
appa.prd     IN      CNAME     fake-a.mypaas.coulombel.it. ; here we could point directly to scoulomb.ddns.net. or to A directly
appb.prd     IN      CNAME     fake-b.mypaas.coulombel.it. ; here we could point directly to scoulomb.ddns.net. or to A directly
````

As nslookup will output this

````shell script
root@sylvain-hp:/home/sylvain/myDNS_hp# nslookup appa.prd.coulombel.it
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
appa.prd.coulombel.it   canonical name = fake-a.mypaas.coulombel.it.
fake-a.mypaas.coulombel.it      canonical name = scoulomb.ddns.net.
Name:   scoulomb.ddns.net
Address: 109.29.148.109

root@sylvain-hp:/home/sylvain/myDNS_hp# nslookup appb.prd.coulombel.it
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
appb.prd.coulombel.it   canonical name = fake-b.mypaas.coulombel.it.
fake-b.mypaas.coulombel.it      canonical name = scoulomb.ddns.net.
Name:   scoulomb.ddns.net
Address: 109.29.148.109
```` 

Applying [v2 ingress](6-part-e-contenarized-http-server/ingressv2.yaml) which uses Host header based routing matching the DNS configuration.

```shell script
kubectl apply -f ./2-advanced-bind/5-real-own-dns-application/6-part-e-contenarized-http-server/ingressv2.yaml
```

So that routing is made with default host header


````shell script
curl appa.prd.coulombel.it
curl appb.prd.coulombel.it
````

Output is 


````shell script
root@sylvain-hp:/home/sylvain/myDNS_hp# curl appa.prd.coulombel.it
Hello app A
root@sylvain-hp:/home/sylvain/myDNS_hp# curl appb.prd.coulombel.it
Hello app B
````

I would like to come back on the configuration 

````shell script
; Ingress demo - part f
[1] *.mypaas     IN      CNAME     scoulomb.ddns.net. ; here we could point to A directly
[2] appa.prd     IN      CNAME     fake-a.mypaas.coulombel.it. ; here we could point directly to scoulomb.ddns.net. or to A directly
[3] appb.prd     IN      CNAME     fake-b.mypaas.coulombel.it. ; here we could point directly to scoulomb.ddns.net. or to A directly
````

###### Alternative configuration

Here with comments we suggest **alternative configuration** could be 


````shell script
; Ingress demo - part f
[1] *.mypaas     IN      CNAME     109.29.148.109
[2] appa.prd     IN      CNAME     fake-a.mypaas.coulombel.it.
[3] appb.prd     IN      CNAME     fake-b.mypaas.coulombel.it. 
````

Here using CNAME makes more sense in [2][3] as we could change the IP.
With a dynamic DNS, it is less useful but we could change the dynamic DNS without impacting too much records.
Note that if the zone were `prd.coulombel.it`, we would be already at the APEX of the domain.
In that case we would have to use  A record `@ IN A`, we could note be able to define a CNAME at APEX (`@ IN CNAME`).

See here why: https://serverfault.com/questions/613829/why-cant-a-cname-record-be-used-at-the-apex-aka-root-of-a-domain

We had seen same issue of custom domain mapping and CNAME at APEX issue in:
- Github page: https://github.com/scoulomb/github-page-helm-deployer/blob/master/appendix-github-page-and-dns.md#go
- Google cloud run: https://github.com/scoulomb/attestation-covid19-saison2-auto#mapping-custom-domain-in-cloud-run


### Analysis

If we analyse what is happening steps by steps here:

````shell script
root@sylvain-hp:/home/sylvain/myDNS_hp# curl -v appb.prd.coulombel.it
*   Trying 109.29.148.109:80...
* TCP_NODELAY set
* Connected to appb.prd.coulombel.it (109.29.148.109) port 80 (#0)
> GET / HTTP/1.1
> Host: appb.prd.coulombel.it
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Server: nginx/1.17.10
< Date: Thu, 26 Nov 2020 10:28:09 GMT
< Content-Type: text/html
< Content-Length: 12
< Connection: keep-alive
< Last-Modified: Mon, 02 Nov 2020 20:55:10 GMT
<
Hello app B
* Connection #0 to host appb.prd.coulombel.it left intact
````

0. We do following query

````shell script
curl -v appb.prd.coulombel.it
> GET / HTTP/1.1
> Host: appb.prd.coulombel.it
````

1. DNS resolution is performed
    1. `appb.prd.coulombel.it` -> `fake-b.mypaas.coulombel.it.`
    2. Then we have wildcard rule `fake-b.mypaas.coulombel.it.`  -> `scoulomb.ddns.net.`
    3. `scoulomb.ddns.net` -> `109.29.148.109` 

Note with [**alternative configuration**](#alternative-configuration) describe above: step 1.ii would not be necessary

This resolution is made exactly as described in part [b (step 1,2,3)](6-use-linux-nameserver-part-b.md#achieve-with-our-own-dns-the-same-service-performed-by-gandi-for-application-deployed-in-section-part-a-to-abstract-dynamic-dns-name) with more indirection.

2. Here we use a NAT so forwarding is performed as in  [b (step 4)](6-use-linux-nameserver-part-b.md#achieve-with-our-own-dns-the-same-service-performed-by-gandi-for-application-deployed-in-section-part-a-to-abstract-dynamic-dns-name).
This step is optional.
3. Then the Ingress rule router is directing to the correct service using Host header (virtual hosting mechanism)
4. Service redirect and load balance to the correct pod using labels.

<!-- alternative config + openshift router and maybe NAT used is equivalent to what I know in real life
it is well described "OpenShift+route+deep+dive" and all info already here now and consistent OK
--> 

It is what was described here: https://github.com/scoulomb/github-page-helm-deployer/blob/master/appendix-github-page-and-dns.md#similarities-with-openshift-route-and-ingress


## Other advantages of the wildcard and intro to OpenShift route

We could have ingress rule which by default, when no host is given matches 

`<ingress/route-name>[-<namespace>].mypaas.coulombel.it.` to specified service in given `<namesapce>`.

In that case a default configuration  would always be working using the **wildcard DNS**.

This is exactly what OpenShift router is doing.

https://docs.openshift.com/container-platform/3.11/architecture/networking/routes.html#route-hostnames

> If a host name is not provided as part of the route definition, then OpenShift Container Platform automatically generates one for you. The generated host name is of the form:

we can see it when retrieving the route `oc get route <route-name> -o jsonpath={.spec.host}`

Note when we define our **specific custom DNS `CNAME` entry**: `appb.prd.coulombel.it` -> `fake-b.mypaas.coulombel.it.`
There is no need to match the OpenShift route name instead of `fake-b.mypaas.coulombel.it.`, it is independent but we can do it by convention.
This why we use fake to make it clear.

<!-- I tried wildcard in CNAME target with Gandi and it did not work -->

If we want to have both `<ingress/route-name>[-<namespace>].<service-name>.mypaas.coulombel.it.` and `appb.prd.coulombel.it`, 
we need the **wildcard** and the **specific** `appb` DNS entry definition, but also the 2 routes.

We will study OpenShift in next section more in details and show it.

## OpenShift route

In OpenShift, OpenShift route offer equivalent to Kubernetes Ingress.

Here is the doc: https://docs.openshift.com/container-platform/3.11/architecture/networking/routes.html#route-hostnames

Name to test 

- wildcard DNS: appa.mypaas.coulombel.it
- specific DNS: appa.coulombel.it

### No route

-  Both not not working


### Adding the route with host matching specific DNS name

````shell script
echo '
kind: Route
apiVersion: v1
metadata:
  name: appa-specific-dns
  labels:
    app: appa
spec:
  host: appa.coulombel.it
  to:
    kind: Service
    name: appa
  port:
    targetPort: 8080
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
' > /tmp/specific-route.yaml
oc delete -f /tmp/specific-route.yaml
oc apply -f /tmp/specific-route.yaml
````

- specific DNS working when termination is not passthough but connexion is not secure (SSL issue)
<!-- (gui-route same issue though termination is passthrough) -->
- wildcard not working


### Adding on top route with host matching DNS name, the one without host (thus matching the wildcard) 

````shell script
echo '
kind: Route
apiVersion: v1
metadata:
  name: appa
  labels:
    app: appa
spec:
  to:
    kind: Service
    name: appa
  port:
    targetPort: 8080
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
' > /tmp/default-route.yaml

oc delete -f /tmp/default-route.yaml
oc apply -f /tmp/default-route.yaml
````

Specific and wildcard are working 
   
   
<!-- For OpenShift I made test with ns automation (inception but like any api server) and replace with own convention as it did test on Minikube with hp -->

## Note on HTTPS
  
With Kubernetes ingress it needs more setup than what we did in v2.
Cf. below

````shell script
root@sylvain-hp:/home/sylvain/myDNS_hp# curl --max-time 5 -v --insecure https://appb.prd.coulombel.it
*   Trying 109.29.148.109:443...
* TCP_NODELAY set
* Connection timed out after 5000 milliseconds
* Closing connection 0
curl: (28) Connection timed out after 5000 milliseconds
root@sylvain-hp:/home/sylvain/myDNS_hp# curl --max-time 5 -v http://appb.prd.coulombel.it
*   Trying 109.29.148.109:80...
* TCP_NODELAY set
* Connected to appb.prd.coulombel.it (109.29.148.109) port 80 (#0)
> GET / HTTP/1.1
> Host: appb.prd.coulombel.it
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Server: nginx/1.17.10
< Date: Thu, 26 Nov 2020 14:32:53 GMT
< Content-Type: text/html
< Content-Length: 12
< Connection: keep-alive
< Last-Modified: Mon, 02 Nov 2020 20:55:10 GMT
<
Hello app B
* Connection #0 to host appb.prd.coulombel.it left intact
````
We would also need to certify we are owner of the DNS.
it is similar to what we had to do for
- Github page: https://github.com/scoulomb/github-page-helm-deployer/blob/master/appendix-github-page-and-dns.md#go
<!-- in gcr and openshift can define several mapping unlike github page -->
- Google cloud run: https://github.com/scoulomb/attestation-covid19-saison2-auto#mapping-custom-domain-in-cloud-run
<!-- And for https://github.com/scoulomb/aws-sa-exo, where it is at elb level according to itw, will stop there digging -->

<!--
OpenShift route as defined here has https: https://docs.openshift.com/container-platform/3.9/architecture/networking/routes.html#secured-routes
It is working in http and https: but https warning (self-signed certificate)
-->


<!-- ABOVE OK AND CLEAR including after: Other advantages of the wildcard and intro to OpenShift route -->

<!-- See PR where equivalences are clear:
DNS PR#77
-->

## What happens if you define 2 ingress with same host 

<!-- as mistake because did not replace between 2 project the host, tested with proj and here generic -->

Let's take openshift route as an example.

We start creating a service and related route in project/ns A. 

````shell script
oc project $project-a
oc create svc clusterip my-cs-1 --tcp 8080:8080
oc create route edge a-route --hostname test.net --path="" --service=my-cs-1 --port=8080 
oc get routes | grep -B 2 a-route
````


output is 

````shell script
➤ oc get routes | grep -B 2 a-route
NAME                                 HOST/PORT                                                        PATH      SERVICES                PORT      TERMINATION     WILDCARD
a-route                              test.net                                                                   my-cs-1                 8080      edge            None
````

We move to project B. Ans create same service and route. Note we could even keep the same resource name as in $project-a as those resource are namespace scoped.

 
````shell script
oc project $project-b
oc create svc clusterip my-cs-1 --tcp 8080:8080
oc create route edge a-route --hostname test.net --path="" --service=my-cs-1 --port=8080 --dry-run -o yaml
````

Dry-run seems ok.

````
➤ oc create route edge a-route --hostname test.net --path="" --service=my-cs-1 --port=8080 --dry-run -o yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  creationTimestamp: null
  labels:
    app: my-cs-1
  name: a-route
spec:
  host: test.net
  port:
    targetPort: 8080
  tls:
    termination: edge
  to:
    kind: ""
    name: my-cs-1
    weight: null
status:
  ingress: null
````

So we go for creation

````shell script
oc create route edge a-route --hostname test.net --path="" --service=my-cs-1 --port=8080
oc get routes | grep -B 2 a-route
````

output is 

````shell script
➤ oc get routes | grep -B 2 a-route
NAME                              HOST/PORT                                                                            PATH      SERVICES                          PORT      TERMINATION     WILDCARD
a-route                           HostAlreadyClaimed                                                                             my-cs-1                           8080      edge            None
````

But here we can see mutiproject conflict is managed we have the error **`HostAlreadyClaimed`**.

As seen in [ingress](6-part-e-contenarized-http-server/ingress.yaml). We can filter on `host` and `path`.
What happens if we add it.

````shell script
oc create route edge a-route-2 --hostname test.net --path="/titi" --service=my-cs-1 --port=8080
oc get routes | grep -B 2 a-route
````

Output is 

````shell script
➤ oc create route edge a-route-2 --hostname test.net --path="/titi" --service=my-cs-1 --port=8080
route.route.openshift.io/a-route-2 created
➤ oc get routes | grep -B 2 a-route
NAME                              HOST/PORT                                                                            PATH      SERVICES                          PORT      TERMINATION     WILDCARD
a-route                           HostAlreadyClaimed                                                                             my-cs-1                           8080      edge            None
a-route-2                         HostAlreadyClaimed                                                                   /titi     my-cs-1                           8080      edge            None
````

We still have  **`HostAlreadyClaimed`**.

Note if in given project we create 2 routes with same name we have an error

````shell script
➤ oc create route edge a-route-2 --hostname test.net --path="/titi" --service=my-cs-1 --port=8080
Error from server (AlreadyExists): routes.route.openshift.io "a-route-2" already exists
````

This demo is finished, we will cleam-up

````
oc delete route a-route --namespace $project-b
oc delete route a-route-2 --namespace $project-b
oc delete route a-route --namespace $project-a
````

Output is

````
➤ oc delete route a-route-2 --namespace $project-b
route.route.openshift.io "a-route-2" deleted
➤ oc delete route a-route --namespace $project-a
route.route.openshift.io "a-route" deleted
````
 
<!--
Proof on the scope

````shell script
➤ oc delete route a-route
Error from server (NotFound): routes.route.openshift.io "a-route" not found
➤ oc delete route a-route --namespace $project-a
route.route.openshift.io "a-route" deleted
````

Note route created via manifest, here cli and code via template,
could do via helm, pulumi => https://kccncna20.sched.com/event/ek9o/five-hundred-twenty-five-thousand-six-hundred-k8s-clis-phillip-wittrock-gabbi-fisher-apple
from https://kccncna20.sched.com/type/101+Track
-->

Ingress have similar behavior: https://github.com/nginxinc/kubernetes-ingress/issues/244

## Go further 

A nice presentation (formal) on Ingress was given on Kubecon 2020:
- https://kccncna20.sched.com/event/ekAL/inside-kubernetes-ingress-dominik-tornow-cisco
- https://static.sched.com/hosted_files/kccncna20/0b/Inside%20K8s%20Ingress.pdf

<!--
All work (in part e+f) linked with tasks:
- create DNS entry
--> 


<!-- 
 All work (in part e) linked with proj and other files
 DNS route (done route and DNS for specific and wildcard, and 2 routes matching same host does not work, both explained OK): DNS PR379 + 80 (script)
 And LB PR#298 and FW PR#114
 -->