# IP checks

> Warning: This file is generated from the jupyter notebook. Do not edit by hand. Generate it instead.

Objective: prevent records from using same IP in same view.


```bash
jupyter nbconvert 3-suite-b-ip-search-non-homogeneous.ipynb --to markdown
```

    [NbConvertApp] Converting notebook 3-suite-b-ip-search-non-homogeneous.ipynb to markdown
    [NbConvertApp] Writing 13442 bytes to 3-suite-b-ip-search-non-homogeneous.md


## Search endpoint

<!-- inspired from echo "=== Create entry failure because of IP check, decoding error due to network created on purpose, matching the subnet of the IP check , which is not a record and can not be decoded for the case where we have a A + HOST conflict" in -->

We have particular case where search API does not necessarily return a record.
It can return a network.
We will reproduce the issue below.


### Environment setup

Create view 


```bash
API_ENDPOINT="" 

echo "=== Create a proto test view"
# create my test view
# See https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md

curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/view" -d '{"name": "scoulomb-proto-view"}'
export view_id=$(curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/view?name=scoulomb-proto-view" |  jq .[0]._ref |  tr -d '"')
echo $view_id

curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/zone_auth?_return_fields%2B=fqdn,network_view&_return_as_object=1" -d \
'{"fqdn": "os.amadeus.net","view": "scoulomb-proto-view"}'

```

    === Create a proto test view
    "view/ZG5zLnZpZXckLjkyNw:scoulomb-proto-view/false"  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100   153    0   153    0     0    496      0 --:--:-- --:--:-- --:--:--   496
    view/ZG5zLnZpZXckLjkyNw:scoulomb-proto-view/false
    {
        "result": {
            "_ref": "zone_auth/ZG5zLnpvbmUkLjkyNy5uZXQuYW1hZGV1cy5vcw:os.amadeus.net/scoulomb-proto-view", 
            "fqdn": "os.amadeus.net", 
            "network_view": "default", 
            "view": "scoulomb-proto-view"
        }
    }

### Create network (sharing same subnet as A + HOST) and A + HOST (sharing same IP)


```bash
UUID=$(cat /proc/sys/kernel/random/uuid)
export entry_name_prefix="demo-test-$UUID"

IPV4_1=$((RANDOM % 256))
IPV4_2=$((RANDOM % 256))

export IPV4=$(printf "%d.%d.%d.%d\n" "$IPV4_1" "$IPV4_2" "$((RANDOM % 256))" "$((RANDOM % 256))")
echo "We will use ip " $IPV4
export NETWORK=$(printf "%d.%d.%d.%d/16\n" "$IPV4_1" "$IPV4_2" "0" "0")
echo "We will use network": $NETWORK

echo -e "\nCreate conflicting network and A + HOST\n"

payload_network=$(cat <<EOF
{"network": "$NETWORK"}
EOF
)

curl -k -u admin:infoblox \
      -H 'content-type: application/json'\
      -X POST \
      https://$API_ENDPOINT/wapi/v2.6/network \
      --data "$payload_network"


payload_infoblox=$(cat <<EOF
{
    "name": "$entry_name_prefix-XXXXX.os.amadeus.net",
    "view": "scoulomb-proto-view",
    "ipv4addr": "$IPV4"
}
EOF
)

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:a |jq -M


payload_infoblox=$(cat <<EOF
{
    "name": "$entry_name_prefix-TTTTTT.os.amadeus.net",
    "view": "scoulomb-proto-view",
    "ipv4addrs": [{"ipv4addr":"$IPV4"}]
}
EOF
)

curl -k -u admin:infoblox\
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:host
```

    We will use ip  58.137.97.25
    We will use network: 58.137.0.0/16
    
    Create conflicting network and A + HOST
    
    "network/ZG5zLm5ldHdvcmskNTguMTM3LjAuMC8xNi8w:58.137.0.0/16/default"  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100   379    0   227  100   152    652    436 --:--:-- --:--:-- --:--:--  1089
    "record:a/ZG5zLmJpbmRfYSQuOTI3Lm5ldC5hbWFkZXVzLm9zLGRlbW8tdGVzdC00MDVhNDQ2Ny1iNTJmLTQxYzktYTM4Yi01MzUxNjYzNzU2MGMteHh4eHgsNTguMTM3Ljk3LjI1:demo-test-405a4467-b52f-41c9-a38b-53516637560c-xxxxx.os.amadeus.net/scoulomb-proto-view"
    "record:host/ZG5zLmhvc3QkLjkyNy5uZXQuYW1hZGV1cy5vcy5kZW1vLXRlc3QtNDA1YTQ0NjctYjUyZi00MWM5LWEzOGItNTM1MTY2Mzc1NjBjLXR0dHR0dA:demo-test-405a4467-b52f-41c9-a38b-53516637560c-tttttt.os.amadeus.net/scoulomb-proto-view"

We find element by IP in Infoblox


```bash
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        https://$API_ENDPOINT/wapi/v2.6/search?address=$IPV4&_return_fields=name | jq -M

sleep 2 # for jupyter to not ove result to next cell
```

    [1] 14766
    [
        {
            "_ref": "record:a/ZG5zLmJpbmRfYSQuOTI3Lm5ldC5hbWFkZXVzLm9zLGRlbW8tdGVzdC00MDVhNDQ2Ny1iNTJmLTQxYzktYTM4Yi01MzUxNjYzNzU2MGMteHh4eHgsNTguMTM3Ljk3LjI1:demo-test-405a4467-b52f-41c9-a38b-53516637560c-xxxxx.os.amadeus.net/scoulomb-proto-view", 
            "ipv4addr": "58.137.97.25", 
            "name": "demo-test-405a4467-b52f-41c9-a38b-53516637560c-xxxxx.os.amadeus.net", 
            "view": "scoulomb-proto-view"
        }, 
        {
            "_ref": "record:host/ZG5zLmhvc3QkLjkyNy5uZXQuYW1hZGV1cy5vcy5kZW1vLXRlc3QtNDA1YTQ0NjctYjUyZi00MWM5LWEzOGItNTM1MTY2Mzc1NjBjLXR0dHR0dA:demo-test-405a4467-b52f-41c9-a38b-53516637560c-tttttt.os.amadeus.net/scoulomb-proto-view", 
            "ipv4addrs": [
                {
                    "_ref": "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuOTI3Lm5ldC5hbWFkZXVzLm9zLmRlbW8tdGVzdC00MDVhNDQ2Ny1iNTJmLTQxYzktYTM4Yi01MzUxNjYzNzU2MGMtdHR0dHR0LjU4LjEzNy45Ny4yNS4:58.137.97.25/demo-test-405a4467-b52f-41c9-a38b-53516637560c-tttttt.os.amadeus.net/scoulomb-proto-view", 
                    "configure_for_dhcp": false, 
                    "host": "demo-test-405a4467-b52f-41c9-a38b-53516637560c-tttttt.os.amadeus.net", 
                    "ipv4addr": "58.137.97.25"
                }
            ], 
            "name": "demo-test-405a4467-b52f-41c9-a38b-53516637560c-tttttt.os.amadeus.net", 
            "view": "scoulomb-proto-view"
        }, 
        {
            "_ref": "network/ZG5zLm5ldHdvcmskNTguMTM3LjAuMC8xNi8w:58.137.0.0/16/default", 
            "network": "58.137.0.0/16", 
            "network_view": "default"
        }
    ][1]+  Done                    curl -k -u admin:infoblox -H "Content-Type: application/json" -X GET https://$API_ENDPOINT/wapi/v2.6/search?address=$IPV4


We had already seen this API could return record host, a, cname etc.So not homogeneous.
But it can return element which are not DNS records.
It can return networkcontainer and network.

````
{
    "_ref": "network/ZG5zLm5ldHdvcmskMTIyLjIzMS4wLjAvMTYvMA:122.231.0.0/16/default", 
    "network": "122.231.0.0/16", 
    "network_view": "default"
}
````

This causes an issue, since network does not have a name and view. 
On server side this can cause a decoding error.


I will add a CNAME, and search by name to verify a DNS record has always a name and view.
From previous search by IP I expect to have only A and HOST (eventually AAAA).
So we create a CNAME.


```bash

payload_infoblox=$(cat <<EOF
{
    "name": "$entry_name_prefix-CNAME-VVVVVV.os.amadeus.net",
    "view": "scoulomb-proto-view",
    "canonical":"scoulomb.test.loc"
}
EOF
)

# https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md
curl -k -u admin:infoblox\
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox" \
        https://$API_ENDPOINT/wapi/v2.5/record:cname

```

    "record:cname/ZG5zLmJpbmRfY25hbWUkLjkyNy5uZXQuYW1hZGV1cy5vcy5kZW1vLXRlc3QtNDA1YTQ0NjctYjUyZi00MWM5LWEzOGItNTM1MTY2Mzc1NjBjLWNuYW1lLXZ2dnZ2dg:demo-test-405a4467-b52f-41c9-a38b-53516637560c-cname-vvvvvv.os.amadeus.net/scoulomb-proto-view"

And find by name to ensure CNAME has name and view


```bash
# https://ipam.illinois.edu/wapidoc/objects/search.html?highlight=search#search
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        https://$API_ENDPOINT/wapi/v2.6/search?fqdn~=$entry_name_prefix&_return_fields=name | jq -M

sleep 2
```

    [1] 14777
    [
        {
            "_ref": "record:host/ZG5zLmhvc3QkLjkyNy5uZXQuYW1hZGV1cy5vcy5kZW1vLXRlc3QtNDA1YTQ0NjctYjUyZi00MWM5LWEzOGItNTM1MTY2Mzc1NjBjLXR0dHR0dA:demo-test-405a4467-b52f-41c9-a38b-53516637560c-tttttt.os.amadeus.net/scoulomb-proto-view", 
            "ipv4addrs": [
                {
                    "_ref": "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuOTI3Lm5ldC5hbWFkZXVzLm9zLmRlbW8tdGVzdC00MDVhNDQ2Ny1iNTJmLTQxYzktYTM4Yi01MzUxNjYzNzU2MGMtdHR0dHR0LjU4LjEzNy45Ny4yNS4:58.137.97.25/demo-test-405a4467-b52f-41c9-a38b-53516637560c-tttttt.os.amadeus.net/scoulomb-proto-view", 
                    "configure_for_dhcp": false, 
                    "host": "demo-test-405a4467-b52f-41c9-a38b-53516637560c-tttttt.os.amadeus.net", 
                    "ipv4addr": "58.137.97.25"
                }
            ], 
            "name": "demo-test-405a4467-b52f-41c9-a38b-53516637560c-tttttt.os.amadeus.net", 
            "view": "scoulomb-proto-view"
        }, 
        {
            "_ref": "record:cname/ZG5zLmJpbmRfY25hbWUkLjkyNy5uZXQuYW1hZGV1cy5vcy5kZW1vLXRlc3QtNDA1YTQ0NjctYjUyZi00MWM5LWEzOGItNTM1MTY2Mzc1NjBjLWNuYW1lLXZ2dnZ2dg:demo-test-405a4467-b52f-41c9-a38b-53516637560c-cname-vvvvvv.os.amadeus.net/scoulomb-proto-view", 
            "canonical": "scoulomb.test.loc", 
            "name": "demo-test-405a4467-b52f-41c9-a38b-53516637560c-cname-vvvvvv.os.amadeus.net", 
            "view": "scoulomb-proto-view"
        }, 
        {
            "_ref": "record:a/ZG5zLmJpbmRfYSQuOTI3Lm5ldC5hbWFkZXVzLm9zLGRlbW8tdGVzdC00MDVhNDQ2Ny1iNTJmLTQxYzktYTM4Yi01MzUxNjYzNzU2MGMteHh4eHgsNTguMTM3Ljk3LjI1:demo-test-405a4467-b52f-41c9-a38b-53516637560c-xxxxx.os.amadeus.net/scoulomb-proto-view", 
            "ipv4addr": "58.137.97.25", 
            "name": "demo-test-405a4467-b52f-41c9-a38b-53516637560c-xxxxx.os.amadeus.net", 
            "view": "scoulomb-proto-view"
        }
    ][1]+  Done                    curl -k -u admin:infoblox -H "Content-Type: application/json" -X GET https://$API_ENDPOINT/wapi/v2.6/search?fqdn~=$entry_name_prefix


It confirms CNAME has a name and view.

## Clean-up


```bash
echo -e "\nDelete network\n"

nw_to_del_ref=$(curl -k -u admin:infoblox \
      -H 'content-type: application/json'\
      -X GET \
      https://$API_ENDPOINT/wapi/v2.6/network?network=$NETWORK | jq .[0]._ref | tr -d '"')

curl -k -u admin:infoblox \
      -H 'content-type: application/json'\
      -X GET \
      https://$API_ENDPOINT/wapi/v2.6/$nw_to_del_ref
# Note if we want to find only network which falls intro the range without knowing the range do
# https://$API_ENDPOINT/wapi/v2.6/network?network~=172.17.162.0/24 with ~, which has same behavior as find (p47)

echo -e "\nDelete view\n"

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X DELETE \
        -d "$payload_infoblox" \
        "https://$API_ENDPOINT/wapi/v2.5/$view_id" |jq -M
```

    
    Delete network
    
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100   173    0   173    0     0    584      0 --:--:-- --:--:-- --:--:--   584
    {
        "_ref": "network/ZG5zLm5ldHdvcmskNTguMTM3LjAuMC8xNi8w:58.137.0.0/16/default", 
        "network": "58.137.0.0/16", 
        "network_view": "default"
    }
    Delete view
    
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100   215    0    51  100   164     65    210 --:--:-- --:--:-- --:--:--   275
    "view/ZG5zLnZpZXckLjkyNw:scoulomb-proto-view/false"


## what is network

As we had seen here
https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md#experiment

The network is a different concept from netowrk view:
https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md#api-impact-and-wrapup

See also: https://www.infoblox.com/wp-content/uploads/infoblox-deployment-infoblox-rest-api.pdf (p57)

Network can be seen as a kind of folder.


## What would be a fix

Here we had seen https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-suite-b-dns-ip-search-api.md#api-comments [1,2,3,4,5]

We have a point before [1,2,3,4,5] => [0], we need to fitler elements which have a none view or none name.
And before we need to make this element optional for decoding not to fail.

Also not we already had done to not fail where we had extra field.

````
# EXCLUDE is used to decode a JSON where a field is not present in the Model.
return cast(SUB_MODEL, model_schema().load(data, unknown=marshmallow.EXCLUDE))
````

We could consider it as duplicate but here it is not the case.


<!--
See github scoulomb/private_script dns-auto/README_find_bug.md,
 
given vm sync use download as 
https://github.com/scoulomb/myk8s/blob/master/Setup/ArchDevVM/known-issues.md#workaround-4-use-rsync-instead-of-nfs -->
