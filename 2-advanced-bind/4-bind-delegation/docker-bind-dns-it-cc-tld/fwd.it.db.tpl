$TTL    86400
@       IN      SOA     ns1.tld.it. root.tld.it. (
                      10030         ; Serial
                       3600         ; Refresh
                       1800         ; Retry
                     604800         ; Expiry
                      86400         ; Minimum TTL
)
; Name Server

; [1] NS records for it zone
@                 IN      NS       ns1.tld.it.
; [4] this says that mydns1.gandi.it. DNS is authoritative for `coulombel.it` zone
; As this name server is hosted at the same domain as the domain name itself (https://docs.gandi.net/en/domain_names/advanced_users/glue_records.html)
; we need a glue record pointing to this DNS
; If the domain name for the DNS which is resolving coulombel.it was not in .it domain like myns1.gandi.net. the glue would not be needed.
; In the end it is the same as [1] which is present in all section except here:
;   - we care particularly about the A record pointing to the second DNS
;   - the final A record (coulombel.it) in not defined in other DNS zone file and not in this zone file unlike test.it
coulombel         IN      NS       myns1.gandi.it.
; A Record Definitions

; [2] Glue record for it zone. Though not use needed for test.it to work. Cf. 3-deploy-named-in-a-pod.md (Note on NS records)
ns1.tld.it.       IN      A        127.0.0.1
; xx to be replaced by ip address of delegated DNS
myns1.gandi.it.   IN      A        xx.xx.xx.xx

; [3] test.it domain which is resolved directly in tld
test              IN      A       43.43.43.43

; [5] Here I show that if we define A record in delegated DNS and in top level DNS, the NS is followed
; If I remove from delegated DNS it is even not returned at all
; This completes comment in 3-deploy-named-in-a-pod.md (Note on NS records)
override.coulombel IN A 89.89.89.89