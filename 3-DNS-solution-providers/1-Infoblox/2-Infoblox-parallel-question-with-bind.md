# DNS

## Infoblox parallel with questions section in bind

### [Can I have 2 A records with same DNS name?](../../1-basic-bind-lxa/p2-1-xx-questions.md#Can-I-have-2-A-records-with-same-DNS-name?)
Answer is yes with bind

In Infoblox it is not possible to create 2 host records with same name.
Same for 2 CNAME, and 2 A.

Moreover those 3 kinds share the same namespace. Though it is a different API path:
- `/wapi/v2.5/record:a`
- `/wapi/v2.5/record:host`
- `/wapi/v2.5/record:cname`

For instance it is not possible to create a CNAME with same name as host record.

To reproduce the same same we would need to create 1 Infoblox host record with 2 IP addresses.

### [Canonical CNAME case](../../1-basic-bind-lxa/p2-1-xx-questions.md#Canonical-CNAME-case)

Implementation of this with Infoblox could be:
- 1 CNAME record and (1 host record xor 1 A record) [if 2 IP as shown in bind example: host rec with 2 IP xor 2 A record]
- 1 Host record with an alias (see [API doc](https://www.infoblox.com/wp-content/uploads/infoblox-deployment-infoblox-rest-api.pdf)). [if 2 IP as shown in bind example: host rec with 2 IP]



### Can I have 2 different A record pointing to same IP?

Answer is yes for bind
In infoblox it would be 2 different host record xor A record.

## Note on naming 

In Infoblox a host record is a A record with more feature.
- Creation of PTR record
- Alias 
- Define several IP addresses

This HostRecord is specific to Infoblox techno. So it is a APTR record.
However in community it sounds like HostRecord is a synonymous of A record.

https://www.ntchosting.com/encyclopedia/dns/host/#:~:text=The%20DNS%20A%20record,and%20its%20matching%20IP%20address.
> The A record, also known as a host record or a DNS host, is a record in your domain's DNS zone file that makes the connection between your domain and its matching IP address. 


I realized this here: https://linuxacademy.com/community/posts/show/topic/49680-dns-reverse-zone-lab
So maybe it is better to use HostRecord as a kind for more general API.

Also dns from Azure and Gcloud offers what they call a record set which enable to define several IP addresses.
- https://cloud.google.com/dns/docs/quickstart
- https://docs.microsoft.com/en-us/azure/dns/dns-zones-records

OK
