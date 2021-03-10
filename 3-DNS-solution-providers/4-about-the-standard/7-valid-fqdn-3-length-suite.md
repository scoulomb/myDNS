# Note on max size

## Why the 254

When using Infoblox we had seen [in Note on length / section "Create host record with element longer than 63 or with global size > 255"](7-valid-fqdn-2-length.md#create-host-record-with-element-longer-than-63-or-with-global-size--255), max size was achieved when 
`wc -c` returns 254 (see `echo "$all_part_62_and_global_is_254.test.loc`).

It actually means that max size is achieved when actual size is 253.
 

As a proof see 

````shell script
[vagrant@archlinux docker-bind-dns-2-length-limit]$ echo A | wc -c
2
[vagrant@archlinux docker-bind-dns-2-length-limit]$ echo AB | wc -c
3
[vagrant@archlinux docker-bind-dns-2-length-limit]$ echo ABC | wc -c
4
[vagrant@archlinux docker-bind-dns-2-length-limit]$ echo ABC | wc -m
4
````

For n char, `wc -c` returns n+1.
Note `wc -c`, `wc -m` returns same value.

Why `wc` returns an extra char, because it counts new line, see:
https://serverfault.com/questions/287370/why-wc-c-always-count-1-more-character

````shell script
[vagrant@archlinux ~]$  echo -n ABC | wc -c
3
[vagrant@archlinux ~]$  echo -n ABC | wc -m
3
````

<!-- STOP IS NOW OK -->

However from https://tools.ietf.org/html/rfc2181

> A full domain name is limited to 255 octets (including the separators).

## So why 253 is the limit?

This is well explained here: https://devblogs.microsoft.com/oldnewthing/20120412-00/?p=7873s

<!-- mirrored in 
resource/What-is-the-real-maximum-length-of-a-DNS-name.md -->

Therefore it is consistent.

Also note that

````shell script
[vagrant@archlinux ~]$ echo "$all_part_62_and_global_is_254.test.loc"
faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.test.loc
[vagrant@archlinux ~]$ export maxdns="$all_part_62_and_global_is_254.test.loc"
[vagrant@archlinux ~]$ python
Python 3.9.1 (default, Dec 13 2020, 11:55:53)
[GCC 10.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import os
>>> print(os.getenv("maxdns"))
faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.faaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.test.loc
>>> print(len((os.getenv("maxdns"))))
253
````

We have `Python's len(dns_name) = 253 = 253 ascii char = 253 octet` where  `size_of(ascii_char) = 1 octet`.

## However it assumes we use ASCII characters.

RFC2181 allows non ascii characters in the name.
See also: https://developer.mozilla.org/en-US/docs/Mozilla/Internationalized_domain_names_support_in_Mozilla

For example if we have a Japanese domain name

http://ジェーピーニック.jp

Python len is 

```shell script
Python 3.9.1 (default, Dec 13 2020, 11:55:53)
[GCC 10.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> domain="ジェーピーニック.jp"
>>> len(domain)
11
>>> len("Ä")
1
```

but 

````shell script
export domain="ジェーピーニック.jp"
echo $domain | wc -c
echo $domain | wc -m

echo "Ä" | wc -c
echo "Ä" | wc -m
````

output is 

````shell script
28
12
3
2
````

## Infoblox policy

Assume we use policy named allow underscore as depicted in [what is a valid hostname, note on Infoblox](7-valid-fqdn.md#note-on-infoblox) 

Creation of A record with Japanese name gives an error:
 
````shell script
payload=$(cat <<EOF
{
  "name": "ジェーピーニック.test.loc",
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
````

This will lead to 

````shell script
{ "Error": "AdmConDataError: None (IBDataConflictError: IB.Data.Conflict:RR name '\u30b8\u30a7\u30fc\u30d4\u30fc\u30cb\u30c3\u30af' does not comply with policy 'Allow Underscore')",
  "code": "Client.Ibap.Data.Conflict",
  "text": "RR name '\u30b8\u30a7\u30fc\u30d4\u30fc\u30cb\u30c3\u30af' does not comply with policy 'Allow Underscore'"
}
````

However it allows underscore.

<!--
$ echo "-" | wc -c
2
-->

Therefore if we want to allow underscore the logic here:
https://codereview.stackexchange.com/questions/235473/fqdn-validation
should be corrected with underscore in the regex.
<!--only if we want to allow it
project SUITE-7809

for auto flow via dnsi we did it as some client wanted it but could have said automated record should not support it
and layer above in template (at create/assess) there said not allowed as we have this check https://codereview.stackexchange.com/questions/235473/fqdn-validation (could be non blocking)
while back end itself is permissive => OK, here from this details angle and stor comment clear OK

regex dnsi not crazy OK => link non nr see end of year 2020: https://github.com/scoulomb/private_script  
-->
If we would allow japanese character, it would not be appropriate.

## Note on printable char

Finally given that we have at least 3 dot when len is at maximum, the number of printable char is 250:
https://stackoverflow.com/questions/32290167/what-is-the-maximum-length-of-a-dns-name

## Behavior with bind9

Finally bind seems to allow less characters.
See [fwd.test.it.db](docker-bind-dns-2-length-limit/fwd.test.it.db) where 

````shell script
(line 13); export a="definition below"  then echo $a.test.it | wc -c 
(line 14); $a.test.it | wc -c is 250
(line 15)aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaa.test.loc    IN      A       42.42.42.42
(line 16); $a.test.it | wc -c is 251
(line 17) aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaa   IN      A       42.42.42.42
(line 18); $a.test.it | wc -c is 252
(line 19) aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaa  IN      A       42.42.42.42
````
And as seen we have to remove 1 char from `wc -c` output.
<!-- 
also jetbrains highlight return same as wc -c, add test.loc in definition file to see it --> 

<!--
cd 3-DNS-solution-providers/4-about-the-standard/docker-bind-dns-2-length-limit
-->

````shell script
cd docker-bind-dns-2-length-limit
docker-compose up --build 
````

outputs

````shell script
---> Running in 8f9c6bd1efa9
dns_master_load: /etc/bind/fwd.test.it.db:17: ran out of space
dns_master_load: /etc/bind/fwd.test.it.db:19: ran out of space
````

Whereas limit is not reached. 

<!-- STOP here on why limit is different -->
<!-- project SUITE-7809
do check on templ and not in input of engine comp (field with xl value)
but check when assessing or whatever OK (com EV)
In dnsi had not check Did not total as zone + host in different place but use infoblox forwarding OK YES
-->

<!--
Did not test japanese and bind
Synced : "Note+on+length+2" OK => 10/03/2021
-->

<!-- consider bind 9 issue stop there and not open bug OK FORBIDDEN 
- reading flow ok
- and added that dnsi allows underscore OK YES
- ms blogs also said
If you use UTF-8 encoding, then the maximum length is harder to describe since UTF-8 is a variable-length encoding.
cf. japanese in this doc STOP HERE
https://www.figer.com/Publications/utf8.htm
also underscore: https://theasciicode.com.ar/ascii-printable-characters/underscore-understrike-underbar-low-line-ascii-code-95.html is extended ascii which is ascii
https://fr.wikipedia.org/wiki/ASCII_%C3%A9tendu
> Ce terme est informel et peut être critiqué pour deux raisons : d'une part cette dénomination pourrait laisser penser que le standard ASCII aurait été étendu, alors qu'il désigne en fait un ensemble de normes qui incluent le sous-ensemble ASCII ;
Sufficient here OK
- and wc -c cf. so answer
So concluded
-->
