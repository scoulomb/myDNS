# Azure REST API


## Create a zone 


````shell script
# Public REST API
PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}?api-version=2018-05-01
# Private REST API
PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}?api-version=2018-09-01
````

Source is:
- https://docs.microsoft.com/en-us/rest/api/dns/zones/createorupdate
- https://docs.microsoft.com/en-us/rest/api/dns/privatedns/privatezones/createorupdate

## Create a RecordSet

````shell script
# Public REST API
PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/dnsZones/{zoneName}/{recordType}/{relativeRecordSetName}?api-version=2018-05-01
# Private REST API
PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/privateDnsZones/{privateZoneName}/{recordType}/{relativeRecordSetName}?api-version=2018-09-01
````

Source is:
- https://docs.microsoft.com/en-us/rest/api/dns/zones/createorupdate
- https://docs.microsoft.com/en-us/rest/api/dns/privatedns/recordsets/createorupdate

Both public and private API, `dnsZones` becomes  `privateDnsZones` in private API.
