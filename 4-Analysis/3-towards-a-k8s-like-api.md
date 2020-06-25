# Towards a k8s like API

## Choice A: View in path

For a k8s look like API for DNS we could put the view in the path (it would look like a k8s [namespace](2-compare-apis.md#Parallel-with-k8s-api).
With in path:
- `/api/v1alpha1/dns/views/{view-name}/{record-type}/{DNS-Name}`
- And have `.metadata.name`={DNS-name}, `.metadata.view`={view-Name} and `.apiVersion`(=v1alpha1), and `.kind`{recordType}`
and `spec.ipv4` for A record type or spec.canonicalName for CNAME record type.


We could also always have `kind: DNS` and discriminates record type with a type as done for service and thus `{record-type}` in path always equals to `DNS`.
This what is done for k8s svc
- https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#configuration-file
- https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#-strong-write-operations-service-v1-core-strong- (search Service v1 core and see ServiceSpec)
- https://github.com/scoulomb/myk8s/blob/master/Services/service_deep_dive.md

It is the choice made by [Google DNS API](../3-DNS-solution-providers/3-Google-DNS/1-Google-DNS.md#record-creation-inside-a-zone) for the type.

<!--
=> option 2: should we have a different or same API path for close but different object
-->

## Choice B: Adding zone in path

We could also split DNS name with a zone.
This can be convenient if using Azure otherwise we would have to infer the zone to use their API which can be painful.

With in path:
- `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/{record-type}/{relative-DNS-Name}`
- And have `.metadata.name`={relative-DNS-Name},  `.metadata.zone`={zone-Name} and `.metadata.view`={view-Name}, `.apiVersion`(=v1alpha1), and `.kind`{recordType}`
and `spec.ipv4` for A record type or spec.canonicalName for CNAME record type.

This option 2 is closer to original Bind API and Azure.
And compatible with Infoblox (but less similar to it).

It opens the possibility to create zone, even if not currently wanted.

## Note: Possibility to gather records

Given point raised [here](2-compare-apis.md#Parallel-with-nslookup-API), though we can not create CNAME and A record with same DNS name
A user has to know what type is the record.
This why we could propose an API extension later.

As a result we could have 


- GET, PUT, DELETE,POST: `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/{record-type}/{relative-DNS-name}`

Retrieve, full modify or deletion of an existing DNS resource 
Creation of a DNS resource

- GET: `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/{record-type}`

List of DNS resource of a given type. Could also perform a search at this level. 

- GET: `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}`

This would not block us to list DNS resource without specifying the type.  Could also perform search, without mentioning the type at this endpoint level.
`/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}?relative-DNS-name=my-vm`

<!--
=> Option 5: should we have a different or same API path for close but different object
-->


