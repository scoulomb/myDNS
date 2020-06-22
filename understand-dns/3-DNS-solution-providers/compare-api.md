# Compare with other API

## Parallel with k8s api

Source is:
- https://kubernetes.io/docs/reference/
- https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/

For instance deployment: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#deployment-v1-apps

### POST

````shell script
POST /apis/apps/v1/namespaces/{namespace}/deployments

$ kubectl proxy
$ curl -X POST -H 'Content-Type: application/yaml' --data '
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-example
spec:
  replicas: 3
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14
        ports:
        - containerPort: 80
' http://127.0.0.1:8001/apis/apps/v1/namespaces/default/deployments
````

### GET 

````shell script
GET /apis/apps/v1/namespaces/{namespace}/deployments/{name}
````

We can see:
- name and namespace are in metadata and present in the API path
It is used with the kind, and version by the controller to determine which API path to target
So it is redundant with API path and explain why it is not in the spec section.
- `apiVersion: apps/v1` matches path:  `/apis/apps/v1/`

More visible for CronJob: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#cronjob-v1beta1-batch
`POST /apis/batch/v1beta1/namespaces/{namespace}/cronjobs`

### Link with Azure

See [Azure DNS](./2-Azure-DNS/5-azure-api-details.md)
Azure API has also a metadata field.
Record name is not present in the body (same intent in k8s as not in the k8s spec part).

## Parallel with nslookup API

```shell script

➤ nslookup google.fr                                                                                                                                                          vagrant@archlinuxServer:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
Name:   google.fr
Address: 216.58.214.3
Name:   google.fr
Address: 2a00:1450:400e:800::2003

is equivalent to 

````shell script
➤ nslookup -type=A,AAAA google.fr                                                                                                                                             vagrant@archlinuxunknown query type: A,AAAA
Server:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
Name:   google.fr
Address: 216.58.214.3
Name:   google.fr
Address: 2a00:1450:400e:800::2003
````

And not only to A (as doc default value pretends)

````shell script
➤ nslookup -type=A google.fr                                                                                                                                                  vagrant@archlinuxServer:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
Name:   google.fr
Address: 216.58.214.3
````

We can aggregate type, useful if we do not know if a record is A,AAAA or CNAME.

But I can not have 1 A record and 1 CNAME with same DNS name as shown [here](../1-basic-bind-lxa/p2-1-xx-questions.md#can-i-have-1-a-record-and-1-cname-with-same-dns-name)
and in [Infoblox namespace](../3-DNS-solution-providers/1-Infoblox/infoblox-namespace.md).

<!--
raised in v0 comment
-->

For a CNAME (DNS Server [used](../1-basic-bind-lxa/with-archlinux-p2-1-summary-configure-forward-zone.md) ):

````shell script
[root@archlinux vagrant]# nslookup -type=cname dns.mylabserver.com
Server:         10.0.2.3
Address:        10.0.2.3#53

** server can't find dns.mylabserver.com: NXDOMAIN

[root@archlinux vagrant]# nslookup -type=cname dns.mylabserver.com 127.0.0.1
Server:         127.0.0.1
Address:        127.0.0.1#53

dns.mylabserver.com     canonical name = nameserver.mylabserver.com.
````

## Zone management 

- Bind manages zone with a conf file link in the named:  [Example](../2-advanced-bind/2-bind-views/docker-bind-dns/named.conf).
- Infoblox manages zone by inferring it from field `name` (full name) in the top level hierarchy of the body: [Example](1-Infoblox/infoblox-comparison.md)
- Azure defines DNS zone in the path [Example](./2-Azure-DNS/4-Azure-views.md)


For a our API we can wonder if we should set the zone in the path or not.


## View management 

- Bind manages view as optional wrapper around the zone:  [Example](../2-advanced-bind/2-bind-views/docker-bind-dns/named.conf).
- Infoblox manages view as an optional field (default) in the top level hierarchy of the body: [Example](1-Infoblox/infoblox-comparison.md)
- Azure DNS manages view by defining same zone in public API and private API: [Example](./2-Azure-DNS/4-Azure-views.md), Distinction is made in the path.

## Retrieve 

We have different way to retrieve a record defined [here](../1-basic-bind-lxa/p2-3-DNS-querying.md).

- Bind does not have REST API.
We can cat the file ;)

- Infoblox API performs the retreive with API using a record id: [Example](1-Infoblox/infoblox-comparison.md)
It looks like

````shell script
https://$API/wapi/v2.5/record:host/{uid}:{dns full name}/{view}
````

They also have an UI

We can also do a search: [Example](1-Infoblox/infoblox-namespace.md).

- Azure has a rest API: https://docs.microsoft.com/en-us/rest/api/dns/privatedns/recordsets/get

Path for retrieve is the same as in creation (no added UID unlike Infoblox)

````shell script
GET https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/{recordType}/{relativeRecordSetName}?api-version=2018-09-01
````

They can also perform a retrieve with Azure CLI, Powershell and portal

## PTR record

Infoblox host record automatically creates a PTR record if reverse zone defined.

## Alias 

Both Azure A, AAAA CNAME and infoblox host record can have alias: 
https://docs.microsoft.com/en-us/azure/dns/dns-alias

rather than defining a CNAME.
 
## structure is 

`/view/zone/(recordset)/type/record`
It is visible in Azure API and Bind, but less obvious in Infoblox.

## k8s like

For a k8s look like API for DNS we could put the view in the path (it would look like a k8s [namespace](compare-api.md#Parallel-with-k8s-api).
With in path:
- `/api/v1alpha1/dns/views/{view-name}/cname/{DNS-Name}`
- And have `.metadata.name`={DNS-name}, `.metadata.view`={view-Name}, `.apiVersion`(=v1alpha1), and `.kind`(=CName)
and `spec.ipv4` for A record

Given point raised [here](compare-api.md#Parallel-with-nslookup-API), though we can not create CNAME and A record with same DNS name
A user has to know what type is the record.
This why we could propose an API later like:

- /records  (GET) -> search
- /aptrs (GET, POST, PUT, DELETE)
- /cnames (GET, POST, PUT, DELETE)
