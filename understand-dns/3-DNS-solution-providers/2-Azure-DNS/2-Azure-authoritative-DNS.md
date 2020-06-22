# Azure authoritative DNS

They make the distinction between public and private DNS.

## Public DNS

Creation is described here in Azure [website](https://docs.microsoft.com/en-us/azure/dns/dns-getstarted-portal).

For instance in powershell

[Source](https://docs.microsoft.com/en-us/azure/dns/dns-getstarted-powershell)

### We start creating a resource group


````shell script
New-AzResourceGroup -name MyResourceGroup -location "eastus"
````

From [doc](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview#terminology) a resource group is :
> A container that holds related resources for an Azure solution. 

### We create a zone, and withing a zone a record set 

````shell script
New-AzDnsZone -Name contoso.xyz -ResourceGroupName MyResourceGroup
New-AzDnsRecordSet -Name www -RecordType A -ZoneName contoso.xyz -ResourceGroupName MyResourceGroup -Ttl 3600 -DnsRecords (New-AzDnsRecordConfig -IPv4Address "10.10.10.10")
````

A record set simnlarly to infoblox hostrecord enables to have several IP addreess for same DNS.
Here is a [difference](https://docs.microsoft.com/en-us/azure/dns/dns-operations-recordsets-portal) between Azure simple record and record set:
> It's important to understand the difference between DNS record sets and individual DNS records. A record set is a collection of records in a zone that have the same name and are the same type.

Not in [portal quick start](https://docs.microsoft.com/en-us/azure/dns/dns-operations-recordsets-portal) they used a simple record.

### Get name of the DNS which contains our zone and target it

````
Get-AzDnsRecordSet -ZoneName contoso.xyz -ResourceGroupName MyResourceGroup # List all record in the zone
Get-AzDnsRecordSet -ZoneName contoso.xyz -ResourceGroupName MyResourceGroup -RecordType ns # List ns record in the zone and return IP of dns derver
````

As seen [here for ns record](../../1-basic-bind-lxa/p2-1-zz-note-on-recursive-and-authoritative-dns.md#There-are-2-special-records-ns-and-soa).

````shell script
nslookup www.contoso.xyz ns1-08.azure-dns.com.
````

`ns1-08.azure-dns.com.` ip of DNS server returned from `Get` cmdlet.

## Private DNS

It is described [here](https://docs.microsoft.com/en-us/azure/dns/private-dns-getstart


### We start creating a resource group


````shell script
New-AzResourceGroup -name MyResourceGroup -location "eastus"
````

### We create a zone, and withing a zone a record set 

But this time the zone is `AzPrivateDnsZone `.
And this `AzPrivateDnsZone` is linked to an `AzVirtualNetworkSubnetConfig`

 

````shell script
Install-Module -Name Az.PrivateDns -force

$backendSubnet = New-AzVirtualNetworkSubnetConfig -Name backendSubnet -AddressPrefix "10.2.0.0/24"
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName MyAzureResourceGroup `
  -Location eastus `
  -Name myAzureVNet `
  -AddressPrefix 10.2.0.0/16 `
  -Subnet $backendSubnet

$zone = New-AzPrivateDnsZone -Name private.contoso.com -ResourceGroupName MyAzureResourceGroup

$link = New-AzPrivateDnsVirtualNetworkLink -ZoneName private.contoso.com `
  -ResourceGroupName MyAzureResourceGroup -Name "mylink" `
  -VirtualNetworkId $vnet.id -EnableRegistration

#-----

New-AzPrivateDnsRecordSet -Name db -RecordType A -ZoneName private.contoso.com `
   -ResourceGroupName MyAzureResourceGroup -Ttl 3600 `
   -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address "10.2.0.4")

````

We will also create VM as dns entry will be created for this VM automatically

````shell script
New-AzVm `
    -ResourceGroupName "myAzureResourceGroup" `
    -Name "myVM01" `
    -Location "East US" `
    -subnetname backendSubnet `
    -VirtualNetworkName "myAzureVnet" `
    -addressprefix 10.2.0.0/24 `
    -OpenPorts 3389

New-AzVm `
    -ResourceGroupName "myAzureResourceGroup" `
    -Name "myVM02" `
    -Location "East US" `
    -subnetname backendSubnet `
    -VirtualNetworkName "myAzureVnet" `
    -addressprefix 10.2.0.0/24 `
    -OpenPorts 3389
````



### Get name of the DNS which contains our zone and target it

````
# Connect to a VM
# Open fw
New-NetFirewallRule –DisplayName "Allow ICMPv4-In" –Protocol ICMPv4

````

````shell script
ping myVM01.private.contoso.com
ping db.private.contoso.com
````

