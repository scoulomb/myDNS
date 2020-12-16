# Infoblox error management and content type

We study how Infoblox manages error 400, 401, 403.
For credentials management and error forwarding.
See [3 infoblox namespace](../3-Infoblox-namespace.md#side-notes)

## Run test

In script `./infoblox_api_content_type.sh`, replace following variables:

- API_ENDPOINT
- VALID_USER_1_NAME
- VALID_USER_1_PASSWORD
- VALID_USER_2_NAME
- VALID_USER_2_PASSWORD 

````shell script
./infoblox_api_content_type.sh > ./infoblox_api_content_type_out_(date "+%s").txt
````

We could use git bash but it requires jq on [Windows](https://stackoverflow.com/questions/53967693/how-to-run-jq-from-gitbash-in-windows).

Tips if running on vm with `rsync` in Vagrantfile:

````shell script
# Before running script: to copy last report update to VM
vagrant rsync # and not auto, otherwise it would overrwrite the file
# Afer running script to get the report as rsync is a one way sync from windows to VM
python -m http.server 8080` to get the report
````
See here issue: https://github.com/scoulomb/myk8s/blob/master/Setup/ArchDevVM/sync-issue.md

## Experiments

- **TEST1**: Create entry nominal: A '201 application/json' IS RETURNED BUT actual type is 'text'"
- **TEST1 BIS**: Create entry nominal with user 2: A '201 application/json' IS RETURNED BUT actual type is 'text'"
- **TEST1 BIS 2**: Shows that using a most recent version changes nothing 
<!--(this version is not available everywhere) -->
- **TEST2**: Create record in zone which does not exist: A '400 application/json' IS RETURNED and actual type is 'application/json'"
Note: if a user does not have right/role to see a view. We have this error too and not necessarily a 403.
<!-- cf sre-setup / testV2 -->
- **TEST3**: Create entry username exists / invalid credentials: A '401 text/html' IS RETURNED and actual type is 'text/html'"
- **TEST4**: Create entry username exists / invalid credentials RETRY: A '401 text/html' IS RETURNED and actual type is 'text/html'"
- **TEST5**: Create entry username DOES NOT exist : A '401 text/html' IS RETURNED and actual type is 'text/html'"
- **TEST6**: Find entry username DOES NOT exist : A '401 text/html' IS RETURNED and actual type is 'text/html'"
- **TEST7**: Find entry username DOES NOT exist RETRY : A '403 text/html' IS RETURNED and actual type is 'text/html'"
- **TEST8**: Create entry nominal after username failure: device is blocked temporarily for this user"
- **TEST9**: Create entry nominal after username failure: device is blocked temporarily for all users"
We also saw that Infoblox drop packet of valid credentials if too much invalid credntials queries resulting in a timeout on client side.
<!-- ("DNS+non+regression+sporadic+failures") -->

## Conclusion 

- From all tests: Infoblox API is not consistent it can return:
    - Text (201) (but says it is `application/json` more a `text/plain`)
    - JSON (400)
    - HTML (401, 403)

- From **TEST1**, `Content-Type` header may not be accurate. It returns `application/json` whereas actual type is `text`

- From **TEST2, TEST3, TEST7**, however for error cases the `Content-Type` seems correct. So we can rely on it.

- From **TEST2**, `400` outputs correct `Content-Type`: 

````shell script

{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:The action is not allowed. A parent was not found.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "The action is not allowed. A parent was not found."
}
````
And has a `code` and `text` which can be parsed by a tool and forward this error.
We could even define an error mapping later rather than forwarding code and text.

- From **TEST2, TEST6 (401), TEST7 (403)** it is not safe to consider all errors have a code and text. 
But we can treat separately 401 and 403. And then for remaining 4XX range, if `Content-Type` is `application/json` we can get safely the code and text with a default value.
If `Content-Type` returned by Infoblox is JSON and actual content is not JSON but a string (as for the create A).
We would have following error:
````shell script
AttributeError: 'str' object has no attribute 'get'
````
<!-- easily reproducible with ut but not a ut, this is
"Assumption is made that Infoblox always returns a JSON in that case, thus we can have data={} but not data="
in test, same issue described in the code
-->

Which could be catched at higher level by a tool and lead to a 500. 

- From **TEST3, TEST5**, there is no distinction made in entry creation for valid username with wrong credential or invalid username

- From **TEST4, TEST6, TEST7**, when performing a find with invalid username, the first query returns a 401. But a retry will return a 403.
<!-- consistent with DNS PR#89 -->
- From **TEST8, TEST9**, making several attempts with invalid username for a user will block the device **for all the users** and return a 403 for a given period of time.
Even with a valid login/password different from the one on which unsuccessful attempts were made.
This smells the bug report if we build a tool on top of it.
To cope with that rather than having a tool which forward each own user credentials to the device. 
We could create a credentials indirection (Kubernetes secrets, Ansible Tower, LDAP, Credentials vault (Thycotic, CyberArk, Centrtify)).

<!-- NR comment: this will make shit for non reg, can test as described in section beginning:
201, 400 (error fwd case), 401 (from device), 403
and 401 when no credentials provided (connexion) 

and 5XX can not NR


Note 403 hard to test as a second failure will block the device.
2 "401" failure from device very close can then make nr fail, so issue if 2 nr runned closely -->

## Algo proposal

````python
http_response: HttpResponse = self._try_send(request)
if http_response.status_code != 201:
    if http_response.status_code == 401:
        raise InvalidCredentials
    if http_response.status_code == 403:
        raise ForbiddenOperation
    if http_response.status_code in range(400, 500) \
            and http_response.headers is not None \
            and http_response.headers.get("Content-Type") == "application/json":
        raise DeviceFailure(http_response.status_code,
                            http_response.get_body_as_json().get('code', ''),
                            http_response.get_body_as_json().get('text', ''))
    raise ResourceCreationFailed(message)

if http_response.body is None:
    raise ResourceCreationFailed(message)

return http_response
````

## Notes
 
Successful response use `Transfer-Encoding.`
While error message use `Content-Length`. 
See https://github.com/scoulomb/http-over-socket.


## Open issue to Infoblox?

From that document we can open issue to Infoblox in particular to fix:
- From **TEST1**, `Content-Type` header may not be accurate. It returns `application/json` whereas actual type is `text`
- Could ask to always return a JSON and use the header `Accept` for content negotiation.
Adding this header changes nothing to the result. 

Note this behavior is not specified: https://www.infoblox.com/wp-content/uploads/infoblox-deployment-infoblox-rest-api.pdf 

<!-- 
This page clear OK and link Infoblox ns OK
From this DNS PR#84 OK
And https://github.com/scoulomb/private_script/tree/main/dns-auto (script runned ok, concluded)
where issue to run the code mentionned https://github.com/scoulomb/myk8s/blob/master/Setup/ArchDevVM/known-issues.md (concluded, and link other proj ok)--> 
-->