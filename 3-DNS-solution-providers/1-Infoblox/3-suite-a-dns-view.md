# Questions on Infoblox behaviour in different views

> Warning: This file is generated from the jupyter notebook. Do not edit by hand. Generate it instead.


```bash
jupyter nbconvert 3-suite-a-dns-view.ipynb --to markdown
```

    [NbConvertApp] Converting notebook 3-suite-a-dns-view.ipynb to markdown
    [NbConvertApp] Writing 5141 bytes to 3-suite-a-dns-view.md


## All records reminder



All the check we have done so far were in default what is the view behavior with record in different zone?

Taking example here from [1] [Infoblox prevents from creating host, A, AAAA record with same name a CNAME record](https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md#Infoblox-prevents-from-creating-host-or-A-or-AAAA-record-with-same-name-as-a-CNAME-record).




```bash
sudo systemd-resolve --flush-caches

export API_ENDPOINT="" # or the DNS IP

UUID=$(cat /proc/sys/kernel/random/uuid)

export entry_name="test-$UUID"


echo "Generate CNAME and HOST with same name in same view"

payload_infoblox_cname=$(cat <<EOF
{
    "name": "$entry_name.test.loc",
    "view": "default",
    "canonical":"tes4.test.loc"
}
EOF
)

payload_infoblox_host=$(cat <<EOF
{
    "name": "$entry_name.test.loc",
    "view": "default",
    "ipv4addrs":[{"ipv4addr":"4.4.4.2"}]
}
EOF
)


echo $payload_infoblox_cname | jq -M
echo $payload_infoblox_host | jq -M



echo "Create CNAME and HOST with same name in same view, expect Infoblox to raise error"


curl -k -u admin:infoblox  \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox_cname" \
        https://$API_ENDPOINT/wapi/v2.5/record:cname

curl -k -u admin:infoblox  \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox_host" \
        https://$API_ENDPOINT/wapi/v2.5/record:host




echo "Create custom view"

export VIEW_REF="None"
export CREATE_OUTPUT=$(curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/view" -d '{"name": "scoulomb-view"}')
export VIEW_REF=$(echo $CREATE_OUTPUT | tr -d '"')
echo "Create output is $CREATE_OUTPUT"
echo "Ref is $VIEW_REF" # be careful in case of conflict it fails and VIEW_REF var keeps old value (this is why we set it to None to not keep an old id, cf. clean-up section)

echo "Create zone"
curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/zone_auth?_return_fields%2B=fqdn,network_view&_return_as_object=1" -d \
'{"fqdn": "test.loc","view": "scoulomb-view"}'


echo "Create HOST with same name in different view, expect Infoblox to NOT raise error as different view"


payload_infoblox_host_custom_view=$(cat <<EOF
{
    "name": "$entry_name.test.loc",
    "view": "scoulomb-view",
    "ipv4addrs":[{"ipv4addr":"4.4.4.2"}]
}
EOF
)

curl -k -u admin:infoblox  \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload_infoblox_host_custom_view" \
        https://$API_ENDPOINT/wapi/v2.5/record:host


curl -k -u admin:infoblox -H 'content-type: application/json' -X DELETE "https://$API_ENDPOINT/wapi/v2.5/$VIEW_REF"



```

    Generate CNAME and HOST with same name in same view
    {
      "name": "test-a1558479-bf3d-4370-8cbe-499fc1648f4f.test.loc",
      "view": "default",
      "canonical": "tes4.test.loc"
    }
    {
      "name": "test-a1558479-bf3d-4370-8cbe-499fc1648f4f.test.loc",
      "view": "default",
      "ipv4addrs": [
        {
          "ipv4addr": "4.4.4.2"
        }
      ]
    }
    Create CNAME and HOST with same name in same view, expect Infoblox to raise error
    "record:cname/ZG5zLmJpbmRfY25hbWUkLl9kZWZhdWx0LmxvYy50ZXN0LnRlc3QtYTE1NTg0NzktYmYzZC00MzcwLThjYmUtNDk5ZmMxNjQ4ZjRm:test-a1558479-bf3d-4370-8cbe-499fc1648f4f.test.loc/default"{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The record 'test-a1558479-bf3d-4370-8cbe-499fc1648f4f.test.loc' already exists.)", 
      "code": "Client.Ibap.Data.Conflict", 
      "text": "The record 'test-a1558479-bf3d-4370-8cbe-499fc1648f4f.test.loc' already exists."
    }Create custom view
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100    70    0    45  100    25     41     22  0:00:01  0:00:01 --:--:--    63
    Create output is "view/ZG5zLnZpZXckLjQ0NA:scoulomb-view/false"
    Ref is view/ZG5zLnZpZXckLjQ0NA:scoulomb-view/false
    Create zone
    {
        "result": {
            "_ref": "zone_auth/ZG5zLnpvbmUkLjQ0NC5sb2MudGVzdA:test.loc/scoulomb-view", 
            "fqdn": "test.loc", 
            "network_view": "default", 
            "view": "scoulomb-view"
        }
    }Create HOST with same name in different view, expect Infoblox to NOT raise error as different view
    "record:host/ZG5zLmhvc3QkLjQ0NC5sb2MudGVzdC50ZXN0LWExNTU4NDc5LWJmM2QtNDM3MC04Y2JlLTQ5OWZjMTY0OGY0Zg:test-a1558479-bf3d-4370-8cbe-499fc1648f4f.test.loc/scoulomb-view""view/ZG5zLnZpZXckLjQ0NA:scoulomb-view/false"

Checks are applied in a given view
