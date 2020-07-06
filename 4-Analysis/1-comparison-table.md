# Compare APIs                                                                              

In order to design a DNS auto API.
We assessed how different DNS API providers are working.
For this we compare 4 different API structures which are:
- Bind9
- Infloblox 2.x
- Azure DNS 
- Google DNS

For the following operations:

- View creation
- Zone creation inside a view
- Record creation inside a zone
- Map a network inside a view

Below are the comparison tables:                                                                                                                                                                            
                                                                                                                                                                                         
| Techno       | View creation |  
| --------     | ----------- |
| Bind9        | `view "myview1" { match-clients { "view1"; }; [ZONE DEF]};` | 
| Infoblox 2.x | `curl -k -u $USERNAME:$PASSWORD -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/view" -d '{"name": "scoulomb-view"}'`*| 
| Azure DNS    | To have view equivalent we should create a zone with same name using public and private API                                                                                                                                                                                    
| Google DNS   | Use private DNS zone

(*) I use direct [view creation](../3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md#we-could-create-a-custom-view-directly-without-network)
                                                                        
| Techno       | Zone creation (inside a view)
| --------     | ----------- | 
| Bind9        |`zone "mylabserver.com" { type master; file "/etc/bind/view1-fwd.mylabserver.com.db"; }; ` |
| Infoblox 2.x | `curl -k -u $USERNAME:$PASSWORD -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/zone_auth?_return_fields%2B=fqdn,network_view&_return_as_object=1" -d '{"fqdn": "mylabserver-scoulomb.com","view": "scoulomb-view"}'` |
| Azure Public DNS | `curl -X PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/mylabserver.com?api-version=2018-05-01`
| Azure Private DNS | `curl -X PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/mylabserver.com?api-version=2018-09-01`
| Google DNS   | `POST https://dns.googleapis.com/dns/v1/projects/{project}/mylabserver.com` (body omitted) |

View is not mandatory, in bind API the zone can be created outside of a view. 
Infoblox use a default view.
For Azure DNS to not use view, do not create the same zone with public and private API. 
For Google do not create zone with same name in different project with private and or public visibility
 
                                                                                                                                                                                               
| Techno       |  Record (set) creation (inside a zone) |
| --------     | ----------- 
| Bind9        |  `scoulomb  IN  A 41.41.41.41` |
| Infoblox 2.x | `curl -k -u $USERNAME:$PASSWORD -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/record:host?_return_fields%2B=name,network_view&_return_as_object=1" -d '{"name":"host.mylabserver-scoulomb.com","ipv4addrs": [{"ipv4addr":"42.42.42.42"}],"view": "scoulomb-view"}'`
| Azure Public DNS | `curl -X PUT -d '{"properties":{"metadata":{"key1":"value1"},"ttl":3600,"aRecords":[{"ipv4Address":"1.2.3.4"}]}}' https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/mylbaserver.com/A/scoulomb?api-version=2018-05-01`
| Azure Private DNS | `curl -X PUT -d '{"properties":{"metadata":{"key1":"value1"},"ttl":3600,"aRecords":[{"ipv4Address":"1.2.3.4"}]}}' https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/mylabserver.com/A/scoulomb?api-version=2018-09-01`
| Google DNS   | `curl -X POST  -d '{"kind":"dns#resourceRecordSet","name":"example.com.","rrdatas":["1.2.3.4"],"ttl":86400,"type":"A"}' https://dns.googleapis.com/dns/v1/projects/{project}/managedZones/{managedZone}/changes`

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
</details>

| Techno       |  Map a network to a view |
| --------     | ----------- 
| Bind9        |  `acl "view1" { 172.17.0.0/28; };` |
| Infoblox 2.x |  [Procedure described here](../3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md#how-to-have-a-different-answer-based-on-client-ip-with-the-view-mechanism-as-done-with-bind9)*|
| Azure Public DNS | `NA`
| Azure Private DNS | [Procedure on Azure website](https://docs.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal#link-the-virtual-network)
| Google DNS  | This is managed in `ZoneCreation body` with field `privateVisibilityConfig`                                                                                                                                                                                                

(*) It should not be confused with [network view and network](../3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md#Infoblox-Network-view-and-View-and-Zone-creation).
                                                                                                                                                                                                                                                                                                                                                                
**Source for comparison:**    

- [Bind 9](../2-advanced-bind/2-bind-views/docker-bind-dns)                                                                                                                     
- [Infoblox](../3-DNS-solution-providers/1-Infoblox/1-Infoblox-API-overview.md#Infoblox-Network-view-and-View-and-Zone-creation)
- [Azure DNS](../3-DNS-solution-providers/2-Azure-DNS)
- [Google DNS](../3-DNS-solution-providers/3-Google-DNS/1-Google-DNS.md)
- [View comparison](1-comparison-table.md)