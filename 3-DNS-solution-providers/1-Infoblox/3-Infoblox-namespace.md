# DNS

## Infoblox prevents from creating host or A or AAAA record with same name as a CNAME record

I will prove that in Infoblox CNAME records shares the same namespace as (Host, A, AAAA) though they have different API endpoint.
However A, AAAA and Host have a distinct namespace.
This will also impact check on names.

````shell script
export API_ENDPOINT="" # or the DNS IP


curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api.test.loc","canonical":"tes4.test.loc"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:cname
	

curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.2"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host

		
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api.test.loc","ipv4addr":"10.10.10.2"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a

curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api.test.loc","ipv6addr":"2001:0db8:0000:0000:0000:ff00:0042:8329"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:aaaa
````
		
Output is 		

````shell script
$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>         -H "Content-Type: application/json" \
>         -X POST \
>         -d '{"name":"test-infoblox-api.test.loc","canonical":"tes4.test.loc"}' \
>         https://$API_ENDPOINT/wapi/v2.5/record:cname
"record:cname/<CNAME-Unique-id>:test-infoblox-api.test.loc/default"
$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>         -H "Content-Type: application/json" \
>         -X POST \
>         -d '{"name":"test-infoblox-api.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.2"}]}' \
>         https://$API_ENDPOINT/wapi/v2.5/record:host
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The record 'test-infoblox-api.test.loc' already exists.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "The record 'test-infoblox-api.test.loc' already exists."
}$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>         -H "Content-Type: application/json" \
>         -X POST \
>         -d '{"name":"test-infoblox-api.test.loc","ipv4addr":"10.10.10.2"}' \
>         https://$API_ENDPOINT/wapi/v2.5/record:a
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The record 'test-infoblox-api.test.loc' already exists.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "The record 'test-infoblox-api.test.loc' already exists."
$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>         -H "Content-Type: application/json" \
>         -X POST \
>         -d '{"name":"test-infoblox-api.test.loc","ipv6addr":"2001:0db8:0000:0000:0000:ff00:0042:8329"}' \
>         https://$API_ENDPOINT/wapi/v2.5/record:aaaa
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The record 'test-infoblox-api.test.loc' already exists.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "The record 'test-infoblox-api.test.loc' already exists."
}
````

It is clearly visible here that I can not create Host, AAAA and A with same name as CNAME.
And it makes sense to prevent this, otherwise we would turn into circle.
Same point is raised in questions [here](../../1-basic-bind-lxa/p2-1-xx-questions.md#can-i-have-1-a-record-and-1-cname-with-same-dns-name).

**We have same behavior with Gandi** -> error in UI.

And for the retrieve (more a find) I have to make the distinction:

````shell script
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
       -H "Content-Type: application/json" \
       -X GET \
       "https://$API_ENDPOINT/wapi/v2.5/record:a?name=test-infoblox-api.test.loc"
  

curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
       -H "Content-Type: application/json" \
       -X GET \
       "https://$API_ENDPOINT/wapi/v2.5/record:cname?name=test-infoblox-api.test.loc"

# No top level resource
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
       -H "Content-Type: application/json" \
       -X GET \
       "https://$API_ENDPOINT/wapi/v2.5/record?name=test-infoblox-api.test.loc"
````   

Output is

````shell script

$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>        -H "Content-Type: application/json" \
>        -X GET \
>        "https://$API_ENDPOINT/wapi/v2.5/record:a?name=test-infoblox-api.test.loc"
[]$
$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>        -H "Content-Type: application/json" \
>        -X GET \
>        "https://$API_ENDPOINT/wapi/v2.5/record:cname?name=test-infoblox-api.test.loc"
[
    {
        "_ref": "record:cname/<CNAME-Unique-id>:test-infoblox-api.test.loc/default",
        "canonical": "tes4.test.loc",
        "name": "test-infoblox-api.test.loc",
        "view": "default"
    }
]

$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>        -H "Content-Type: application/json" \
>        -X GET \
>        "https://$API_ENDPOINT/wapi/v2.5/record?name=test-infoblox-api.test.loc"
{ "Error": "AdmConProtoError: Unknown object type (record)",
  "code": "Client.Ibap.Proto",
  "text": "Unknown object type (record)"
````

Also note the API is returning an array, because it is generic for any search on a given field
Check a search on the view field for instance we will have several results.
For a search by name as we can not create a record with duplicate name (including a cname with same name as hsot record)
Thus I expect the search to always return a single element.

Same for the lookup as not A or AAAA, we have to mention the [type](../../4-Analysis/2-compare-apis.md#Parallel-with-nslookup-and-dig-API):

````shell script
$ nslookup test-infoblox-api.test.loc $API_ENDPOINT
Server:         <YOUR DNS IP = API ENDPOINT>
Address:        <YOUR DNS IP = API ENDPOINT>#<nb>

** server can't find test-infoblox-api.test.loc: NXDOMAIN

$ nslookup -type=CNAME test-infoblox-api.test.loc $API_ENDPOINT
Server:         <YOUR DNS IP = API ENDPOINT>
Address:        <YOUR DNS IP = API ENDPOINT>#<nb>

test-infoblox-api.test.loc      canonical name = tes4.test.loc.
````

## Infoblox does not prevent from creating A and AAAA and Host with same name 

**However if I do not create a CNAME, I can create an A, AAAA and Host with same name.**

````shell script
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-no-cname.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.2"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host

		
curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-no-cname.test.loc","ipv4addr":"10.10.10.2"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a

curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-no-cname.test.loc","ipv6addr":"2001:0db8:0000:0000:0000:ff00:0042:8329"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:aaaa
````

Output is

````shell script
$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>         -H "Content-Type: application/json" \
>         -X POST \
>         -d '{"name":"test-infoblox-api-no-cname.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.2"}]}' \ >         https://$API_ENDPOINT/wapi/v2.5/record:host
"record:host/<id1>:test-infoblox-api-no-cname.test.loc/default"$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>         -H "Content-Type: application/json" \
>         -X POST \
>         -d '{"name":"test-infoblox-api-no-cname.test.loc","ipv4addr":"10.10.10.2"}' \
>         https://$API_ENDPOINT/wapi/v2.5/record:a
"record:a/<id2>:test-infoblox-api-no-cname.test.loc/default"
$ curl -k -H "Authorization: Basic $(cat ~/admin-credentials | base64)" \
>         -H "Content-Type: application/json" \
>         -X POST \
>         -d '{"name":"test-infoblox-api-no-cname.test.loc","ipv6addr":"2001:0db8:0000:0000:0000:ff00:0042:8329"}' \
>         https://$API_ENDPOINT/wapi/v2.5/record:aaaa
"record:aaaa/<id3>:test-infoblox-api-no-cname.test.loc/default"
````

And nslookup output will be:

````shell script
$ nslookup test-infoblox-api-no-cname.test.loc $API_ENDPOINT
Server:         <YOUR DNS IP = API ENDPOINT>
Address:        <YOUR DNS IP = API ENDPOINT>#<nb>

Name:   test-infoblox-api-no-cname.test.loc
Address: 10.10.10.2
Name:   test-infoblox-api-no-cname.test.loc
Address: 4.4.4.2
Name:   test-infoblox-api-no-cname.test.loc
Address: 2001:db8::ff00:42:8329
# Here we have A and AAAA
$ nslookup -type=A test-infoblox-api-no-cname.test.loc $API_ENDPOINT
Server:         <YOUR DNS IP = API ENDPOINT>
Address:        <YOUR DNS IP = API ENDPOINT>#<nb>

Name:   test-infoblox-api-no-cname.test.loc
Address: 4.4.4.2
Name:   test-infoblox-api-no-cname.test.loc
Address: 10.10.10.2
# Here we have A
$ nslookup -type=AAAA test-infoblox-api-no-cname.test.loc $API_ENDPOINT
Server:         <YOUR DNS IP = API ENDPOINT>
Address:        <YOUR DNS IP = API ENDPOINT>#53

Name:   test-infoblox-api-no-cname.test.loc
Address: 2001:db8::ff00:42:8329
# Here we have AAAA
````

See why [here](../../4-Analysis/2-compare-apis.md#Parallel-with-nslookup-and-dig-API)

<details><summary>Note on dig results when several A and a host record with several IPs</summary>
<p>


#### Note on dig results when several A and a host records with several IPs

We will see  [that unlike A record we can not create several host with same even when the IP is different](#we-can-not-create-several-host-record-with-same-name-even-with-different-ip)

````shell script
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-no-cname-2.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.2"}, {"ipv4addr":"12.4.4.2"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-no-cname-2.test.loc","ipv4addr":"10.10.10.2"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-no-cname-2.test.loc","ipv6addr":"2001:0db8:0000:0000:0000:ff00:0042:8329"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:aaaa
````
Then `nslookup` will return:

````shell script
# here nslooup default type (A and AAAA), we return A and AAAA, We can see 1 host results in 2 A
➤ nslookup test-infoblox-api-no-cname-2.test.loc $API_ENDPOINT                                                                                                        
Server:         <DNS Server>
Address:        <DNS IP>#53

Name:   test-infoblox-api-no-cname-2.test.loc
Address: 12.4.4.2
Name:   test-infoblox-api-no-cname-2.test.loc
Address: 10.10.10.2
Name:   test-infoblox-api-no-cname-2.test.loc
Address: 4.4.4.2
Name:   test-infoblox-api-no-cname-2.test.loc
Address: 2001:db8::ff00:42:8329

# here we return all A. We can see 1 host results in 2 A
➤ nslookup -type=A test-infoblox-api-no-cname-2.test.loc $API_ENDPOINT                                                                                                
Server:         <DNS Server>
Address:        <DNS IP>#53

Name:   test-infoblox-api-no-cname-2.test.loc
Address: 10.10.10.2
Name:   test-infoblox-api-no-cname-2.test.loc
Address: 4.4.4.2
Name:   test-infoblox-api-no-cname-2.test.loc
Address: 12.4.4.2

# here we return alls AAAA
➤ nslookup -type=AAAA test-infoblox-api-no-cname-2.test.loc $API_ENDPOINT                                                                                             
Server:         <DNS Server>
Address:        <DNS IP>#53

Name:   test-infoblox-api-no-cname-2.test.loc
Address: 2001:db8::ff00:42:8329
````


</p>
</details>

## We can also create several A with the same name and different IP

Here I will create `myrecord.test.loc` pointing to 4 IP. 
Using a host record with 2 IP and 2 A records.
**When doing nslookup we expect to get the 4 records**


````shell script

export API_ENDPOINT=""

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytstrecord.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.1"}, {"ipv4addr":"4.4.4.2"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytstrecord.test.loc","ipv4addr":"4.4.4.3"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a


curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytstrecord.test.loc","ipv4addr":"4.4.4.4"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytstrecord.test.loc","ipv4addr":"4.4.4.1"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a
````

When doing a nslookup, the 4 records are returned (round-robin)

````shell script
➤ nslookup mytstrecord.test.loc $API_ENDPOINT                                                                                                                                 
Server:         <YOUR DNS IP = API ENDPOINT>
Address:        <YOUR DNS IP = API ENDPOINT>

Name:   mytstrecord.test.loc
Address: 4.4.4.3
Name:   mytstrecord.test.loc
Address: 4.4.4.4
Name:   mytstrecord.test.loc
Address: 4.4.4.1
Name:   mytstrecord.test.loc
Address: 4.4.4.2
````

I can add a A with several time the same name.

Same in gandi we can create 2 a records pointing to same name.

````shell script
➤ nslookup tutu.coulombel.site                                                                                                                                                
Server:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
Name:   tutu.coulombel.site
Address: 43.43.33.45
Name:   tutu.coulombel.site
Address: 32.54.55.56
````

Because the key for A record is type + record name + ip. 

For instance if recreating ip `4.4.4.4`.

````shell script
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytstrecord.test.loc","ipv4addr":"4.4.4.4"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a
````

Output is 


````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytstrecord.test.loc","ipv4addr":"4.4.4.4"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:a
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The record 'mytstrecord.test.loc' already exists.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "The record 'mytstrecord.test.loc' already exists."
}⏎
````

We say record type is part of the key because we can see that we have IP `4.4.4.1` defined twice as a A and Host.
This have impact when searching by [IP](3-suite-b-dns-ip-search-api.md#api-comments) <!-- 3/ -->.

<!-- I assume same for AAAA. Gandi is ok-->

## We can not create several host record with same name even with different IP 

For host record it is a bit different key is type + name (not the IP). I can not have duplicate with same name.
Here I recreate a host record with same name but different IPs.

````shell script
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytstrecorddiffip.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.57"}, {"ipv4addr":"4.4.4.58"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytstrecorddiffip.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.59"}, {"ipv4addr":"4.4.4.60"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host
````

Output is 

````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytstrecorddiffip.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.57"}, {"ipv4addr":"4.4.4.58"}]}' \
          https://$API_ENDPOINT/wapi/v2.5/record:host
"record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0Lm15dHN0cmVjb3JkZGlmZmlw:mytstrecorddiffip.test.loc/default"⏎
[11:43] ~
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytstrecorddiffip.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.59"}, {"ipv4addr":"4.4.4.60"}]}' \
          https://$API_ENDPOINT/wapi/v2.5/record:host
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The record 'mytstrecorddiffip.test.loc' already exists.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "The record 'mytstrecorddiffip.test.loc' already exists."
}⏎
````

If same IP it will also raise a conflict

````shell script
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytstrecordsameip.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.57"}, {"ipv4addr":"4.4.4.58"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytstrecordsameip.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.57"}, {"ipv4addr":"4.4.4.58"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host
````

Output is 

````shell script
[11:39] ~
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytstrecordsameip.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.57"}, {"ipv4addr":"4.4.4.58"}]}' \
          https://$API_ENDPOINT/wapi/v2.5/record:host
"record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0Lm15dHN0cmVjb3Jkc2FtZWlw:mytstrecordsameip.test.loc/default"⏎
[11:39] ~
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytstrecordsameip.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.57"}, {"ipv4addr":"4.4.4.58"}]}' \
          https://$API_ENDPOINT/wapi/v2.5/record:host
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The record 'mytstrecordsameip.test.loc' already exists.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "The record 'mytstrecordsameip.test.loc' already exists."
}⏎
````

## We can not have 2 CNAME with the same NAME in Infoblox unlike some other providers

````shell script

export API_ENDPOINT="" # or the DNS IP


curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-duplicate.test.loc","canonical":"tes5.test.loc"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:cname

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test-infoblox-api-duplicate.test.loc","canonical":"tes6.test.loc"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:cname
````

Output is 

````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"test-infoblox-api-duplicate.test.loc","canonical":"tes5.test.loc"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:cname
"record:cname/ZG5zLmJpbmRfY25hbWUkLl9kZWZhdWx0LmxvYy50ZXN0LnRlc3QtaW5mb2Jsb3gtYXBpLWR1cGxpY2F0ZQ:test-infoblox-api-duplicate.test.loc/default"⏎
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"test-infoblox-api-duplicate.test.loc","canonical":"tes6.test.loc"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:cname
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The record 'test-infoblox-api-duplicate.test.loc' already exists.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "The record 'test-infoblox-api-duplicate.test.loc' already exists."
}⏎                                                                                                                                                                          
````
 **However some DNS provider like Gandi allows it**
 
 ````shell script
➤ nslookup -type=CNAME myentry.coulombel.it                                                                                                                                   
Server:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
myentry.coulombel.it    canonical name = toto.com.coulombel.it.
myentry.coulombel.it    canonical name = tutu.com.coulombel.it.

Authoritative answers can be found from:
````

Same for AWS in particular for latency based routing (see AWS dojo).

<!--
AWS SA EXO
https://github.com/scoulomb/aws-sa-exo/blob/master/sa-question-b.adoc
-->

## Infoblox does not prevent from creating a host, A, AAAA with same name as TXT

````shell script
export API_ENDPOINT=""

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytxtrecordtest.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.1"}, {"ipv4addr":"4.4.4.2"}]}' \
        https://$API_ENDPOINT/wapi/v2.5/record:host

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytxtrecordtest.test.loc","view":"default","text": "This a host server"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:txt

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytxtrecordtest.test.loc","ipv4addr":"10.10.10.2"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytxtrecordtest.test.loc","ipv6addr":"2001:0db8:0000:0000:0000:ff00:0042:8329"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:aaaa
````

Output is 

````shell script
[11:31] ~
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytxtrecordtest.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.1"}, {"ipv4addr":"4.4.4.2"}]}' \
          https://$API_ENDPOINT/wapi/v2.5/record:host
"record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0Lm15dHh0cmVjb3JkdGVzdA:mytxtrecordtest.test.loc/default"⏎
[11:31] ~
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytxtrecordtest.test.loc","view":"default","text": "This a host server"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:txt
"record:txt/ZG5zLmJpbmRfdHh0JC5fZGVmYXVsdC5sb2MudGVzdC5teXR4dHJlY29yZHRlc3QuIlRoaXMiICJhIiAiaG9zdCIgInNlcnZlciI:mytxtrecordtest.test.loc/default"⏎
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytxtrecordtest.test.loc","ipv4addr":"10.10.10.2"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:a
"record:a/ZG5zLmJpbmRfYSQuX2RlZmF1bHQubG9jLnRlc3QsbXl0eHRyZWNvcmR0ZXN0LDEwLjEwLjEwLjI:mytxtrecordtest.test.loc/default"⏎
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytxtrecordtest.test.loc","ipv6addr":"2001:0db8:0000:0000:0000:ff00:0042:8329"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:aaaa
"record:aaaa/ZG5zLmJpbmRfYWFhYSQuX2RlZmF1bHQubG9jLnRlc3QsbXl0eHRyZWNvcmR0ZXN0LDIwMDE6ZGI4OjpmZjAwOjQyOjgzMjk:mytxtrecordtest.test.loc/default"⏎
                                                                                                                                                                         
````


## Note on nslookup

**When we do not specify a type in nslookup query it will check both A and AAAA by default**.
If we specify A we only have A, same for AAAA.
- If record is a CNAME
    - If (nslookup) type is CNAME it will stop recursion at CNAME
    - If type is A it will look only for A
    - If type is AAAA it will only for AAAA
    - If no type it will recurse after the CNAME and find A and AAAA
    
Example;

````shell script
# coulombel.site zone file
yop 300 IN CNAME yop.coulombel.it.
# coulombel.it zone file
yop 300 IN A 42.42.42.42
yop 300 IN AAAA 2a00:1140:200::17
````

Nslookup output is 

````shell script
➤ nslookup -type=CNAME yop.coulombel.site                                                                                                                                     
Server:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
yop.coulombel.site      canonical name = yop.coulombel.it.

Authoritative answers can be found from:

[14:25] ~
➤ nslookup -type=A yop.coulombel.site                                                                                                                                         
Server:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
yop.coulombel.site      canonical name = yop.coulombel.it.
Name:   yop.coulombel.it
Address: 42.42.42.42

[14:25] ~
➤ nslookup -type=AAAA yop.coulombel.site                                                                                                                                      
Server:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
yop.coulombel.site      canonical name = yop.coulombel.it.
Name:   yop.coulombel.it
Address: 2a00:1140:200::17

[14:25] ~
➤ nslookup yop.coulombel.site                                                                                                                                                 
Server:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
yop.coulombel.site      canonical name = yop.coulombel.it.
Name:   yop.coulombel.it
Address: 42.42.42.42
Name:   yop.coulombel.it
Address: 2a00:1140:200::17
````


## Wrap-up

- [1] [Infoblox prevents from creating host, A, AAAA record with same name a CNAME record](#Infoblox-prevents-from-creating-host-or-A-or-AAAA-record-with-same-name-as-a-CNAME-record)
- [2] [Infoblox does not prevent from creating A and AAAA and Host with same name](#Infoblox-does-not-prevent-from-creating-A-and-AAAA-and-Host-with-same-name)
- [3] [We can also create several A with the same name and different IP](#we-can-also-create-several-a-with-the-same-name-and-different-ip)
- [4] [We can not create several host record with same name even with different IP](#we-can-not-create-several-host-record-with-same-name-even-with-different-ip)
- [5] [We can not have 2 CNAME with the same NAME in Infoblox unlike some other providers](#we-can-not-have-2-cname-with-the-same-name-in-infoblox-unlike-some-other-providers)
- [6] [Infoblox does not prevent from creating a host, A, AAAA with same name as TXT](#infoblox-does-not-prevent-from-creating-a-host-a-aaaa-with-same-name-as-txt)

<!-- autocompletion in Markdown always use lower case -->

## FQDN duplicate checks

Assume we have requirement when creating a Host record to check that this FQDN is not defined (already exists) as:
- Host record
- A record 
- ~~AAAA record~~
- CNAME record
- TXT record 

[3 checks + hosts]

### Do not check twice 

If we forward Infoblox error.

- Host record -> checked by [4].
If we want idempotency (check sent payload same as device status) 
    - option 1: retrieve host, of present check retrieved content and payload if same idempotent call ok otherwise raise exception
    - option 2: we could make the check when handling Infoblox exception.

    Algorithm would be 

    ````shell script
    If conflict exception raised by Infoblox:
        retrieve host record 
        if exist: # conflict is due to host record 
          check content payload and device status are equal 
            if equal: idempotency ok, return ok
            else: 
              fail 409
    ```` 
  Option2 has big advantage to not increase response time (avoid [parallelism](https://github.com/scoulomb/dev_snippets/tree/master/multithread)) of all requests but only conflicting one

Which is convenient as avoids to to the check at every request.
Option is 1 LBYL (look before you leap), and option 2 is EAFP (Easier to ask for forgiveness than permission).
See https://stackoverflow.com/questions/7604636/better-to-try-something-and-catch-the-exception-or-test-if-its-possible-first

- A record -> check to be performed
- ~~AAAA record -> check to be performed~~
- CNAME record ->  checked by [1]
- TXT record -> check to be performed

<!--
DNS PR#48
-->

We could add check on IP.

## Infoblox find API - check duplicate v1

Relying on Infoblox name checks and rely on error forwarding makes sense because:
- it reduces the number of API call (4 to 2). Not negligible as parallelization has some issue with multithread: https://github.com/scoulomb/dev_snippets/blob/master/multithread/parallel_map/async.py#L8.
- it avoids to test cases which can not happen.

But we still need 2 API calls for A and TXT, if we want to avoid to create a Host with same as existing A and TXT).

Moreover there is inconsistency in error management.
With the 2 API call check we would return a 409, and error forwarding would return a 400 (if not re-processed).

### Here I will emulate the check

We create a A, AAAA and TXT with name `testdup` in zone `test.loc`.
I am also adding a MX.

````shell script
export API_ENDPOINT=""

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"testdup.test.loc","ipv4addr":"10.10.10.2"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"testdup.test.loc","ipv6addr":"2001:0db8:0000:0000:0000:ff00:0042:8329"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:aaaa

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"testdup.test.loc","view":"default","text": "This a host server"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:txt

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"mail_exchanger":"testdup.tutu.loc","name":"testdup.test.loc","preference":1}' \
        https://$API_ENDPOINT/wapi/v2.5/record:mx
````

Once created we retrieve them via API.

````shell script
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:a?name=testdup.test.loc&zone=test.loc"

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:aaaa?name=testdup.test.loc&zone=test.loc"

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:txt?name=testdup.test.loc&zone=test.loc"

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:mx?name=testdup.test.loc&zone=test.loc"


curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:txt?name=testdupsamplenotfound.test.loc&zone=test.loc"
````

Note zone is optional for those 3 cases. Output is:

````shell script
[10:32][master]⚡? ~/dev/dns-automation
➤ curl -k -u admin:infoblox \                                                                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/record:a?name=testdup.test.loc&zone=test.loc"

[
    {
        "_ref": "record:a/ZG5zLmJpbmRfYSQuX2RlZmF1bHQubG9jLnRlc3QsdGVzdGR1cCwxMC4xMC4xMC4y:testdup.test.loc/default",
        "ipv4addr": "10.10.10.2",
        "name": "testdup.test.loc",
        "view": "default"
    }
]⏎
[10:32][master]⚡? ~/dev/dns-automation
➤ curl -k -u admin:infoblox \                                                                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/record:aaaa?name=testdup.test.loc&zone=test.loc"
[
    {
        "_ref": "record:aaaa/ZG5zLmJpbmRfYWFhYSQuX2RlZmF1bHQubG9jLnRlc3QsdGVzdGR1cCwyMDAxOmRiODo6ZmYwMDo0Mjo4MzI5:testdup.test.loc/default",
        "ipv6addr": "2001:db8::ff00:42:8329",
        "name": "testdup.test.loc",
        "view": "default"
    }
]⏎
[10:33][master]⚡? ~/dev/dns-automation
➤ curl -k -u admin:infoblox \                                                                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/record:txt?name=testdup.test.loc&zone=test.loc"
[
    {
        "_ref": "record:txt/ZG5zLmJpbmRfdHh0JC5fZGVmYXVsdC5sb2MudGVzdC50ZXN0ZHVwLiJUaGlzIiAiYSIgImhvc3QiICJzZXJ2ZXIi:testdup.test.loc/default",
        "name": "testdup.test.loc",
        "text": "This a host server",
        "view": "default"
    }
]⏎
[14:36][master]⚡ ~/dev/myDNS
➤ curl -k -u admin:infoblox \                                                                                                                  
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/record:mx?name=testdup.test.loc&zone=test.loc"
[
    {
        "_ref": "record:mx/ZG5zLmJpbmRfbXgkLl9kZWZhdWx0LmxvYy50ZXN0LnRlc3RkdXAudGVzdGR1cC50dXR1LmxvYy4x:testdup.test.loc/default",
        "mail_exchanger": "testdup.tutu.loc",
        "name": "testdup.test.loc",
        "preference": 1,
        "view": "default"
    }
]⏎
[10:33][master]⚡? ~/dev/dns-automation
➤ curl -k -u admin:infoblox \                                                                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/record:txt?name=testdupsamplenotfound.test.loc&zone=test.loc"
[]⏎
[10:33][master]⚡? ~/dev/dns-automation
➤                                                                                                                                                                                                                             
````

In that example  application code/layer (not infoblox) will prevent creating the host and run such curl (as conflict detected with A and TXT, see requirements [above](#FQDN-duplicate-checks)):

````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"testdup.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.1"}, {"ipv4addr":"4.4.4.2"}]}' \
          https://$API_ENDPOINT/wapi/v2.5/record:host
"record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0LnRlc3RkdXA:testdup.test.loc/default"⏎

➤ curl -k -u admin:infoblox \                                                                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/record:host?name=testdup.test.loc&zone=test.loc"
[
    {
        "_ref": "record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0LnRlc3RkdXA:testdup.test.loc/default",
        "ipv4addrs": [
            {
                "_ref": "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuX2RlZmF1bHQubG9jLnRlc3QudGVzdGR1cC40LjQuNC4xLg:4.4.4.1/testdup.test.loc/default",
                "configure_for_dhcp": false,
                "host": "testdup.test.loc",
                "ipv4addr": "4.4.4.1"
            },
            {
                "_ref": "record:host_ipv4addr/ZG5zLmhvc3RfYWRkcmVzcyQuX2RlZmF1bHQubG9jLnRlc3QudGVzdGR1cC40LjQuNC4yLg:4.4.4.2/testdup.test.loc/default",
                "configure_for_dhcp": false,
                "host": "testdup.test.loc",
                "ipv4addr": "4.4.4.2"
            }
        ],
        "name": "testdup.test.loc",
        "view": "default"
    }
]⏎

````
Note a find by name will always return a single array (top level) for host (due to infoblox check [4]), but for A it could be 
<!-- and it does not return cname though they share same ns see [1] --> 

But it is not the case for A.

````shell script
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test123456.test.loc","ipv4addr":"10.10.10.2"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test123456.test.loc","ipv4addr":"10.10.10.3"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a


curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/record:a?name=test123456.test.loc&zone=test.loc"
````

Output is 

````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/record:a?name=test123456.test.loc&zone=test.loc"
[
    {
        "_ref": "record:a/ZG5zLmJpbmRfYSQuX2RlZmF1bHQubG9jLnRlc3QsdGVzdDEyMzQ1NiwxMC4xMC4xMC4y:test123456.test.loc/default",
        "ipv4addr": "10.10.10.2",
        "name": "test123456.test.loc",
        "view": "default"
    },
    {
        "_ref": "record:a/ZG5zLmJpbmRfYSQuX2RlZmF1bHQubG9jLnRlc3QsdGVzdDEyMzQ1NiwxMC4xMC4xMC4z:test123456.test.loc/default",
        "ipv4addr": "10.10.10.3",
        "name": "test123456.test.loc",
        "view": "default"
    }
]⏎
````

### Infoblox find API - check duplicate v2: can we do better and do a single call for TXT and A

Quoting the doc:
https://www.infoblox.com/wp-content/uploads/infoblox-deployment-infoblox-rest-api.pdf (p23)

> Retrieve all the records in a zone
> The API function allrecords returns the following types of records within a zone:
> - record:a
> - record:aaaa
> - record:cname
> - record:dname
> - record:host
> - record:host_ipv4addr
> - record:host_ipv6addr
> - record:mx
> - record:naptr
> - record:ptr
> - record:srv
> - record:txt
> - sharedrecord:a
> - sharedrecord:aaaa
> - sharedrecord:mx
> - sharedrecord:srv
> - sharedrecord:txt
>
> For the other types of records, it returns `“UNSUPPORTED”`

> `GET <wapi_url>/allrecords?zone=info.com`
>
> `curl -k -u admin:infoblox -X GET "https://grid-master/wapi/v2.11/allrecords?zone=info.com&_return_as_object=1"`

<!--
Note some record here not available for direct retrieve: 
````
➤ curl -k -u admin:infoblox \                                                                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/record:dname?name=testdup.test.loc&zone=test.loc"
{ "Error": "AdmConProtoError: Unknown object type (record:dname)",
  "code": "Client.Ibap.Proto",
````
-->

Can we use this? Yes because even if not mentioned in doc we can filter on mame.

````shell script
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/allrecords?name=testdup&zone=test.loc"
````

Answer is yes but note:

- **The filtering on name is not mentioned in doc**
- Zone is mandatory
- The name unlike single retrieve API should not include the zone (`testdup` and not `testdup.test.loc`)

 Output is:
 
 ````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/allrecords?name=testdup&zone=test.loc"
[
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5iaW5kX2EkLl9kZWZhdWx0LmxvYy50ZXN0LHRlc3RkdXAsMTAuMTAuMTAuMg:testdup",
        "comment": "",
        "name": "testdup",
        "type": "record:a",
        "view": "default",
        "zone": "test.loc"
    },
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5iaW5kX2FhYWEkLl9kZWZhdWx0LmxvYy50ZXN0LHRlc3RkdXAsMjAwMTpkYjg6OmZmMDA6NDI6ODMyOQ:testdup",
        "comment": "",
        "name": "testdup",
        "type": "record:aaaa",
        "view": "default",
        "zone": "test.loc"
    },
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5iaW5kX3R4dCQuX2RlZmF1bHQubG9jLnRlc3QudGVzdGR1cC4iVGhpcyIgImEiICJob3N0IiAic2VydmVyIg:testdup",
        "comment": "",
        "name": "testdup",
        "type": "record:txt",
        "view": "default",
        "zone": "test.loc"
    },
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5ob3N0JC5fZGVmYXVsdC5sb2MudGVzdC50ZXN0ZHVw:testdup",
        "comment": "",
        "name": "testdup",
        "type": "record:host_ipv4addr",
        "view": "default",
        "zone": "test.loc"
    },
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5ob3N0JC5fZGVmYXVsdC5sb2MudGVzdC50ZXN0ZHVw:testdup",
        "comment": "",
        "name": "testdup",
        "type": "record:host_ipv4addr",
        "view": "default",
        "zone": "test.loc"
    },
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5iaW5kX214JC5fZGVmYXVsdC5sb2MudGVzdC50ZXN0ZHVwLnRlc3RkdXAudHV0dS5sb2MuMQ:testdup",
        "comment": "",
        "name": "testdup",
        "type": "record:mx",
        "view": "default",
        "zone": "test.loc"
    }
]⏎
````

We can find the A, AAAA and TXT. And the Host we had added containing the 2 A.
Thus we can reuse this, and even filter on the type !
This avoids to rely on Infoblox forwarding error proposed [above in section "do not check twice"](#do-not-check-twice).

So if the list is empty there is no conflict.
If it is not empty we check when creating a host, there is in this list not a: HOST or (A, CNAME, TXT, ~~AAAA~~).
(we can use a filter)

If there was only a MX it would not fail.

Note HOST has:
- host_ipv4addr
- host_ipv6addr
- host (I have never seen it)

````shell script
curl -k \
     -u admin:infoblox \
     -H "Content-Type: application/json" \
     -X POST \
     -d '{"name":"uuu.test.loc","view":"default","ipv4addrs":[{"ipv4addr":"4.4.4.1"}, {"ipv4addr":"4.4.4.2"}], "ipv6addrs":[{"ipv6addr":"2001:0db8:0000:0000:0000:ff00:0042:8329"}, {"ipv6addr":"2001:0db8:0000:0000:0008:ff00:0042:8329"}]}' \
     https://$API_ENDPOINT/wapi/v2.5/record:host

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/allrecords?name=uuu&zone=test.loc"
````

Output is 

````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                                                                 
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/allrecords?name=uuu&zone=test.loc"
[
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5ob3N0JC5fZGVmYXVsdC5sb2MudGVzdC51dXU:uuu",
        "comment": "",
        "name": "uuu",
        "type": "record:host_ipv6addr",
        "view": "default",
        "zone": "test.loc"
    },
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5ob3N0JC5fZGVmYXVsdC5sb2MudGVzdC51dXU:uuu",
        "comment": "",
        "name": "uuu",
        "type": "record:host_ipv6addr",
        "view": "default",
        "zone": "test.loc"
    },
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5ob3N0JC5fZGVmYXVsdC5sb2MudGVzdC51dXU:uuu",
        "comment": "",
        "name": "uuu",
        "type": "record:host_ipv4addr",
        "view": "default",
        "zone": "test.loc"
    },
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5ob3N0JC5fZGVmYXVsdC5sb2MudGVzdC51dXU:uuu",
        "comment": "",
        "name": "uuu",
        "type": "record:host_ipv4addr",
        "view": "default",
        "zone": "test.loc"
    }
]⏎
````
=> we check host_ipv6 but not AAAA.

Thus this fix the issue raised in section [introduction](#Infoblox-find-API).
We do not need 2 API calls for CNAME and TXT, but 1 for AllRecords
It avoids to rely on error forwarding (when creating host with same FQDN as existing CNAME[1] and HOST[4])
and have consistent error management with CNAME and TXT.
As we also check HOST and CNAME with that solution, it avoids another call in case of conflict to create a host.

Following UC:
- Create host with same name as 2 existing A is rejected => because of the check
- Create host with same name as existing host is rejected => because of the check but Infoblox would reject it and it would be visible with error forwarding.
The fact we do a one shot call also reduces the number of API calls (not need to try to create the record there)

<!-- see demo s6 -->

With this approach we can also go for [idempotency option 1 discussed in section "do not check twice"](#do-not-check-twice) with no extra cost.
It simplifies non reg cases.
If we implement imperative idempotency/declarative (idempotent) use-case "Create host with same name as existing host" will not be rejected if body is matching content in the device. It will results in a no-ops.

<!-- linked to "Question on imperative/declarative" API mel and reference for that-->

<!-- 
Linked here https://raw.githubusercontent.com/scoulomb/soapui-docker/master/presentation.md + cname point seen in aws-sa
-->

**Note**: Later we decided to remove TXT record when creating a host (so 3 checks).
Thus given checks we want to [perform described in "do-not-check-twice"](#do-not-check-twice).
We have no big API call reduction (1 API call for CNAME (not TXT to check) vs 1 API call for AllRecords) at check level.
But we avoid to call Infoblox API for host record creation in case of host duplicate when using AllRecords.
+ all the advantage mentioned above are still valid
It also enables to easily prevents duplication with other kind of records (+ future check for cname creation).

Thus in the retrieve list we check before creating a host record with a given FQDN
there is not a existing HOST (record:host_ipv6addr, record:host_ipv4addr, record:host) or (A (record:a), CNAME (record:cname), ~~TXT (record:txt), AAAA (record:aaaa~~) with same FQDN.

<!--
See DNS PR#50
ALL IS OK - code and this aligned and consistent
-->

Note Infoblox API is not consistent, when [creating a A record](1-Infoblox-API-overview.md#POST-A), name contains the zone.
In `allrecords` output for `record:a`, name does not contain the zone.

<!--
See DNS PR#52 + 53
demo s6 when we create A record
-->

### Side notes

We keep the forwarding because it allows us, to catch other error like non existent zone.
And for concurrent update to avoid to have a 500. (but still concrent possible for our own check, limited)
Also for invalid credential but needs to check the content-type in response.


Note it is possible to filter on the view:

````shell script
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X GET \
        "https://$API_ENDPOINT/wapi/v2.5/allrecords?name=uuu&view=Office_api_test&zone=test.loc"
````

It is something we can add to allow record with same FQDN in public and private view.



## Questions on Infoblox check behaviour in different views

See [document here](3-suite-a-dns-view.md).
Thus if we do not filter on the view we are clearly more restrictive and will want to do it.
<!-- DNS PR#60 -->

## Conclusion and next steps

Previously we proposed a strategy to ensure Name (FQDN) is not in use by another A, CNAME, Host record (host_ipv4add, host_ipv6addr, host ) in same view
using AllRecords API when creating a host record.


<!--
````
Filter on view via Infoblox API + 
filter(lambda record: record.type in (
    "record:a", "record:cname", "record:host_ipv4addr", "record:host_ipv6addr", "record:host"),
  
````

-->
Now we want to ensure IP is not in use by another record in same view using Search API when creating a host record

See details in that markdown [file](3-suite-b-dns-ip-search-api.md) where we applied a similar recipe.

## Additional questions

- 2 CNAME with same name (question from [Advanced bind - use linux nameserver](../../2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-0.md)).
We had studied this point here: [5] [We can not have 2 CNAME with the same NAME in Infoblox unlike some other providers](#we-can-not-have-2-cname-with-the-same-name-in-infoblox-unlike-some-other-providers). OK.

- Several A and round robin (question from [Advanced bind - use linux nameserver](../../2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-0.md)). 
and example here [Attestation covid-19](https://github.com/scoulomb/attestation-covid19-saison2-auto#configure-dns)) when register APEX.
Also seen here: [3] [We can also create several A with the same name and different IP](#we-can-also-create-several-a-with-the-same-name-and-different-ip)

Define in Gandi:
````shell script
sysy 300 IN A 40.40.40.40
sysy 300 IN A 41.41.41.41
sysy 300 IN A 42.42.42.42
sysy 300 IN A 43.43.43.43
sysy 300 IN AAAA 2001:4860:4802:40::15
sysy 300 IN AAAA 2001:4860:4802:41::15
sysy 300 IN AAAA 2001:4860:4802:42::15
sysy 300 IN AAAA 2001:4860:4802:43::15
````


````shell script
ssh sylvain@109.29.148.109 

sylvain@sylvain-hp:~$ nslookup sysy.coulombel.site
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   sysy.coulombel.site
Address: 40.40.40.40
Name:   sysy.coulombel.site
Address: 43.43.43.43
Name:   sysy.coulombel.site
Address: 42.42.42.42
Name:   sysy.coulombel.site
Address: 41.41.41.41
Name:   sysy.coulombel.site
Address: 2001:4860:4802:43::15
Name:   sysy.coulombel.site
Address: 2001:4860:4802:41::15
Name:   sysy.coulombel.site
Address: 2001:4860:4802:40::15
Name:   sysy.coulombel.site
Address: 2001:4860:4802:42::15

sylvain@sylvain-hp:~$ nslookup -type=A sysy.coulombel.site
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   sysy.coulombel.site
Address: 41.41.41.41
Name:   sysy.coulombel.site
Address: 42.42.42.42
Name:   sysy.coulombel.site
Address: 43.43.43.43
Name:   sysy.coulombel.site
Address: 40.40.40.40

sylvain@sylvain-hp:~$ nslookup -type=AAAA sysy.coulombel.site
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   sysy.coulombel.site
Address: 2001:4860:4802:42::15
Name:   sysy.coulombel.site
Address: 2001:4860:4802:40::15
Name:   sysy.coulombel.site
Address: 2001:4860:4802:41::15
Name:   sysy.coulombel.site
Address: 2001:4860:4802:43::15
````

We can see the randomisation :

````shell script
sylvain@sylvain-hp:~$ ping -4 sysy.coulombel.site
PING sysy.coulombel.site (41.41.41.41) 56(84) bytes of data.
^C
--- sysy.coulombel.site ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1025ms

sylvain@sylvain-hp:~$ sudo systemd-resolve --flush-caches
[sudo] password for sylvain:
sylvain@sylvain-hp:~$ ping -4 sysy.coulombel.site
PING sysy.coulombel.site (41.41.41.41) 56(84) bytes of data.
^C
--- sysy.coulombel.site ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1031ms

sylvain@sylvain-hp:~$ sudo systemd-resolve --flush-caches
sylvain@sylvain-hp:~$ ping -4 sysy.coulombel.site
PING sysy.coulombel.site (42.42.42.42) 56(84) bytes of data.
^C
--- sysy.coulombel.site ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1013ms

sylvain@sylvain-hp:~$ ping -4 sysy.coulombel.site
PING sysy.coulombel.site (43.43.43.43) 56(84) bytes of data.
^C
--- sysy.coulombel.site ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1006ms

sylvain@sylvain-hp:~$ ping -6 sysy.coulombel.site
PING sysy.coulombel.site(2001:4860:4802:42::15 (2001:4860:4802:42::15)) 56 data bytes
^CFrom 2001:4860:1:1::478 icmp_seq=1 Destination unreachable: Administratively prohibited

--- sysy.coulombel.site ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

sylvain@sylvain-hp:~$ ping -6 sysy.coulombel.site
PING sysy.coulombel.site(2001:4860:4802:40::15 (2001:4860:4802:40::15)) 56 data bytes
From 2001:4860:1:1::478 icmp_seq=1 Destination unreachable: Administratively prohibited
From 2001:4860:1:1::478 icmp_seq=2 Destination unreachable: Administratively prohibited
^C
--- sysy.coulombel.site ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1000ms

````

Use ssh to ubuntu (see [Use linux ns](../../2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-0.md)).
<!-- To use ubuntu setup and not vm on co win and 10.0.2.3 is standard for VM so ok:
https://serverfault.com/questions/453185/vagrant-virtualbox-dns-10-0-2-3-not-working
https://github.com/scoulomb/myDNS/blob/541764802fa4ff66fcdad3bba861f61a4f87a8d2/2-advanced-bind/5-real-own-dns-application/2-modify-tld-ns-record.md
-->

OK.

- TXT and CNAME conflict -> Gandi blocks it (question from [Attestation covid-19](https://github.com/scoulomb/attestation-covid19-saison2-auto#configure-dns))
(error made when wanted to perform cname mapping amd verify subdomain instead of domain).
If we had seen
[6] [Infoblox does not prevent from creating a host, A, AAAA with same name as TXT](#infoblox-does-not-prevent-from-creating-a-host-a-aaaa-with-same-name-as-txt)
Infoblox also block TXT and CNAME conflict

````shell script
curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytxtrecordtest-31120.test.loc","view":"default","text": "This a host server"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:txt

curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"mytxtrecordtest-31120.test.loc","canonical":"tes4.test.loc"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:cname

````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                 vagrant@archlinux
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytxtrecordtest-31120.test.loc","view":"default","text": "This a host server"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:txt
"record:txt/ZG5zLmJpbmRfdHh0JC5fZGVmYXVsdC5sb2MudGVzdC5teXR4dHJlY29yZHRlc3QtMzExMjAuIlRoaXMiICJhIiAiaG9zdCIgInNlcnZlciI:mytxtrecordtest-31120.test.loc/default"⏎
[10:33] ~
➤ curl -k -u admin:infoblox \                                                                                                                                                 vagrant@archlinux
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"mytxtrecordtest-31120.test.loc","canonical":"tes4.test.loc"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:cname

{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The record 'mytxtrecordtest-31120.test.loc' already exists.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "The record 'mytxtrecordtest-31120.test.loc' already exists."
}⏎
````

it is consistent for CNAME and TXT with
[1] [Infoblox prevents from creating host, A, AAAA record with same name a CNAME record](#Infoblox-prevents-from-creating-host-or-A-or-AAAA-record-with-same-name-as-a-CNAME-record)
And Gandi behavior. OK.

- CNAME at APEX (question from [Attestation covid-19](https://github.com/scoulomb/attestation-covid19-saison2-auto#configure-dns)).
It is not possbile with Gandi, probably same with Infoblox.


curl -k -u admin:infoblox \
        -H "Content-Type: application/json" \
        -X POST \
        -d '{"name":"test.loc","ipv4addr":"10.10.10.2"}' \
        https://$API_ENDPOINT/wapi/v2.5/record:a

Output is

````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                 vagrant@archlinux
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"test.loc","ipv4addr":"10.10.10.2"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:a
"record:a/ZG5zLmJpbmRfYSQuX2RlZmF1bHQubG9jLnRlc3QsLDEwLjEwLjEwLjI:test.loc/default"⏎

➤ nslookup test.loc $API_ENDPOINT                                                                                                                                             vagrant@archlinux
Server:         <API_ENDPOINT DNS>
Address:        <API API_ENDPOINT IP>#53

Name:   test.loc
Address: 10.10.10.2
````

And 

````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                 vagrant@archlinux
          -H "Content-Type: application/json" \
          -X GET \
          "https://$API_ENDPOINT/wapi/v2.5/allrecords?name=""&zone=test.loc&type=record:a"
[
    {
        "_ref": "allrecords/ZG5zLnpvbmVfc2VhcmNoX2luZGV4JGRucy5iaW5kX2EkLl9kZWZhdWx0LmxvYy50ZXN0LCwxMC4xMC4xMC4y:",
        "comment": "",
        "name": "",
        "type": "record:a",
        "view": "default",
        "zone": "test.loc"
    }
]⏎
````
Which proves `test.loc` is a zone.
And same with `CNAME`:

````shell script
# remove any space  after \ and check no bash header
curl -k -u admin:infoblox \
          -H "Content-Type: application/json" \
          -X POST \
          -d '{"name":"test.loc","canonical":"tes4.test.loc"}' \
          https://$API_ENDPOINT/wapi/v2.5/record:cname
````

Output is 

````shell script
➤ curl -k -u admin:infoblox \                                                                                                                                                 vagrant@archlinux
            -H "Content-Type: application/json" \
            -X POST \
            -d '{"name":"test.loc","canonical":"tes4.test.loc"}' \
            https://$API_ENDPOINT/wapi/v2.5/record:cname
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:Zone 'test.loc' cannot have an empty CNAME.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "Zone 'test.loc' cannot have an empty CNAME."
}⏎
````

Which is consistent with Gandi. OK.


<!-- 3/11/2020 I review whole doc and all is consistent ok including suite A+B; OK
From 2/10/2020
- Domain 
    - P#48 Prepare (overview ok keep this file better for domain an IP)
    - P#50 Code for logic
    - P#53: Spec (voir test.sh for error reproduction)
    - P#52 Non reg
    - P#60 for view
DEMO S6 points are OK (no come back committed) 
- IP check
    - P#61/63 Code for logic
    - Spec and nr osef
; OK and stuff in TODO with no impact updated OK

rewritten his: repos/private/browse/myk8s/Repo-mgmt/repo-mgmt-rm-conf-data.md
+ covid did it (judge similar and not the point ok osef)
; and to check across hist:  git grep expression $(git rev-list --all)

Infoblox+namespace+questions page updated on 3/11/2020 OKOK
Did not include ip checks and end of doc as initially for design in conf 
; OK
===>>> Can conclude this TOPIC :) STOP
test.sh could try with mix conflict osef STOP

And search for "I assume same for AAAA. Gandi is ok and not needed" OK

note on ping -4/6 just saw same with git push -h OK
-->
