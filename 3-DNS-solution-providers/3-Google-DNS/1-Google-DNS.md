# Google DNS API

## Zone creation

`POST https://dns.googleapis.com/dns/v1/projects/{project}/{managedZones}`

Where body is

````json
{
  "kind": "dns#managedZone",
  "name": string,
  "dnsName": string,
  "description": string,
  "id": unsigned long,
  "nameServers": [
    string
  ],
  "creationTime": string,
  "dnssecConfig": {
    "kind": "dns#managedZoneDnsSecConfig",
    "state": string,
    "defaultKeySpecs": [
      {
        "kind": "dns#dnsKeySpec",
        "keyType": string,
        "algorithm": string,
        "keyLength": unsigned integer
      }
    ],
    "nonExistence": string
  },
  "nameServerSet": string,
  "visibility": string,
  "privateVisibilityConfig": {
    "kind": "dns#managedZonePrivateVisibilityConfig",
    "networks": [
      {
        "kind": "dns#managedZonePrivateVisibilityConfigNetwork",
        "networkUrl": string
      }
    ]
  },
  "forwardingConfig": {
    "kind": "dns#managedZoneForwardingConfig",
    "targetNameServers": [
      {
        "kind": "dns#managedZoneForwardingConfigNameServerTarget",
        "ipv4Address": string
      }
    ]
  },
  "labels": {
    (key): string
  }
}
````

**Source**: https://cloud.google.com/dns/docs/reference/v1/managedZones


## Record creation inside a zone

````shell script
POST https://dns.googleapis.com/dns/v1/projects/{project}/managedZones/{managedZone}/changes
````

Where for instance body for A record creation is

````shell script
{
  "kind": "dns#resourceRecordSet",
  "name": "example.com.",
  "rrdatas": [
      "1.2.3.4"
  ],
  "ttl": 86400,
  "type": "A"
}
````

**Source**: 
- https://cloud.google.com/dns/docs/reference/v1/resourceRecordSets
- https://cloud.google.com/dns/docs/records/json-record

## View creation, Zone creation inside a view and Map a network inside a view

This is managed in ZoneCreation body with field `privateVisibilityConfig`

We also use private zone for split view:
> Create split-horizon DNS architectures where identical or overlapping zones can coexist between public and private zones in Cloud DNS, or across different GCP networks.

From: https://cloud.google.com/blog/products/networking/introducing-private-dns-zones-resolve-to-keep-internal-networks-concealed

For this we create different projects (https://cloud.google.com/dns/docs/overview) using same zone.

Guess for azure also unlimited with different resource group.