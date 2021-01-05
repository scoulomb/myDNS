# Negative cache 

From:
https://www.ionos.fr/digitalguide/hebergement/aspects-techniques/enregistrement-soa/

> Le champ « Minimum » marque la fin. 
> Ce champ correspond au Time to Live qu’on rencontre dans les autres enregistrements DNS. 
> Ce champ précise combien de temps un client peut conserver les données dans le cache avant de devoir renouveler sa requête.
> Généralement le TTL est enregistré de manière globale pour l’ensemble de la zone avec la mention $TTL.
> Dans un tel cas, il est inutile de répéter cette mention dans chaque enregistrement.
> Le nom de la zone peut être défini au début du fichier au moyen de la mention $ORIGIN.

> L’enregistrement se fait toujours au début du fichier de zone.

> `<name> <class> <type> <mname> <rname> <serial> <refresh> <retry> <expire> <minimum>`

> Les champs peuvent tout simplement être saisis à la suite, sur une même ligne. Tandis que l’enregistrement est généralement assez simple dans les autres types de records, l’enregistrement SOA est quant à lui un peu plus complexe. Pour une meilleure lisibilité, on dispose habituellement les champs de manière imbriquée et subordonnée.

````
$ORIGIN
$TTL
@ 	<class>	<type> <mname> <rname> (</rname></mname></type></class>
		<serial></serial>
		<refresh></refresh>
		<retry></retry>
		<expire></expire>
		<minimum></minimum>
)
````

For example

````shell script
$ORIGIN example.org.
$TTL 1750
@	IN	SOA	master.example.org admin\.master.example.org (
	2019040502	; serial
	86400		; refresh
	7200		; retry
	3600000	; expire
	1750		; minimum
)
	IN	NS	a.iana-servers.net.
www	IN	A	93.184.216.34
````

or [here](../5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db).


> Quand on les enregistre de cette manière, les TTL et Domain-Name sont enregistrés par avance. 
> Le signe @ au début d’un enregistrement renvoie à l’indication d’origine. 
> Pour pouvoir imbriquer plusieurs valeurs temporelles et les répartir sur plusieurs lignes, on utilise des parenthèses.

From:
https://tools.ietf.org/html/rfc2308#section-4
From : RFC 2308 / DNS NCACHE / March 1998

> The SOA minimum field has been overloaded in the past to have three
> different meanings, 
> - the minimum TTL value of all RRs in a zone, 
> - the default TTL of RRs which did not contain a TTL value
> - and the TTL of negative responses.

> Despite being the original defined meaning, the first of these, the
> minimum TTL value of all RRs in a zone, has never in practice been
> used and is hereby deprecated.

>  The second, the default TTL of RRs which contain no explicit TTL in
>  the master zone file, is relevant only at the primary server.  After
>  a zone transfer all RRs have explicit TTLs and it is impossible to
>  determine whether the TTL for a record was explicitly set or derived
>  from the default after a zone transfer. 

>  Where a server does not
>  require RRs to include the TTL value explicitly, it should provide a
>  mechanism, not being the value of the MINIMUM field of the SOA
>  record, from which the missing TTL values are obtained.  How this is
>   done is implementation dependent.

>  The Master File format [RFC 1035 Section 5] is extended to include
>  the following directive:
>  $TTL <TTL> [comment]


>  All resource records appearing after the directive, and which do not
>  explicitly include a TTL value, have their TTL set to the TTL given
>  in the $TTL directive.  SIG records without a explicit TTL get their
>  TTL from the "original TTL" of the SIG record [RFC 2065 Section 4.5].

>   **The remaining of the current meanings, of being the TTL to be used
>   for negative responses, is the new defined meaning of the SOA minimum
>   field.**

In summary:
- Use `TTL` in record,
- If not use `$TTL` of the zone
- `Minimum` of `SOA` is used for negative cache
Some implem may still use it in old meanining (cf Ionos page) but RFC is very clear


Why it is important?
Assume we want to perform a modify a record.
And we implement it as a:
1. Deletion 
2. Followed by a create 

If a recursive asks for a record between step 1 and 2.
It will cache the NXDOMAIN  (no such domain) for mumber of seconds specified in  `Minimun` field of TTL.
Thus after step 2 some recurive server could continue to answer NXDOMAIN while the TTL of SOA did not expire.
And create some outage.
It can be acceptable if this Minimum value is low.

<!-- ok -->