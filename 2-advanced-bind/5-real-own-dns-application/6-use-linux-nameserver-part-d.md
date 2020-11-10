# Notes on Docker

## Some mistakes when writing Docker images

When running our Docker image with Docker we realize there was some issues on it, while it was silently ignored by Kubernetes.

First read this as a pre-requisite: 
- https://docs.docker.com/engine/reference/builder/#cmd
- https://docs.docker.com/engine/reference/builder/#entrypoint

### V1 with problem 

````
mkdir /tmp/docker

echo 'FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
ENTRYPOINT ["systemctl",  "start",  "named", ";", "systemctl", "enable",  "named", ";", "sleep", "3600"]
' > /tmp/docker/dnsv1.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/dnsv1.Dockerfile -t dnsv1 
sudo docker run dnsv1
````

Output is 

````shell script
sylvain@sylvain-hp:/tmp/docker$ sudo docker run dnsv1
ERROR:systemctl:Unit ;.service could not be found.
ERROR:systemctl:Unit systemctl.service could not be found.
ERROR:systemctl:Unit enable.service could not be found.
ERROR:systemctl:Unit ;.service could not be found.
ERROR:systemctl:Unit sleep.service could not be found.
ERROR:systemctl:Unit 3600.service could not be found.
````

Here our images is working because start/enable of the service was not mandatory. And is kept alive by systemctl.
But it is not doing our intent.

when doing 
````shell script
ENTRYPOINT ["systemctl",  "start",  "named", ";", "systemctl", "enable",  "named", ";", "sleep", "3600"]
````
We are actually using the exec form and quoting the documentation:

> Unlike the shell form, the exec form does not invoke a command shell. This means that normal shell processing does not happen. For example, ENTRYPOINT [ "echo", "$HOME" ] will not do variable substitution on $HOME. If you want shell processing then either use the shell form or execute a shell directly, for example: ENTRYPOINT [ "sh", "-c", "echo $HOME" ]. 

And as `;` are shell functionality, here it is not processed and it is given as input of `systemctl` which can take several arguments.
Thus the command becomes systemctl with all parameter after arguments of systemctl.

We can check this by doing 

```shell script
ENTRYPOINT ["systemctl",  "start",  "nameffffd", "dddddd", "systemctl", ";", "toto"]
```

More details can be found here:
- https://stackoverflow.com/questions/46797348/docker-cmd-exec-form-for-multiple-command-execution
- https://stackoverflow.com/questions/27158840/docker-executable-file-not-found-in-path

### V2: fix by using `sh -c` in exec form

As we want a shell to process `;`, naturally we want to use `sh -c`.

```shell script
mkdir /tmp/docker

echo 'FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
ENTRYPOINT ["sh",  "-c",  "systemctl start named; systemctl enable named; sleep 300"]
' > /tmp/docker/dnsv2.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/dnsv2.Dockerfile -t dnsv2
sudo docker rm dnsv2 # remove container with that name not the image
sudo docker run --name dnsv2 dnsv2
````

And output of `sudo docker exec -it dnsv2 ps -auxww`:

```shell script
$ sudo docker exec -it dnsv2 ps -auxww
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.2  0.0   2608   536 ?        Ss   13:01   0:00 sh -c systemctl start named; systemctl enable named; sleep 300
bind           7  0.7  0.4 754604 34464 ?        Ssl  13:01   0:00 /usr/sbin/named -f -u bind
root          22  0.0  0.0   2508   516 ?        S    13:01   0:00 sleep 300
root          23  0.0  0.0   5880  2768 pts/0    Rs+  13:01   0:00 ps -auxww
```

This is working! 
But `ctrl-C` signal is not processed because it is launched as subcommand of `sh -c`. 
As we use the exec command `sh -c` is pid 1 but not the subcommand.
We can use a script



### V3: fix by using shell form and a separate script

````shell script
mkdir /tmp/docker

echo '#!/bin/bash
# https://gist.github.com/ikbear/56b28f5ecaed76ebb0ca

echo "This is start named and keep container running."

cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}

trap cleanup SIGINT SIGTERM

systemctl start named
systemctl enable named
systemctl status named

while [ 1 ]
do
  sleep 60 &
  wait $!
done
' > /tmp/docker/myscript.sh

echo 'FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
COPY ./myscript.sh /myscript.sh
RUN chmod u+x /myscript.sh
ENTRYPOINT /myscript.sh
' > /tmp/docker/dnsv3.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/dnsv3.Dockerfile -t dnsv3
sudo docker rm dnsv3 --force # remove container with that name not the image
sudo docker run --name dnsv3 dnsv3
````

He we use a script but use the shell form which start the script with `sh -c`.


This is working but when dong a `ctrl-C` it is not taken into account as raised in the doc
> The shell form prevents any CMD or run command line arguments from being used, but has the disadvantage that your ENTRYPOINT will be started as a subcommand of /bin/sh -c, which does not pass signals. This means that the executable will not be the container’s PID 1 - and will not receive Unix signals - so your executable will not receive a SIGTERM from docker stop <container>.

It would be equivalent to do v4 which is the same as v1

### V4: fix by using exec form and a separate script launch with sh -c


````shell script
echo 'FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
COPY ./myscript.sh /myscript.sh
RUN chmod u+x /myscript.sh
ENTRYPOINT ["sh", "-c", "/myscript.sh"]
' > /tmp/docker/dnsv4.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/dnsv4.Dockerfile -t dnsv4
sudo docker rm dnsv4 --force # remove container with that name not the image
sudo docker run --name dnsv4 dnsv4
````

Here `ctrl-C` does not work because it launched as a subcommand of `sh -c`.

```shell script
$ sudo docker exec -it dnsv4 ps -auxww
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   2608   540 ?        Ss   14:11   0:00 sh -c /myscript.sh
root           6  0.0  0.0   3976  2992 ?        S    14:11   0:00 /bin/bash /myscript.sh
bind           8  0.1  0.4 754604 34504 ?        Ssl  14:11   0:00 /usr/sbin/named -f -u bind
root          24  0.0  0.0   2508   520 ?        S    14:11   0:00 sleep 60
root          30  0.0  0.0   5880  2760 pts/0    Rs+  14:12   0:00 ps -auxww
```


Solution is to use directly the **exec** form (see v5)!


### V5: fix by using exec form and a separate script launched directly


````shell script
echo 'FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
COPY ./myscript.sh /myscript.sh
RUN chmod u+x /myscript.sh
ENTRYPOINT ["/myscript.sh"]
' > /tmp/docker/dnsv5.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/dnsv5.Dockerfile -t dnsv5
sudo docker rm dnsv5 --force # remove container with that name not the image
sudo docker run --name dnsv5 dnsv5
````

and output of ps 

```shell script
$ sudo docker exec -it dnsv5 ps -auxww
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   3976  3016 ?        Ss   14:14   0:00 /bin/bash /myscript.sh
bind           7  0.2  0.4 754604 34492 ?        Ssl  14:14   0:00 /usr/sbin/named -f -u bind
root          23  0.0  0.0   2508   592 ?        S    14:14   0:00 sleep 60
root          30  0.0  0.0   5880  2856 pts/0    Rs+  14:14   0:00 ps -auxww

```

Here we can see that pid 1 is our script directly.

This time `ctrl-C` signal is transmitted.


### V6: Actually we can fix by using **shell** form and a separate script launched with exec


As raised in the doc we can actually use exec to use *shell form* (as we wanted to do in [v3](#v3-fix-by-using-shell-form-and-a-separate-script)):
https://docs.docker.com/engine/reference/builder/#shell-form-entrypoint-example

```shell script
echo 'FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
COPY ./myscript.sh /myscript.sh
RUN chmod u+x /myscript.sh
ENTRYPOINT exec /myscript.sh
' > /tmp/docker/dnsv6.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/dnsv6.Dockerfile -t dnsv6
sudo docker rm dnsv6 --force # remove container with that name not the image
sudo docker run --name dnsv6 dnsv6
```

And `ctrl-c` will work.

### v7: we can use exec form and a separate script launch with sh -c and exec 

Signal transmission would work in [v4](#v4-fix-by-using-exec-form-and-a-separate-script-launch-with-sh--c) if using exec 

```shell script
echo 'FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
COPY ./myscript.sh /myscript.sh
RUN chmod u+x /myscript.sh
ENTRYPOINT ["sh", "-c",  "exec /myscript.sh"]
' > /tmp/docker/dnsv7.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/dnsv7.Dockerfile -t dnsv7
sudo docker rm dnsv7 --force # remove container with that name not the image
sudo docker run --name dnsv7 dnsv7
```

### Conclusion

Recommendation is to use v5. Thus our final DNS image.
In conclusion 

`ENTRYPOINT /script.sh (shell form)` <-> `ENTRYPOINT ["sh", "-c", "/script.sh"] (exec form)`
If shell is used our custom command is not PID1 anymore, and does not transmit signal.

And exec as the effect to replace current shell so it cancels the `sh -c` which enables to transmit interruption signal.
See [v7](#v7-we-can-use-exec-form-and-a-separate-script-launch-with-sh--c-and-exec) and [v6](#v6-actually-we-can-fix-by-using-shell-form-and-a-separate-script-launched-with-exec).

Docker doc has also interesting example with docker stop to show same example:
> This means that the executable will not be the container’s PID 1 - and will not receive Unix signals - so your executable will not receive a SIGTERM from docker stop <container>.

We observe same behavior when doing 

```shell script
sudo docker rm dnsv3-stop dnsv5-stop
sudo docker run --name dnsv3-stop dnsv3
sudo docker run --name dnsv5-stop dnsv5
sudo docker stop dnsv3-stop  # -> long deletion 
sudo docker stop dnsv5-stop # -> immediate deletion
```

As a consequence all docker reference understood here.
Note we can run command directly without entrypoint as stated in the doc.
They can interact as described here:
https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact.
<!-- did not find case where 2 execs needed but theory ok, in array(3,3), it is the shell form which prevents args
-->


## Override entrypoint and command.

when doing 

```shell script
sudo docker run  --entrypoint "echo" --name dnsv3-override dnsv3 "123"
```


This would output

````shell script
$ sudo docker run  --entrypoint "echo" --name dnsv3-override dnsv3 "123"
123
````

Case where override entrypoint and keep command in image

```shell script
echo 'FROM ubuntu
ENTRYPOINT ["echo"]
CMD ["hello"]
' > /tmp/docker/test.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/test.Dockerfile -t test
sudo docker rm testinstance --force # remove container with that name not the image
sudo docker run --name testinstance_11 test
sudo docker run --name testinstance_22 --entrypoint "echo" test
```

Output is 
````shell script
sylvain@sylvain-hp:~$ sudo docker run --name testinstance_11 test
hello
sylvain@sylvain-hp:~$ sudo docker run --name testinstance_22 --entrypoint "echo" test
````
So we lose the args it is consistent with the fact that

> If CMD is defined from the base image, setting ENTRYPOINT will reset CMD to an empty value. In this scenario, CMD must be defined in the current image to have a value.

and notes here: https://docs.docker.com/engine/reference/run/#entrypoint-default-command-to-execute-at-runtime


Note that unlike kubernetes this `--` is not ignored. 

````shell script
$ sudo docker run  --entrypoint "echo" --name dnsv3-override-dash dnsv3 -- "123"
-- 123
````

## Also when we override it is like we use the exec form

here is the proof:

### IP as container env var and shell usage OK

```shell script
$ sudo docker run --entrypoint="" --name dnsv3-override-show-ip0 --env IP=42.42.42.42 dnsv3  /bin/sh -c 'echo $IP'
42.42.42.42
```

### IP as container env var and NO shell usage KO

````shell script
sylvain@sylvain-hp:~$ sudo docker run --entrypoint="" --name dnsv3-override-show-ip-bis --env IP=42.42.42.42 dnsv3  echo $IP

sylvain@sylvain-hp:
````

### IP ENV var defined outside and no shell usage WARNING

We had seen 2 problems above here: https://github.com/scoulomb/myk8s/blob/6e6de11afe4fd78b761d785ecab80de021b7814e/Master-Kubectl/4-Run-instructions-into-a-container.md
Pay attention to that different case where we do NOT use shell it is because the IP is defined in the shell calling the Docker like:

````shell script
IP=44.5.5.6
sylvain@sylvain-hp:~$ sudo docker run --entrypoint="" --name dnsv3-override-show-ip-bis2 --env IP=42.42.42.42 dnsv3  echo $IP
44.5.5.6
````

### Note that system environment var are inherited 

````shell script
sylvain@sylvain-hp:~$ sudo docker run --entrypoint=""  --name dnsv3-override-show-shell-from dnsv3 echo $PWD
/home/sylvain
sylvain@sylvain-hp:~$ sudo docker run --entrypoint=""  --name dnsv3-override-show-shell-fromss dnsv3 /bin/sh -c "echo $PWD"
/home/sylvain
sylvain@sylvain-hp:~$ /bin/sh -c '/bin/sh -c "echo $PWD"'
/home/sylvain
````

## Kubernetes link

We have made the link with Kubernetes for `ENTRYPOINT` and `COMMAND` override:
https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#note-on-args-and-command

- Docker `ENTRYPOINT` <=> k8s `command`
- Docker `CMD` <=> k8s `args`

And the discrepancy between `kubectl run` and `kubectl create job` and `kubectl create deployment`.
Read this as a prerequisite:
https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#discrepancy-between-k-run-and-k-create

Where both of them have discrepancies with `docker run`!

In spite of the effort to align `kubectl run` and `docker run` (see [v1.18](https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/0-kubectl-run-explained.md#obeservations)), kubectl run and docker run have discrepancies:

### Kubectl run 

```shell script
sudo kubectl run dnsv3 --image dnsv3 --dry-run=client -o yaml --command echo -- "123"
```

```shell script
$ sudo kubectl run dnsv3 --image dnsv3 --dry-run=client -o yaml --command echo -- "123"
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dnsv3
  name: dnsv3
spec:
  containers:
  - command:
    - echo
    - "123"
    image: dnsv3
    name: dnsv3
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Here it would create only k8s command (Docker ENTRYPOINT). 
Removing `--command` would lead to only k8s args (Docker CMD) (part of docker CMD can be executable)

which is not aligned with Docker cf. [Override entrypoint and command](#override-entrypoint-and-command).


Quoting https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#discrepancy-between-k-run-and-k-create
> We can not mix command and args with kubectl.

(we can do whatever in a manifest)

Note that the doc is consistent with our finding but ambiguous (actually the challenge is to have several container enginer):

```shell script
➤ kubectl run --help                                                                                                                                                          vagrant@archlinuxCreate and run a particular image in a pod.

Examples:
[...]
  # Start the nginx pod using the default command, but use custom arguments (arg1 .. argN) for that command. 
## MY comment: command is k8s one. Here args are parameter of docker CMD. But docker CMD can have one executable
  kubectl run nginx --image=nginx -- <arg1> <arg2> ... <argN>
  # Start the nginx pod using a different command and custom arguments. 
## MY comment: here args  is docker ENTRYPOINT executable and docker ENTRYPOINT param 
  kubectl run nginx --image=nginx --command -- <cmd> <arg1> ... <argN>
```

<!-- ok checked -->

### Kubectl create job

We can also see in that page:
https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#discrepancy-between-k-run-and-k-create

```shell script
sudo kubectl create job alpine-job --image alpine --dry-run=client -o yaml -- /bin/sleep 10 
$ sudo kubectl create job alpine-job --image alpine --dry-run=client -o yaml -- /bin/sleep 10 
apiVersion: batch/v1
kind: Job
metadata:
  creationTimestamp: null
  name: alpine-job
spec:
  template:
    metadata:
      creationTimestamp: null
    spec:
      containers:
      - command:
        - /bin/sleep
        - "10"
        image: alpine
        name: alpine-job
        resources: {}
      restartPolicy: Never
status: {}
```

Would create a k8s Command thus overrides the Docker ENTRYPOINT (not consistent with  kubectl run => [cf](#kubectl-run) Removing `--command` would lead to only k8s args (Docker CMD)) .
<!-- cf. jenkinsfile with sleep OK CLEAR STOP YES -->
It is not consistent with `sudo docker run alpine  /bin/sleep 5` which would generate a Docker CMD!
This `sudo docker run alpine  /bin/sleep 5` is equivalent to have in Dockerfile `CMD ["executable","param1","param2"] (exec form, this is the preferred form)`.
Given the [doc](https://docs.docker.com/engine/reference/builder/#cmd) and observations made in section ["Also when we override it is like we use the exec form"](#also-when-we-override-it-is-like-we-use-the-exec-form).

Proof `sudo docker run alpine  /bin/sleep 5` would generate a Docker CMD:

````shell script
sylvain@sylvain-hp:~$ sudo docker run alpine echo "hello"
hello
sylvain@sylvain-hp:~$ sudo docker run alpine "hello"
docker: Error response from daemon: OCI runtime create failed: container_linux.go:349: starting container process caused "exec: \"hello\": executable file not found in $PATH": unknown.
ERRO[0000] error waiting for container: context canceled
sylvain@sylvain-hp:~$ sudo docker run --entrypoint="echo" alpine "hello"
hello
````

It also shows that on top of the confusion we can decide to not have and  entrypoint and use a command as executable (first hello)!
Qutoing the docker command [doc](https://docs.docker.com/engine/reference/builder/#cmd).
> The main purpose of a CMD is to provide defaults for an executing container. These defaults can include an executable, or they can omit the executable, in which case you must specify an ENTRYPOINT instruction as well.

<!-- Docker image with mistakes kept in DNS delegation example,
And as cmd and entrypoint is mandatory and was not provided in Docker (see dns-forwarding.md), 
it was given after k run --, given that we did not use --command we created k8s args thus Docker CMD (https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#discrepancy-between-k-run-and-k-create),
so from docker spec it is `CMD command param1 param2` 
(and it is actually the exec form proved here: ## Also when we override it is like we use the exec form, but  `/bin/sh -c` would not be mandatory there as proof:

sylvain@sylvain-hp:~$ sudo docker run --entrypoint="" --name dnsv3-override-show-systemctl-proof dnsv3 systemctl status named
named.service - BIND Domain Name Server
    Loaded: loaded (/usr/lib/systemd/system/named.service, enabled)
    Active: inactive (dead)
sylvain@sylvain-hp:~$ 
# if we sleep. named will be active!
-->

Remind [that](https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#discrepancy-between-k-run-and-k-create) 
> I can only generate k8s command with kubectl create job, not k8s args.

Cronjob and job have same behvavior for command.
 
### But actually when we create a Job from a CronJob the command is ignored

Proof:
````shell script
oc get cj
oc create job api-after-load-non-regression --from=cronjob/{replace-by-cj-name} -- sleep 60
➤ oc get job api-after-load-non-regression -o yaml | grep -A 5 containers                                                                                                     vagrant@archlinux
      containers:
      - command:
        - /bin/sh
        - -c
        - /bin/sh launch.sh 1.0.109 publish $NAMESPACE
````

Note that future version (cf our kubectl ) will have error message

````shell script
sudo kubectl create cronjob alpine-cronjob --image alpine  --schedule="* * * * *"    
sudo kubectl create  job proof --from=cronjob/alpine-cronjob  --dry-run -o yaml -- /bin/sleep 300
````

Output is 

````shell script
sylvain@sylvain-hp:~$ sudo kubectl create  job proof --from=cronjob/alpine-cronjob  --dry-run -o yaml -- /bin/sleep 300
W1110 13:39:13.027471   40327 helpers.go:535] --dry-run is deprecated and can be replaced with --dry-run=client.
error: cannot specify --from and command
sylvain@sylvain-hp:~$ sudo kubectl create  job proof --from=cronjob/alpine-cronjob -- /bin/sleep 300
error: cannot specify --from and command
````
=> error: cannot specify --from and command

It makes sens as it was an override of docker image made in manifest which was overidden in the cli!


### Kubectl create deployment

We can not give command and args directly with Kubectl:
https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#create-deployment


## Version used for test

Used doc of Docker cli: https://github.com/scoulomb/cli
Which was forked https://github.com/scoulomb/cli/blob/master/docs/reference/builder.md#cmd (with latest commit on this file is `e08a441`)

With kubectl (ssh)

````shell script
sylvain@sylvain-hp:~$ sudo kubectl version
Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.3", GitCommit:"2e7996e3e2712684bc73f0dec0200d64eec7fe40", GitTreeState:"clean", BuildDate:"2020-05-20T12:52:00Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.2", GitCommit:"52c56ce7a8272c798dbc29846288d7cd9fbae032", GitTreeState:"clean", BuildDate:"2020-04-16T11:48:36Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
````
<all above concluded>
