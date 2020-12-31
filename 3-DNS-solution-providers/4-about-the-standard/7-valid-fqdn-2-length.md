# What is a valid Hostname?

Here we will dive into length.

As a reminder last RFC said:

https://tools.ietf.org/html/rfc2181

> The DNS itself places only one restriction on the particular labels
that can be used to identify resource records.  That one restriction
relates to the length of the label and the full name.  The length of
any one label is limited to between 1 and 63 octets.  A full domain
name is limited to 255 octets (including the separators).  The zero
length full name is defined as representing the root of the DNS tree,
and is typically written and displayed as ".".  Those restrictions
aside, any binary string whatever can be used as the label of any
resource record.  


### With bind9

````shell script
vagrant rsync
cd 3-DNS-solution-providers/4-about-the-standard/docker-bind-dns-2-length
docker build . -f dns-ubuntu.Dockerfile -t dns-name-check
````

output is

````shell script
Step 11/17 : RUN named-checkzone fwd.coulombel.it /etc/bind/fwd.coulombel.it.db
 ---> Running in 97a1cf7f8daf
dns_master_load: /etc/bind/fwd.coulombel.it.db:19: label too long
dns_master_load: /etc/bind/fwd.coulombel.it.db:25: ran out of space
zone fwd.coulombel.it/IN: loading from master file /etc/bind/fwd.coulombel.it.db failed: label too long
zone fwd.coulombel.it/IN: not loaded due to errors.
The command '/bin/sh -c named-checkzone fwd.coulombel.it /etc/bind/fwd.coulombel.it.db' returned a non-zero code: 1
````

As expected commenting line 19 and 25:

<!-- can do it on vm directly rather than sync -->

output is 

````shell script
Step 11/17 : RUN named-checkzone fwd.coulombel.it /etc/bind/fwd.coulombel.it.db
 ---> Running in 896e2bffe384
zone fwd.coulombel.it/IN: loaded serial 10030
OK
Removing intermediate container 896e2bffe384
 ---> caf7baf04772
Step 12/17 : RUN chmod 760 /etc/bind/fwd.coulombel.it.db
````

### With Infoblox

Making similar and more advanced test with Infoblox.

##### Create zone with element longer than 63


````shell script
clear
export API_ENDPOINT="TARGET_DNS"

curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/zone_auth?_return_fields%2B=fqdn,network_view&_return_as_object=1" -d \
'{"fqdn": "test.loc","view": "default"}'

curl -k -u admin:infoblox -H 'content-type: application/json' -X POST "https://$API_ENDPOINT/wapi/v2.5/zone_auth?_return_fields%2B=fqdn,network_view&_return_as_object=1" -d \
'{"fqdn": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.test.loc","view": "default"}'
````

Output is 

````shell script
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:Duplicate object 'test.loc' of type zone exists in the database.)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "Duplicate object 'test.loc' of type zone exists in the database."
}{ "Error": "AdmConDataError: A domain label is longer than 63 characters.",
  "code": "Client.Ibap.Data",
  "text": "A domain label is longer than 63 characters."
}⏎
````

In verbose mode we can see it returns a `HTTP/1.1 400 Bad Request`.

Bind equivalent would be when defining a zone (not done).


##### Create host record with element longer than 63 or with global size > 255

In script below we show that:

- $a_part_gt_63: OK, 
- $a_part_gt_64 KO, we can not have a part STRICTLY gt (greater than) 64 (1 char more than convention which makes sense as power of 2),
- $a_single_element_64: but element lt (lower than) 64, OK
- $two_element_64: allowed and shows that `.` does not count, OK
- $all_part_62_and_global_is_256: but global size can not be gt 256, KO
- $all_part_62_and_global_is_255, KO
- $all_part_62_and_global_is_254: and strictly lt 255, and `.` counts in global size, as clearly stated in RFC. OK

Same test as in [bind 9](docker-bind-dns-2-length/fwd.coulombel.it.db) but more precise OK.

Here is the script:

````shell script
clear
export API_ENDPOINT="TARGET_DNS"

element_of_size_65="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
echo $element_of_size_65 | wc -c
element_of_size_64="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
echo $element_of_size_64 | wc -c
element_of_size_63="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
echo $element_of_size_63 | wc -c
element_of_size_62="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
echo $element_of_size_62 | wc -c

a_part_gt_63="$element_of_size_64.bbb"
a_part_gt_64="$element_of_size_65.bbb"
a_single_element_64="$element_of_size_64"
two_element_64="$element_of_size_64.$element_of_size_64" 

all_part_62_and_global_is_256="$element_of_size_62.$element_of_size_62.$element_of_size_62.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
all_part_62_and_global_is_255="$element_of_size_62.$element_of_size_62.$element_of_size_62.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
all_part_62_and_global_is_254="$element_of_size_62.$element_of_size_62.$element_of_size_62.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

echo "$all_part_62_and_global_is_256.test.loc" | wc -c
echo "$all_part_62_and_global_is_255.test.loc" | wc -c
echo "$all_part_62_and_global_is_254.test.loc" | wc -c

declare -a arr=(a_part_gt_63 a_part_gt_64 a_single_element_64 two_element_64 all_part_62_and_global_is_256 all_part_62_and_global_is_255 all_part_62_and_global_is_254)

## now loop through the above array
for i in "${arr[@]}"
do
# https://unix.stackexchange.com/questions/397586/how-to-print-the-variable-name-along-with-its-value
# explains why no $ in `arr`
echo -e "= Test with  $i = ${!i} \n"


echo -e "=== Sent payload \n"

payload=$(cat <<EOF
{
  "name": "${!i}.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
EOF
)
echo $payload | jq -M

echo -e "=== try to create \n"

curl -k -u admin:infoblox\
                -H "Content-Type: application/json" \
                -X POST \
                -d "$payload"\
                https://$API_ENDPOINT/wapi/v2.5/record:host

echo -e "\n=== try to lookup \n"

nslookup "${!i}.test.loc" $API_ENDPOINT
echo -e "=------------------------------\n"

done
````

Here is the output

````shell script
[vagrant@archlinux ~]$ export API_ENDPOINT="TARGET_DNS"
[vagrant@archlinux ~]$
[vagrant@archlinux ~]$ element_of_size_65="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
[vagrant@archlinux ~]$ echo $element_of_size_65 | wc -c
65
[vagrant@archlinux ~]$ element_of_size_64="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
[vagrant@archlinux ~]$ echo $element_of_size_64 | wc -c
64
[vagrant@archlinux ~]$ element_of_size_63="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
[vagrant@archlinux ~]$ echo $element_of_size_63 | wc -c
ize_62="faaaaaaa63
[vagrant@archlinux ~]$ element_of_size_62="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
[vagrant@archlinux ~]$ echo $element_of_size_62 | wc -c
62
[vagrant@archlinux ~]$
[vagrant@archlinux ~]$ a_part_gt_63="$element_of_size_64.bbb"
[vagrant@archlinux ~]$ a_part_gt_64="$element_of_size_65.bbb"
[vagrant@archlinux ~]$ a_single_element_64="$element_of_size_64"
[vagrant@archlinux ~]$ two_element_64="$element_of_size_64.$element_of_size_64"
[vagrant@archlinux ~]$
[vagrant@archlinux ~]$ all_part_62_and_global_is_256="$element_of_size_62.$element_of_size_62.$element_of_size_62.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
[vagrant@archlinux ~]$ all_part_62_and_global_is_255="$element_of_size_62.$element_of_size_62.$element_of_size_62.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
[vagrant@archlinux ~]$ all_part_62_and_global_is_254="$element_of_size_62.$element_of_size_62.$element_of_size_62.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
[vagrant@archlinux ~]$
[vagrant@archlinux ~]$ echo "$all_part_62_and_global_is_256.test.loc" | wc -c
256
[vagrant@archlinux ~]$ echo "$all_part_62_and_global_is_255.test.loc" | wc -c
rt_62_and_global255
[vagrant@archlinux ~]$ echo "$all_part_62_and_global_is_254.test.loc" | wc -c
254
[vagrant@archlinux ~]$
[vagrant@archlinux ~]$ declare -a arr=(a_part_gt_63 a_part_gt_64 a_single_element_64 two_element_64 all_part_62_and_global_is_256 all_part_62_and_global_is_255 all_part_62_and_global_is_254) [vagrant@archlinux ~]$
[vagrant@archlinux ~]$ ## now loop through the above array
[vagrant@archlinux ~]$ for i in "${arr[@]}"
> do
> # https://unix.stackexchange.com/questions/397586/how-to-print-the-variable-name-along-with-its-value
> # explains why no $ in `arr`
> echo -e "= Test with  $i = ${!i} \n"
>
>
> echo -e "=== Sent payload \n"
>
> payload=$(cat <<EOF
> {
>   "name": "${!i}.test.loc",
>   "view": "default",
>   "ipv4addrs": [
>     {
>       "ipv4addr": "4.4.4.2"
>     }
>   ]
> }
> EOF
> )
> echo $payload | jq -M
>
> echo -e "=== try to create \n"
>
> curl -k -u admin:infoblox\
>                 -H "Content-Type: application/json" \
>                 -X POST \
>                 -d "$payload"\
>                 https://$API_ENDPOINT/wapi/v2.5/record:host
>
> echo -e "\n=== try to lookup \n"
>
> nslookup "${!i}.test.loc" $API_ENDPOINT
> echo -e "=------------------------------\n"
>
> done
= Test with  a_part_gt_63 = faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbb

=== Sent payload

{
  "name": "faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbb.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
=== try to create

"record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0LmJiYi5mYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWE:faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbb.test.loc/default"
=== try to lookup

Server:         TARGET_DNS
Address:        DNS_IP#53

Name:   faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbb.test.loc
Address: 4.4.4.2

=------------------------------

= Test with  a_part_gt_64 = faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbb

=== Sent payload

{
  "name": "faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbb.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
=== try to create

{ "Error": "AdmConDataError: A domain label is longer than 63 characters.",
  "code": "Client.Ibap.Data",
  "text": "A domain label is longer than 63 characters."
}
=== try to lookup

nslookup: 'faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbb.test.loc' is not a legal IDNA2008 name (domain label longer than 63 characters), use +noidnin
=------------------------------

= Test with  a_single_element_64 = faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

=== Sent payload

{
  "name": "faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
=== try to create

"record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0LmZhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYQ:faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.test.loc/default"
=== try to lookup

Server:         TARGET_DNS
Address:        DNS_IP#53

Name:   faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.test.loc
Address: 4.4.4.2

=------------------------------

= Test with  two_element_64 = faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

=== Sent payload

{
  "name": "faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
=== try to create

"record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0LmZhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYS5mYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWE:faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.test.loc/default"
=== try to lookup

Server:         TARGET_DNS
Address:        DNS_IP#53

Name:   faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.test.loc
Address: 4.4.4.2

=------------------------------

= Test with  all_part_62_and_global_is_256 = faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

=== Sent payload

{
  "name": "faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
=== try to create

{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:A fully qualified DNS name cannot be longer than 255 characters)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "A fully qualified DNS name cannot be longer than 255 characters"
}
=== try to lookup

nslookup: 'faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.test.loc' is not a legal IDNA2008 name (domain name longer than 255 characters), use +noidnin
=------------------------------

= Test with  all_part_62_and_global_is_255 = faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

=== Sent payload

{
  "name": "faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
=== try to create

{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:A fully qualified DNS name cannot be longer than 255 characters)",
  "code": "Client.Ibap.Data.Conflict",
  "text": "A fully qualified DNS name cannot be longer than 255 characters"
}
=== try to lookup

nslookup: 'faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.test.loc' is not a legal IDNA2008 name (domain name longer than 255 characters), use +noidnin
=------------------------------

= Test with  all_part_62_and_global_is_254 = faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

=== Sent payload

{
  "name": "faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
=== try to create

"record:host/ZG5zLmhvc3QkLl9kZWZhdWx0LmxvYy50ZXN0LmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmIuZmFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYS5mYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhLmZhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWE:faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.test.loc/default"
=== try to lookup

Server:         TARGET_DNS
Address:        DNS_IP#53

Name:   faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.test.loc
Address: 4.4.4.2

=------------------------------

[vagrant@archlinux ~]$
````

This is compliant with described observations above.

With verbose we can see in both case it is a 400 where we have a distinct error for domain and total length.

<!-- when both it is total length error which is returned -->

### OpenAPI and length 

See config in previous section [here](7-valid-fqdn.md).

- element_of_size_65="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

````shell script
{
  "errors": [
    {
      "code": 4926,
      "detail": "'faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' is not a 'hostname' - 'metadata.name'",
      "status": 400,
      "title": "INVALID DATA RECEIVED"
    }
  ]
}
````

- element_of_size_64="faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
OK PASSED

- and repeat size 64

````shell script
{
  "errors": [
    {
      "code": 4926,
      "detail": "'faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' is not a 'hostname' - 'metadata.name'",
      "status": 400,
      "title": "INVALID DATA RECEIVED"
    }
  ]
}
````

So OpenAPI implements the size restrictions at hostname level

<!--
### Consequence

But assume that fullname is relative DNS name (open api field) + zone name (in path).
OpenAPI is not aware of it. So in best world we could add a check for length of the full name (relative dns name + zone name).
But it is not mandatory if we have error forwarding (cf. https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md#side-notes)

For instance if we input 

````shell script
{
  "metadata": {
    "name": "faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  }
 }
````

output will be

````shell script
{
  "errors": [
    {
      "code": 141,
      "detail": "Device failed to process requested action. Device returns following http status '400' with error code 'Client.Ibap.Data.Conflict' and details 'A fully qualified DNS name cannot be longer than 255 characters'",
      "status": 400,
      "title": "DEVICE FAILED TO PROCESS THE REQUEST"
    }
  ]
}
````

if OpenAPI hostname is not satisfying to allow underscore we can change it with our own regex, see NS PR#93.

-->

## Appendix about space

<!--
````shell script
17:53:42.733 assertion failed: path: $.errors[0], actual: {"code":4926,"detail":"'testi ngqa' does not match 'THE_BIG_REGEX' - 'metadata.name'","title":"INVALID DATA RECEIVED","status":400}, expected: {code=4926, detail='testi ngqa' is not a 'hostname' - 'metadata.name', status=400, title=INVALID DATA RECEIVED}, reason: [path: $.errors[0].detail, actual: ''testi ngqa' does not match 'THE_BIG_REGEX' - 'metadata.name'', expected: ''testi ngqa' is not a 'hostname' - 'metadata.name'', reason: not equal]
````
because OpenAPI error message changed.
before space not accepted by OpenAPI hostname built in
and now rejected as does not match the regex
the error message is different

visible by switching des, (qcp as loaded see adjust requests) vs uat
-->

### In BIND
if zone contains a space

````shell script
sco ulomb         IN      A       42.42.42.42
````

When building we have

````shell script
Step 11/17 : RUN named-checkzone fwd.coulombel.it /etc/bind/fwd.coulombel.it.db
 ---> Running in 4e6d56dd464e
/etc/bind/fwd.coulombel.it.db:13: unknown RR type 'ulomb'
````

### and with Infoblox

````shell script
payload=$(cat <<EOF
{
  "name": "yo p.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
EOF
)
echo $payload | jq -M

curl -k -u admin:infoblox\
                -H "Content-Type: application/json" \
                -X POST \
                -d "$payload"\
                https://$API_ENDPOINT/wapi/v2.5/record:host
````

output is

````shell script
Status: 400
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:RR name 'yo p' does not comply with policy 'Allow Underscore')",
  "code": "Client.Ibap.Data.Conflict",
  "text": "RR name 'yo p' does not comply with policy 'Allow Underscore'"
}

````


It is actually [this](7-valid-fqdn.md#note-on-infoblox) policy name.
And same error as `scoul_om@b` as [there](7-valid-fqdn.md).

<!--
Assume it would not be catched by Openapi hostname or regex, error fw would still work
as in [consequence](#consequence).
-->

## What about Ä  (shift + " + a)

````shell script
payload=$(cat <<EOF
{
  "name": "dddÄddd.test.loc",
  "view": "default",
  "ipv4addrs": [
    {
      "ipv4addr": "4.4.4.2"
    }
  ]
}
EOF
)
echo $payload | jq -M

curl -k -u admin:infoblox\
                -H "Content-Type: application/json" \
                -X POST \
                -d "$payload"\
                https://$API_ENDPOINT/wapi/v2.5/record:host
````

output is 

````shell script
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:RR name 'ddd\u00e4ddd' does not comply with policy 'Allow Underscore')",
  "code": "Client.Ibap.Data.Conflict",
  "text": "RR name 'ddd\u00e4ddd' does not comply with policy 'Allow Underscore'"
}
````

And `A` is working.

Using bind

````
scáoulomb        IN      A       42.42.42.42
````

````shell script
Step 11/17 : RUN named-checkzone fwd.coulombel.it /etc/bind/fwd.coulombel.it.db
 ---> Running in ffa4902e9043
/etc/bind/fwd.coulombel.it.db:14: sc\195\161oulomb.fwd.coulombel.it: bad owner name (check-names)
/etc/bind/fwd.coulombel.it.db:16: scoul_omb.fwd.coulombel.it: bad owner name (check-names)
[Note build continues but search "However any lookup in that zone will fail." in 7-valid-fqdn.md]
```` 

And A is working.

It is not compliant with RFC2181.