# Compare with other APIs: Bind9, Azure and Infoblox

## Zone management at record creation step

- Bind manages zone with a configuration file containing the record link in the named:  [Example](../2-advanced-bind/2-bind-views/docker-bind-dns/named.conf).
- Infoblox manages zone by inferring it from field `name` (full name) in the top level hierarchy of the body: [Example](../3-DNS-solution-providers/1-Infoblox/2-Infoblox-parallel-question-with-bind.md)
- Azure defines DNS zone in the path [Example](../3-DNS-solution-providers/2-Azure-DNS/4-Azure-views.md)

For a our API we can wonder if we should set the zone in the path or not.

## View management 

- Bind manages view as optional wrapper around the zone:  [Example](../2-advanced-bind/2-bind-views/docker-bind-dns/named.conf).
- Infoblox manages view as an optional field (default value is `default`) in the top level hierarchy of the body: [Example](../3-DNS-solution-providers/1-Infoblox/2-Infoblox-parallel-question-with-bind.md)
- Azure DNS manages view by defining same zone in public API and private API: [Example](../3-DNS-solution-providers/2-Azure-DNS/4-Azure-views.md), Distinction is made in the path.

## Retrieve 

We have different way to retrieve a record defined [here](../1-basic-bind-lxa/p2-3-DNS-querying.md).

- Bind does not have REST API :).
We can `cat` the file!

- Infoblox API performs the retrieve with API using a record id: [Example](../3-DNS-solution-providers/1-Infoblox/2-Infoblox-parallel-question-with-bind.md)
The record id contains DNS name and the view.

````shell script
https://$API/wapi/v2.5/record:host/{uid}:{dns full name}/{view}
````

They also have an UI

We can also do a search by name: [Example](../3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md).

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

Rather than defining a CNAME.

See Infoblox HostRecord [here](../3-DNS-solution-providers/1-Infoblox/4-Ansible-API/host-create-with-alias.yaml).

## structure tree is 

For the three api the tree is:
`/view/zone/(recordset)/record-type/record`
It is visible in Azure API and Bind, but less obvious in Infoblox.
But it is visible [here](../3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md#Infoblox-View-and-Zone-creation).

## Parallel with nslookup and dig API


```shell script
➤ nslookup google.fr                                                                                                                                                          vagrant@archlinux
Server:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
Name:   google.fr
Address: 216.58.214.3
Name:   google.fr
Address: 2a00:1450:400e:800::2003

would be equivalent to 

````shell script
➤ nslookup -type=A,AAAA google.fr                                                                                                                                             vagrant@archlinux
unknown query type: A,AAAA
````

But it is not possible!

````shell script
[08:53] ~
➤ man nslookup | grep -A 5 "type=value"                                                                                                                                       vagrant@archlinux
           querytype=value

           type=value
               Change the type of the information query.

               (Default = A and then AAAA; abbreviations = q, ty)

               Note: It is only possible to specify one query type, only the default behavior looks up both when an alternative is not specified.
````

So only default value can have A and AAAA.

````shell script
➤ nslookup -type=A google.fr 8.8.8.8                                                                                                                                          vagrant@archlinux
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   google.fr
Address: 216.58.206.227
````
I use `8.8.8.8` otherwise it uses DNS in `/etc/resolv.conf`.

But dig can aggregate type:

````shell script
➤ dig @8.8.8.8. google.com ANY   # different results with other recursive DNS                                                                                                                                             vagrant@archlinux

; <<>> DiG 9.16.0 <<>> @8.8.8.8. google.com ANY
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 38235
;; flags: qr rd ra; QUERY: 1, ANSWER: 23, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;google.com.                    IN      ANY

;; ANSWER SECTION:
google.com.             264     IN      A       74.125.206.101
google.com.             264     IN      A       74.125.206.100
google.com.             264     IN      A       74.125.206.113
google.com.             264     IN      A       74.125.206.138
google.com.             264     IN      A       74.125.206.139
google.com.             264     IN      A       74.125.206.102
google.com.             264     IN      AAAA    2a00:1450:400c:c04::71
google.com.             564     IN      MX      10 aspmx.l.google.com.
google.com.             264     IN      TXT     "docusign=05958488-4752-4ef2-95eb-aa7ba8a3bd0e"
google.com.             564     IN      MX      20 alt1.aspmx.l.google.com.
google.com.             3564    IN      TXT     "facebook-domain-verification=22rm551cu4k0ab0bxsw536tlds4h95"
google.com.             24      IN      SOA     ns1.google.com. dns-admin.google.com. 317830920 900 900 1800 60
google.com.             21564   IN      NS      ns4.google.com.
google.com.             3564    IN      TXT     "v=spf1 include:_spf.google.com ~all"
google.com.             21564   IN      NS      ns2.google.com.
google.com.             21564   IN      NS      ns3.google.com.
google.com.             564     IN      MX      50 alt4.aspmx.l.google.com.
google.com.             564     IN      MX      30 alt2.aspmx.l.google.com.
google.com.             3564    IN      TXT     "globalsign-smime-dv=CDYX+XFHUw2wml6/Gb8+59BsH31KzUr6c1l2BPvqKX8="
google.com.             264     IN      TXT     "docusign=1b0a6754-49b1-4db5-8540-d2c12664b289"
google.com.             21564   IN      CAA     0 issue "pki.goog"
google.com.             564     IN      MX      40 alt3.aspmx.l.google.com.
google.com.             21564   IN      NS      ns1.google.com.

;; Query time: 53 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Wed Jun 24 08:57:17 UTC 2020
;; MSG SIZE  rcvd: 729
````

We can aggregate type in API, useful if we do not know if a record is A,AAAA or CNAME.

But note  I can not have 1 A record and 1 CNAME with same DNS name as shown [here](../1-basic-bind-lxa/p2-1-xx-questions.md#can-i-have-1-a-record-and-1-cname-with-same-dns-name)
and in [Infoblox namespace](../3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md).

<!--
raised in v0 comment OK
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

Sometimes we can use `localhost` instead of `127.0.0.1` (depends on hostfile or DNS?).

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
It is used with the kind, and version by the controller to determine which API path to target.
It is also useful for a retrieve.
So it is redundant with API path and explain why it is not in the spec section.
- `apiVersion: apps/v1` matches path:  `/apis/apps/v1/`

More visible for CronJob: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#cronjob-v1beta1-batch
`POST /apis/batch/v1beta1/namespaces/{namespace}/cronjobs`

### Link with Azure

See [Azure DNS](../3-DNS-solution-providers/2-Azure-DNS/5-azure-api-details.md)
Azure API has also a metadata field.
Record name is not present in the body (same intent in k8s as not in the k8s spec part).

