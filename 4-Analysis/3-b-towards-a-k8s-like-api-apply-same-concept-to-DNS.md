# Towards a k8s like API - Apply same concept to DNS

What would happen If I had to design a DNS API with k8s philosophy.

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
- https://github.com/scoulomb/myIaC/blob/master/pulumi/quickstart/main.go#L43

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

Given point raised [here](2-compare-apis.md#Parallel-with-nslookup-and-dig-API), though we can not create CNAME and A record with same DNS name
A user has to know what type is the record.
This why we could propose an API extension later with a top level path.
I realized (later after taking this decision), this is what is done by [k8s API](./3-a-towards-a-k8s-like-api-explore-k8s-api.md#Documentation) when we List (pod in) all ns.
 
## As a result we could have 

If I had to design a DNS API design with k8s philosophy in mind.

### Path Initial


| Type | Operation         | HTTP method |  Path                                                                                     | Body
| ---- | ------------      | ----------- | --------------------------------------------------                                        | ------------------
|Write | create Entry      | POST        | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/{record-type}`                     | {record-type} body
|Write | replace Entry     | PUT         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/{record-type}/{relative-DNS-name}` | {record-type} body
|Write | delete  Entry     | DELETE      | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/{record-type}/{relative-DNS-name}` | {record-type} body
|Write | delete collection | DELETE      | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/{record-type}`                     | {record-type} body

| Type | Operation         | HTTP method |  Path                                                                                     | Body
| ---- | ------------      | ----------- | --------------------------------------------------                                        | ------------------
|Read  | Read Entry        | GET         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/{record-type}/{relative-DNS-name}` | Empty
|Read  | List Entries      | GET         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/{record-type}`                     | Empty
|Read  | List all Entries  | GET         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}`                                   | Empty

{record-type} body is body for specific for A or CNAME

### And Path if we expand (as in OpenAPI)

- {record-type} → Host
- {record-type} → CName

#### host record

| Type | Operation         | HTTP method |  Path                                                                                     | Body
| ---- | ------------      | ----------- | --------------------------------------------------                                        | ------------------
|Write | create Entry      | POST        | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/host`                              | host body
|Write | replace Entry     | PUT         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/host/{relative-DNS-name}`          | host body
|Write | delete  Entry     | DELETE      | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/host/{relative-DNS-name}`          | host body
|Write | delete collection | DELETE      | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/host`                              | host body

<!--
delete collection optional, not exposed
-->

| Type | Operation         | HTTP method |  Path                                                                                     | Body
| ---- | ------------      | ----------- | --------------------------------------------------                                        | ------------------
|Read  | Read Entry        | GET         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/host/{relative-DNS-name}`          | Empty
|Read  | List Entries      | GET         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/host`                              | Empty


#### CName

| Type | Operation         | HTTP method |  Path                                                                                     | Body
| ---- | ------------      | ----------- | --------------------------------------------------                                        | ------------------
|Write | create Entry      | POST        | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/cname`                             | cname body
|Write | replace Entry     | PUT         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/cname/{relative-DNS-name}`         | cname body
|Write | delete  Entry     | DELETE      | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/cname/{relative-DNS-name}`         | cname body
|Write | delete collection | DELETE      | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/cname`                             | cname body

| Type | Operation         | HTTP method |  Path                                                                                     | Body
| ---- | ------------      | ----------- | --------------------------------------------------                                        | ------------------
|Read  | Read Entry        | GET         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/cname/{relative-DNS-name}`         | Empty
|Read  | List Entries      | GET         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}/cname`                             | Empty



#### All records

| Type | Operation         | HTTP method |  Path                                                                                     | Body
| ---- | ------------      | ----------- | --------------------------------------------------                                        | ------------------
|Read  | List all Entries  | GET         | `/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}`                                   | Empty

This enables to list DNS resource without specifying the type.  Could also perform search, without mentioning the type at this endpoint level.
`/api/v1alpha1/dns/views/{view-name}/zones/{zone-name}?relative-DNS-name=my-vm`

<!--
Optional
-->
<!--
=> Option 5: should we have a different or same API path for close but different object
all presentation of method was not accurate and error in POST which does not have relative DNS name
https://github.com/scoulomb/myDNS/blob/47809cfdba46b083ea3dc43101be84dd9031aca2/4-Analysis/3-towards-a-k8s-like-api.md#note-possibility-to-gather-records
-->


#### Comments

Note that [Conclusion API server metadata ns and name are redundant with API path](./3-a-towards-a-k8s-like-api-explore-k8s-api.md#Conclusion-redundancy):
would apply here.
- `{view-name}` and `{zone-name}` <=> `{namespace}`
- `{relative-DNS-name}` <=> `{ (pod) name}`
- `{apiVersion}` and `{kind}` <=> `{apiVersion}` and `{kind/record-type}`

Also for list all entries is not at same level as ns it applies to 2 different resources.

And metadata has name, zone and view.

<!--

- I decided to remove `{view-name}` and `{zone-name}` from the body **metadata** to not have consistency check (we only rely on view and zone provided in path arguments + name in body).
This also enables to return directly the body.

See DNS PR#95.

Those Metadata are optional as
redundant with path query parameters. 

Metadata could have been used for retrieve use-case and to perform GitOps pattern. A controller could use it to
know which API path to target.

Redundancy does not apply for metadata.name which is
mandatory in POST body as not present in the path.

- Thus check on mame only needed for update => OK

- API version and kind 
    - API version: accept only v1 so if v2 in kind: OpenAPI error, if v2 in path OpenAPI 404 => OK
    - Kind: With OpenAPI, I made the necessary so that path for a given kind only accept object of one kind =< OK


{
  "apiVersion": "v1",
  "metadata": {
    "name": "yop",
    "externalReferenceId": "88888888"
  },
  "kind": "Host",
  "spec": {
    "ipv4Address": "172.17.2.9"
  }
}

See BB: repos/private/browse/myDNS/4-Analysis/4-private-proposal.md, actually deprecated
mirror conf: "DNS+auto+API+v1alpha1"
-->

I excluded network view from path and body: https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md#network-view-direct-access.
But could include for dynamic IP allocation.
