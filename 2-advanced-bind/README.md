# Explain DNS with Kubernetes

In this subproject we will use k8s, bind and docker to show different kind of DNS mode.
Then we will leverage this knowledge for real world application.

<!--
We could have used VM instead but os dup etc
-->

This completes this [document in basic part](../1-basic-bind-lxa/p2-1-zz-note-on-recursive-and-authoritative-dns.md).

## Section 1: Simple Recursive and Authoritative DNS in Kubernetes

This will show:

- [**recursive DNS**](./1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md) (aka cache server). This has already been studied [here](../1-basic-bind-lxa/p1-1-dns-cache.md).
Do not confuse with OS/Browser caching ([firefox cache about:networking#dns](about:networking#dns)) (note some browsers now uses os caching)
<!-- in next I could y, Autoritative only-->
- [**Authoritative DNS**](./1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md).

Note we can disable recursion explicitly.
Or same DNS can be authoritative for a domain and recursive for others. We show second option in [section 1](./1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md).

Section is divided into:

- [Intro](1-bind-in-docker-and-kubernetes/1-intro.md)
- [Understand source IP in k8s](1-bind-in-docker-and-kubernetes/2-understand-source-ip-in-k8s.md)
- [Deploy named in a pod](1-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md)  


## Section 2: Authoritative DNS zone and view

- [Authoritative DNS zone view view](./2-bind-views/bind-views.md)

## Section 3: Forwarding DNS 

- [**Forwarding DNS**](./3-bind-forwarders/dns-forwarding.md) (different from a fw Zone) 


## Section 4: Record delegation 
 
- [**Record delegation**](./4-bind-delegation/dns-delegation.md)

## Section 5: real world applications

We will conclude with a wrap-up and show the link with public DNS in [real world application](./5-real-world-application/README.md).
- Gandi
- Amazon route 53

## Notes

On [Digital Ocean](https://www.digitalocean.com/community/tutorials/a-comparison-of-dns-server-types-how-to-choose-the-right-dns-configuration), we can find same listing:
    - Recursive
    - Authoritative
    - Forwarding
    - Delegation
    
- DNS resolves the location and returns IP to the caller (GTM) and does not proxy to the service (LTM) unlike F5 LTM.

- If you face some issue with docker, you can check [debug section](./debug/fix-docker-build-issue.md)

<!--
HLD OK
-->