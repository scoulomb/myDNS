## WIP

### TODO => 5/01 => OK

- all below ok except root/private.md

- https://github.com/scoulomb/myk8s/blob/master/Repo-mgmt/repo-mgmt.md

 private github with private file?
- Doc: https://opdhsblobprod01.blob.core.windows.net/contents/4a6d75bb3af747de838e6ccc97c5d978/4aa9cbe69e42108831906b959b0b48f6?sv=2018-03-28&sr=b&si=ReadPolicy&sig=yWx%2Bo6mXn3LBXCtcee%2FmqP7kEd15IZH6PLwpTuC2%2F8A%3D&st=2020-06-19T08%3A23%3A21Z&se=2020-06-20T08%3A33%3A21Z
+ infoblox pdf

ADD OPTIONAL.FIX (after sent)
- cd: resource versioning juge ok
- v0: spec.ipv4 is not an array, as we will allow only a 1-1 mapping => multi pillars (allowed it as evolution and + views, ask more details)
- prx comment in [proposal](4-Analysis/4-private-proposal.md) 

- fix k8s doc in [source ip](2-advanced-bind/1-bind-in-docker-and-kubernetes/2-understand-source-ip-in-k8s.md#doc-typo) -> skip

### DONE

- reorganize aconf page and api details DONE OK
- All integrated one aconf->git (confirm), faire git->aconf
OK all integrated what remain is now the API, what is relevant in aconf in git OK
lien todo.md OK osef (2occ)-> pushed no come back
16/06 + the impact on check by name: https://github.com/scoulomb/myDNS/blob/master/4-Analysis/2-compare-apis.md#view-management OK
- LATER WROTE API: (api commit): update 2waysOK (git <-> aconf) -> confirms seems done OK
from compare [API](4-Analysis/2-compare-apis.md#Notes-on-record-set-creation-API) and [proposal](4-Analysis/3-b-towards-a-k8s-like-api-apply-same-concept-to-DNS.md)
+ 4

-  2020-06-25 review API avec oeil neuf ms semble ok? update 2ways again ok
[proposal](4-Analysis/4-private-proposal.md#host-body) => comment OK
STOP OK CONFIRM MAIL OK


- Mail links Azure OK
- Try API for real SKIP
- nslookup default type A then AAAA OKOK
- check TTL? at record level, global level OK DONE                                                                                                                                                                                                                                                                                                                                         
-  https://github.com/scoulomb/myDNS/blob/master/4-Analysis/2-compare-apis.md#view-management OK
impact on name check OK

### Dedicated repo for DNS OK

````shell script
[12:33][master]✓ ~/dev/myDNS
➤ git remote rm origin                                                                                                                                                        vagrant@archlinux[12:33][master]✓ ~/dev/myDNS
➤ git remote add origin https://github.com/scoulomb/myDNS.git                                                                                                                 vagrant@archlinux[12:33][master]✓ ~/dev/myDNS
➤ git push -u origin master                                                                                                                                                   vagrant@archlinuxEnumerating objects: 326, done.
Counting objects: 100% (326/326), done.
Delta compression using up to 10 threads
Compressing objects: 100% (314/314), done.
Writing objects: 100% (326/326), 6.06 MiB | 93.00 KiB/s, done.
Total 326 (delta 160), reused 0 (delta 0)
remote: Resolving deltas: 100% (160/160), done.
To https://github.com/scoulomb/myDNS.git
 * [new branch]                master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.

➤ git clone https://github.com/scoulomb/misc-notes.git                                                                                                                        vagrant@archlinuxCloning into 'misc-notes'...
remote: Enumerating objects: 313, done.
remote: Counting objects: 100% (313/313), done.
remote: Compressing objects: 100% (222/222), done.
remote: Total 313 (delta 154), reused 224 (delta 80), pack-reused 0
Receiving objects: 100% (313/313), 6.07 MiB | 450.00 KiB/s, done.
Resolving deltas: 100% (154/154), done.
[12:38] ~/dev
➤ git reset --hard  d1ce43d752808553f75ebec174d5c3cc2b614174                                                                                                                  vagrant@archlinuxfatal: not a git repository (or any parent up to mount point /home/vagrant)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
➤ git push --force                                                                                                                                                            vagrant@archlinuxTotal 0 (delta 0), reused 0 (delta 0)
To https://github.com/scoulomb/misc-notes.git
 + d8a7f5e1d779...d1ce43d75280 master -> master (forced update)
[12:39][master]✓ ~/dev/misc-notes
➤
````

vpn ti push to git hub no need to disconnect vpn
do ➤ sudo systemd-resolve --flush-caches