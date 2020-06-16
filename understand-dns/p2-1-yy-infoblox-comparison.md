# DNS

## Infoblox API overview

````
export API_ENDPOINT="x.x.x.x"
export USERNAME=""
export PASSWORD=""
echo -n "$USERNAME:$PASSWORD" > ~/admin-credentials
````

### POST CNAME

````
export reference=$(curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-cname1.test.loc","canonical":"tes4.test.loc"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:cname)
        
# https://stackoverflow.com/questions/9733338/shell-script-remove-first-and-last-quote-from-a-variable
export reference_without_quote=$(sed -e 's/^"//' -e 's/"$//' <<< $reference)
````

### GET CNAME
````
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/$reference_without_quote"
````
### DELETE CNAME
````
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X DELETE \
        "https://$API_ENDPOINT/wapi/v2.5/$reference_without_quote"
````
### POST HOST RECORD
````
export reference=$(curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-host1.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.2"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host)
        
export reference_without_quote=$(sed -e 's/^"//' -e 's/"$//' <<< $reference)
````
### DELETE HOST RECORD
````
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X DELETE \
        "https://$API_ENDPOINT/wapi/v2.5/$reference_without_quote"
````
### POST PTR
````
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"2.10.10.10.in-addr.arpa", "ptrdname":"server1.info.com","ipv4addr":"10.10.10.2"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:ptr
````       
### POST A
````
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-a1.test.loc","ipv4addr":"10.10.10.2"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a
````
### FIND A by name

 ````      
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:a?name=test-infoblox-api-a1.test.loc"
````

Name is an array, when it is on the name based on observation above I expect 1 result.
But it is an array as we can search on other view such as the view.

### Find CNAME by view
````
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:a?view=default"
````

## Infoblox comparision with questions section

### [Can I have 2 A records with same DNS name?](./p2-1-xx-questions.md#Can-I-have-2-A-records-with-same-DNS-name?)
Answer is yes with bind

In Infoblox it is not possible to create 2 host records with same name.
Same for 2 CNAME, and 2 A.

Moreover those 3 kinds share the same namespace. Though it is a different API path:
- `/wapi/v2.5/record:a`
- `/wapi/v2.5/record:host`
- `/wapi/v2.5/record:cname`

For instance it is not possible to create a CNAME with same name as host record.

To reproduce the same same we would need to create 1 Infoblox host record with 2 IP addresses.

### [Canonical CNAME case](./p2-1-xx-questions.md#Canonical-CNAME-case)

Implementation of this with Infoblox could be:
- 1 CNAME record and (1 host record xor 1 A record)
- 1 Host record with an alias (see [API doc](https://www.infoblox.com/wp-content/uploads/infoblox-deployment-infoblox-rest-api.pdf)).

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

