# Azure API details 

## RecordSet

````shell script
PUT https://management.azure.com/subscriptions/subscriptionId/resourceGroups/resourceGroup1/providers/Microsoft.Network/privateDnsZones/privatezone1.com/A/recordA?api-version=2018-09-01

{
  "properties": {
    "metadata": {
      "key1": "value1"
    },
    "ttl": 3600,
    "aRecords": [
      {
        "ipv4Address": "1.2.3.4"
      }
    ]
  }
}
````

This will create recordA.privatezone1.com with  "ipv4Address": "1.2.3.4"
It is very interesting because we can see name is not in the body.
However I find `aRecords` in body redundant with the path.
