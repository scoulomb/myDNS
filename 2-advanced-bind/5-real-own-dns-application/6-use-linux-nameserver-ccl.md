# CCL

## Conclusion 

- 6-use-linuxnameserver ccl from A to K.
- Remain consequence of [part i](6-use-linux-nameserver-part-i.md) only

## Consequence of part i

- Test if theme elegant is now fixed (then CI?)
- Push CNAME and README 
    - https://github.com/ValentinH/ValentinH/blob/master/README.md
 <!-- seen from PR https://github.com/scoulomb/attestation-covid19-saison2-auto/pull/12 to ValentinH --> 
    - https://fullyunderstood.com/how-to-create-beautiful-github-profile-readmemd/
    - https://docs.github.com/en/free-pro-team@latest/github/setting-up-and-managing-your-github-profile/managing-your-profile-readme
(I have to selection option share to profile as before july 2020)

- Also scoulomb.github.io does work when coulombel.it is configured, and DNS is working.
As scoulomb.github.io redirect to coulombel.it
````shell script
sylvain@sylvain-hp:~/myDNS_hp$ curl -L scoulomb.github.io | head -n 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   162  100   162    0     0   2000      0 --:--:-- --:--:-- --:--:--  2000
<!DOCTYPE html>
<html lang="en">

    <head>
        <meta charset="utf-8" />
 14 61181   14  9044    0     0  53200      0  0:00:01 --:--:--  0:00:01 53200
curl: (23) Failed writing body (532 != 1384)
````

So if DNS maybe broken `scoulomb.github.io` is safer as can disable CNAME file

<!--
(cert etc is clear)
-->

## Add lien http over socket

Project: https://github.com/scoulomb/http-over-socket

- lien cert: https://github.com/scoulomb/misc-notes/tree/master/tls
- lien host header and cert: https://github.com/scoulomb/http-over-socket/blob/master/README_SUITE_2_HOST_HEADER.md 

(concluded OK)


## VLC consequence 

can use pcloud instead 

(concluded ok)

## make prez 

(optional)