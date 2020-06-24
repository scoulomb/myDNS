# DNS: Infoblox API overview

## Infoblox Record API overview

````
export API_ENDPOINT="x.x.x.x" # or FQDN to DNS
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


## Infoblox View and Zone creation



From https://www.infoblox.com/wp-content/uploads/infoblox-deployment-infoblox-rest-api.pdf (p55):

> DNS views provide the ability to serve one version of DNS data to one set of clients and another version to
another set of clients. With DNS views, the appliance can provide a different answer to the same query,
depending on the source of the query.

Create a network view with API by doing


````shell script
curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.11/networkview?_return_fields%2B=name&_return_as_object=1" -d '{"name":
"demo"}'
````
And create an authoritative zone within a network view

````shell script
curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.11/zone_auth?_return_fields%2B=fqdn,network_view&_return_as_object=1" -d
'{"fqdn": "infoblox.com","view": "default.test"}'
````

Then create a host record within a network view (as done above)

````shell script
curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.11/record:host?_return_fields%2B=name,network_view&_return_as_object=1" -d
'{"name":"host.infoblox.com","ipv4addrs": [{"ipv4addr":"10.10.10.20"}],"view": "default.test"}'
````

In doc seems we have a mistake in output `network_view` instead of `view` (p56).

Add a network within a view

````shell script
curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.11/network?_return_fields%2B=network&_return_as_object=1 " -d '{"network":
"192.168.1.0/24","network_view": "test"}'

````
## Infoblox TTL


<details>
  <summary>Infoblox has also a TTL at record level, we can define TTL at zone and global level</summary>
  
  
````json
{
    "name": "testttl.test.loc",
    "view": "default",
    "ipv4addrs": [{
        "ipv4addr": "4.4.4.2"
    }, {
        "ipv4addr": "4.4.4.5"
    }],
	  "ttl": 3600,
	  "use_ttl": true
}
````

It is similar in bind9: https://www.zytrax.com/books//dns/apa/ttl.html
> The default TTL for the zone is defined in BIND9 by the $TTL directive which must appear at the beginning of the zone file, that is, before any RR to which it will apply. This $TTL is used for any Resource Record which does not explicitly set the 'ttl' field.

</details>

Source**: [Infoblox REST API Nios 8.5 ref](https://www.infoblox.com/wp-content/uploads/infoblox-deployment-infoblox-rest-api.pdf) (p13/56)

## Views


````shell script
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-view.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.2"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host

curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-view.test.loc", "view":"another_view", "ipv4addrs":[{"ipv4addr":"4.4.4.2"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host

curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:host?name=test-infoblox-api-view.test.loc"

curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:host?name=test-infoblox-api-view.test.loc&view=default"

````

Output is 


````shell script
[vagrant@archlinux ~]$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>         -H "Content-Type: application/json" \
>         -X GET \
>         "https://$API_ENDPOINT/wapi/v2.5/record:host?name=test-infoblox-api-view.test.loc"
[
    {
        "_ref": "record:host/<uid>:test-infoblox-api-view.test.loc/another_view",
        "ipv4addrs": [
            {
                "_ref": "record:host_ipv4addr/<uid>:4.4.4.2/test-infoblox-api-view.test.loc/another_view",
                "configure_for_dhcp": false,
                "host": "test-infoblox-api-view.test.loc",
                "ipv4addr": "4.4.4.2"
            }
        ],
        "name": "test-infoblox-api-view.test.loc",
        "view": "another_view"
    },
    {
        "_ref": "record:host/<uid>:test-infoblox-api-view.test.loc/default",
        "ipv4addrs": [
            {
                "_ref": "record:host_ipv4addr/<uid>:4.4.4.2/test-infoblox-api-view.test.loc/default",
                "configure_for_dhcp": false,
                "host": "test-infoblox-api-view.test.loc",
                "ipv4addr": "4.4.4.2"
            }
        ],
        "name": "test-infoblox-api-view.test.loc",
        "view": "default"
    }
]
[vagrant@archlinux ~]
$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>         -H "Content-Type: application/json" \
>         -X GET \
>         "https://$API_ENDPOINT/wapi/v2.5/record:host?name=test-infoblox-api-view.test.loc&view=default"
[
    {
        "_ref": "record:host/<uid>:test-infoblox-api-view.test.loc/default",
        "ipv4addrs": [
            {
                "_ref": "record:host_ipv4addr/<uid>:4.4.4.2/test-infoblox-api-view.test.loc/default",
                "configure_for_dhcp": false,
                "host": "test-infoblox-api-view.test.loc",
                "ipv4addr": "4.4.4.2"
            }
        ],
        "name": "test-infoblox-api-view.test.loc",
        "view": "default"
    }
]
````

So we have to mention the view in the search.