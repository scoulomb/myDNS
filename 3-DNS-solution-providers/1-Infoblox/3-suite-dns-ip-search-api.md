# IP checks

> Warning: This file is generated from the jupyter notebook. Do not edit by hand. Generate it instead.


```bash
jupyter nbconvert 3-suite-dns-ip-search-api.ipynb --to markdown --output=3-suite-dns-ip-search-api.md
```

## All records reminder

As a reminder this is API call we used for FQDN check

<!-- I inspire from s6 demo for creation and for view creation https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md -->


```bash
sudo systemd-resolve --flush-caches

export API_ENDPOINT=""

echo "Create view"

export VIEW_REF="None"
export CREATE_OUTPUT=$(curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/view" -d '{"name": "scoulomb-view"}')
export VIEW_REF=$(echo $CREATE_OUTPUT | tr -d '"')
echo "Create output is $CREATE_OUTPUT"
echo "Ref is $VIEW_REF" # be careful in case of conflict it fails and VIEW_REF var keeps old value (this is why we set it to None to not keep an old id, cf. clean-up section)

echo "Create zone"
curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/zone_auth?_return_fields%2B=fqdn,network_view&_return_as_object=1" -d \
'{"fqdn": "test.loc","view": "scoulomb-view"}'

echo "Create host"
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"toto.test.loc","view":"scoulomb-view","ipv4addrs":[{"ipv4addr":"4.4.4.1"}, {"ipv4addr":"5.5.5.5"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host

echo "Create A"
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"toto.test.loc", "view": "scoulomb-view","ipv4addr":"5.5.5.5"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a

echo "Retrieve by name"
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/allrecords?name=toto&view=scoulomb-view&zone=test.loc"


```

    Create view
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100    70    0    45  100    25     41     23  0:00:01  0:00:01 --:--:--    64
    Create output is "view/ZG5zLnZpZXckLjExNg:scoulomb-view/false"
    Ref is view/ZG5zLnZpZXckLjExNg:scoulomb-view/false
    Create zone
    {
        "result": {
            "_ref": "zone_auth/ZG5zLnpvbmUkLjExNi5sb2MudGVzdA:test.loc/scoulomb-view", 
            "fqdn": "test.loc", 
            "network_view": "default", 
            "view": "scoulomb-view"
        }
    }Create host
    "record:host/ZG5zLmhvc3QkLjExNi5sb2MudGVzdC50b3Rv:toto.test.loc/scoulomb-view"Create A
    "record:a/ZG5zLmJpbmRfYSQuMTE2LmxvYy50ZXN0LHRvdG8sNS41LjUuNQ:toto.test.loc/scoulomb-view"Retrieve by name
    [
        {
            "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5ob3N0JC4xMTYubG9jLnRlc3QudG90bw:toto", 
            "comment": "", 
            "name": "toto", 
            "type": "record:host_ipv4addr", 
            "view": "scoulomb-view", 
            "zone": "test.loc"
        }, 
        {
            "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5ob3N0JC4xMTYubG9jLnRlc3QudG90bw:toto", 
            "comment": "", 
            "name": "toto", 
            "type": "record:host_ipv4addr", 
            "view": "scoulomb-view", 
            "zone": "test.loc"
        }, 
        {
            "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5iaW5kX2EkLjExNi5sb2MudGVzdCx0b3RvLDUuNS41LjU:toto", 
            "comment": "", 
            "name": "toto", 
            "type": "record:a", 
            "view": "scoulomb-view", 
            "zone": "test.loc"
        }
    ]

## But filtering on address is not possble with all records api endpoint 


```bash
sudo systemd-resolve --flush-caches


curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/allrecords?address=5.5.5.5&zone=test.loc"
        
        
# curl -k -u admin:infoblox \
#         -H "Content-Type: application/json" \
#         -X GET \
#         "https://$API_ENDPOINT/wapi/v2.5/allrecords?comment=&zone=test.loc"
```

    { "Error": "AdmConProtoError: Field is not searchable: address", 
      "code": "Client.Ibap.Proto", 
      "text": "Field is not searchable: address"
    }

## Search endpoint

But we can use search endpoint but it does not enable to filter on the view, client will have to do it.
If it was we could actually filter one element only.
However we have spotted the issue of type union, array elements are not homogenous
Unlike FQDN check we do not have to filter on top of the type provided by Infoblox


```bash
curl -k -u admin:infoblox "https://$API_ENDPOINT/wapi/v2.6/search?address=5.5.5.5&_return_as_object=1"
```

    {
        "result": [
            {
                "_ref": "record:a/ZG5zLmJpbmRfYSQuMS56b25lLmd1bm5hcix0ZXN0LDUuNS41LjU:test.gunnar.zone/Office", 
                "ipv4addr": "5.5.5.5", 
                "name": "test.gunnar.zone", 
                "view": "Office"
            }, 
            {
                "_ref": "record:a/ZG5zLmJpbmRfYSQuNS5jb20uYW1hdHN0LHozLDUuNS41LjU:z3.amatst.com/Internet", 
                "ipv4addr": "5.5.5.5", 
                "name": "z3.amatst.com", 
                "view": "Internet"
            }, 
            {
                "_ref": "record:host/ZG5zLmhvc3QkLjExNi5sb2MudGVzdC50b3Rv:toto.test.loc/scoulomb-view", 
                "ipv4addrs": [
                    {
                        "_ref": "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuMTE2LmxvYy50ZXN0LnRvdG8uNC40LjQuMS4:4.4.4.1/toto.test.loc/scoulomb-view", 
                        "configure_for_dhcp": false, 
                        "host": "toto.test.loc", 
                        "ipv4addr": "4.4.4.1"
                    }, 
                    {
                        "_ref": "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuMTE2LmxvYy50ZXN0LnRvdG8uNS41LjUuNS4:5.5.5.5/toto.test.loc/scoulomb-view", 
                        "configure_for_dhcp": false, 
                        "host": "toto.test.loc", 
                        "ipv4addr": "5.5.5.5"
                    }
                ], 
                "name": "toto.test.loc", 
                "view": "scoulomb-view"
            }, 
            {
                "_ref": "record:a/ZG5zLmJpbmRfYSQuMTE2LmxvYy50ZXN0LHRvdG8sNS41LjUuNQ:toto.test.loc/scoulomb-view", 
                "ipv4addr": "5.5.5.5", 
                "name": "toto.test.loc", 
                "view": "scoulomb-view"
            }, 
            {
                "_ref": "record:a/ZG5zLmJpbmRfYSQuMTMubG9jLnRlc3QsaG9zdDUsNS41LjUuNQ:host5.test.loc/Office_api_test", 
                "ipv4addr": "5.5.5.5", 
                "name": "host5.test.loc", 
                "view": "Office_api_test"
            }
        ]
    }

## Clean-up


```bash
export VIEW_REF_FIND=$(curl -k -u admin:infoblox "https://$API_ENDPOINT/wapi/v2.6/view?name=scoulomb-view" | jq '.[0]._ref' | tr -d '"')
echo $VIEW_REF
echo $VIEW_REF_FIND
# here we can use VIEW_REF (from create) or  VIEW_REF_FIND (from find). Find output is less likely to fail.
curl -k -u admin:infoblox -H 'content-type: application/json' -X DELETE "https://$API_ENDPOINT/wapi/v2.5/$VIEW_REF_FIND"
```

      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100   141    0   141    0     0    427      0 --:--:-- --:--:-- --:--:--   425
    view/ZG5zLnZpZXckLjExNg:scoulomb-view/false
    view/ZG5zLnZpZXckLjExNg:scoulomb-view/false
    "view/ZG5zLnZpZXckLjExNg:scoulomb-view/false"

This ensures a bijection IP <-> FQDN
<!-- And name check != -->
All this checks are policy checks.
