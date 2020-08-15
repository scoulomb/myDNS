# Fix build issue

Issue met when did [DNS delegation](../4-bind-delegation/dns-delegation.md).

- GPG error: http://archive.ubuntu.com/ubuntu focal InRelease: At least one invalid signature was encountered.
https://stackoverflow.com/questions/59139453/repository-is-not-signed-in-docker-build
Fix by dong:

````shell script
docker image prune
docker rmi ubuntu --force
````

- Then space issue: https://github.com/onyx-platform/onyx-starter/issues/5

````shell script
add apt get clean or do FROM xenial (+ package name change)
````

Still issue use xenial  but this did not fix, this fix it: 

````shell script
docker rmi $(docker images -q)
docker rm -v $(docker ps -qa)
````

- then error
````shell script
E: There were unauthenticated packages and -y was used without --allow-unauthenticated
Added: --allow-unauthenticated for apt-get
````

But this was needed for xenial

- flush DNS cache for package download

CCL: Docker images should not be changed dio:

````shell script
docker image prune
docker rmi ubuntu --force
docker rmi $(docker images -q)
docker rm -v $(docker ps -qa)
````

I also added entry point in docker images to avoid to do:

````shell script
kubectl run <pod-name> --image=<img-name> --restart=Never --image-pull-policy=Never -- /bin/sh -c "systemctl start named;systemctl enable named;sleep 3600"
````

We could also set a ubuntu release.