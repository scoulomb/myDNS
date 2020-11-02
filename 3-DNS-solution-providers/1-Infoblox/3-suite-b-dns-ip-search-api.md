# IP checks

> Warning: This file is generated from the jupyter notebook. Do not edit by hand. Generate it instead.

Objective: prevent records from using same IP in same view.


```bash
jupyter nbconvert 3-suite-b-dns-ip-search-api.ipynb --to markdown # --output=3-suite-dns-ip-search-api.md
```

    [NbConvertApp] Converting notebook 3-suite-b-dns-ip-search-api.ipynb to markdown
    [NbConvertApp] Writing 11626 bytes to 3-suite-b-dns-ip-search-api.md


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

## But filtering on address is not possible with all records api endpoint 


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

## Notes

This ensures a bijection IP <-> FQDN
<!-- And name check != -->
All this checks are policy checks.
No check is performed bty Infoblox on IP.


## API comments


- 1/ Infoblox Search API does not enable to filter on the view unlike `AllRecords`, thus a filtering on view needed
- 2/ Unlike check_duplicate_name, the check on duplicate IP is not dependent on record type. We consider all type of records.
- 3/ based comment here:
https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md#we-can-also-create-several-a-with-the-same-name-and-different-ip
> We say record type is part of the key because we can see that we have IP 4.4.4.1 defined twice as a A and Host.
https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md#we-can-not-create-several-host-record-with-same-name-with-different-ip

````
If we do a find there: 

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        https://$API_ENDPOINT/wapi/v2.6/search?address=4.4.4.1 | jq -M


[vagrant@archlinux dns-automation]$ curl -k -u admin:infoblox \
>         -H "Content-Type: application/json" \
>         -X GET \
>         https://$API_ENDPOINT/wapi/v2.6/search?address=4.4.4.1 | jq -M
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  5308    0  5308    0     0  11640      0 --:--:-- --:--:-- --:--:-- 11640
[
  {
    "_ref": "record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0Lm15dHN0cmVjb3Jk:mytstrecord.test.loc/default",
    "ipv4addrs": [
      {
        "_ref": "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuX2RlZmF1bHQubG9jLnRlc3QubXl0c3RyZWNvcmQuNC40LjQuMS4:4.4.4.1/mytstrecord.test.loc/default",
        "configure_for_dhcp": false,
        "host": "mytstrecord.test.loc",
        "ipv4addr": "4.4.4.1"
      },
      {
        "_ref": "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuX2RlZmF1bHQubG9jLnRlc3QubXl0c3RyZWNvcmQuNC40LjQuMi4:4.4.4.2/mytstrecord.test.loc/default",
        "configure_for_dhcp": false,
        "host": "mytstrecord.test.loc",
        "ipv4addr": "4.4.4.2"
      }
    ],
    "name": "mytstrecord.test.loc",
    "view": "default"
  },
  {
    "_ref": "record:a/ZG5zLmJpbmRfYSQuX2RlZmF1bHQubG9jLnRlc3QsbXl0c3RyZWNvcmQsNC40LjQuMQ:mytstrecord.test.loc/default",
    "ipv4addr": "4.4.4.1",
    "name": "mytstrecord.test.loc",
    "view": "default"
  },
````

We have to return the type and the name, as same IP can be defined twice for a given name as host and A, but not twice as A or HostRecord with same IP for a given name
Otherwise we would return twice the same name for no obvious reason for automation client.


- 4/ Search API can not return the record type unlike AllRecords something like `&_return_fields=name` `&_return_as_object=1` does not work here.
We have to extract if from _ref

- 5/ Name field contain the zone unlike AllRecords in (check_duplicate_name)
<!--
(as comment here, https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md
> Note Infoblox API is not consistent)
-->

Note https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md#infoblox-find-api---check-duplicate-v2-can-we-do-better-and-do-a-single-call-for-txt-and-a
AllRecord has a special type in _ref unlike here!!
And end of ref does not contain the zone unlike here (at least consistent with name field)

<!--
DNS PR#61
all comment judged clear including ut
-->
