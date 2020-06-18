# DNS

## Infoblox Namespace

I will prove that in Infoblox CNAME records shares the same namespace as (Host, A, AAAA) though they have different API endpoint.
However A, AAAA and Host have a distinct namespace.

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
Same point is raised in questions [here](./p2-1-xx-questions.md#can-i-have-1-a-record-and-1-cname-with-same-dns-name).

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

Same for the lookup as not A or AAAA, we have to mention the type:

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

Default type is A (seems return AAAA, see the end), so I have to specify the CNAME type.

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
# Here we have record, A, AAAA though doc says default is A, thus I would not expect AAAA
$ nslookup -type=A test-infoblox-api-no-cname.test.loc $API_ENDPOINT
Server:         <YOUR DNS IP = API ENDPOINT>
Address:        <YOUR DNS IP = API ENDPOINT>#<nb>

Name:   test-infoblox-api-no-cname.test.loc
Address: 4.4.4.2
Name:   test-infoblox-api-no-cname.test.loc
Address: 10.10.10.2
# Here we have record, A
$ nslookup -type=AAAA test-infoblox-api-no-cname.test.loc $API_ENDPOINT
Server:         <YOUR DNS IP = API ENDPOINT>
Address:        <YOUR DNS IP = API ENDPOINT>#53

Name:   test-infoblox-api-no-cname.test.loc
Address: 2001:db8::ff00:42:8329
# Here we have AAAA
````