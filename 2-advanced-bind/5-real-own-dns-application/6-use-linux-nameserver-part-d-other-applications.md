# Notes on Docker: application to other use-cases

This is another example where we apply lesson learnt in [part D](6-use-linux-nameserver-part-d.md).

## objective

Assume we want to launch a non regression job only after a deployment of an API server is performed in a `Jenkinsfile`.

## Solution 0: make jenkins sleep 

## Solution 1: make sleep in job, not working :(

Override job docker entrypoint/k8s command as done here to sleep while the code is loaded and provide version defined in Jenkins file
<!-- what we did initially lb-->

````shell script
def version="1.2
sh "./path/to/oc create job api-after-load-non-regression-${version} --from=cronjob/api-non-regression -- /bin/sh -c 'sleep 60 && launch.sh $version publish des'"
````
version here is Jenkins var and `cronjob/api-non-regression` is Cronjob metadata.name. 

Here we think we  override the job entrypoint as per [part d](6-use-linux-nameserver-part-d.md#kubernetes-link).
It would be the case if it was a normal job but here we use `--from` and it results to a no-ops.
This was explained here [part d: actually when we create a Job from a CronJob the command is ignored](6-use-linux-nameserver-part-d.md#but-actually-when-we-create-a-job-from-a-cronjob-the-command-is-ignored).

We can also do as a proof

````shell script
oc create job api-after-load-non-regression-manual --from=cronjob/dns-automation-api-non-regression --dry-run -o yaml -- /bin/sh -c 'sleep 60 && launch.sh $version publish des' | grep command
➤ oc create job api-after-load-non-regression-manual --from=cronjob/dns-automation-api-non-regression --dry-run -o yaml -- /bin/sh -c 'sleep 60 && launch.sh $version publish des' | grep -A 5 command
      - command:
        - /bin/sh
        - -c
        - /bin/sh launch.sh 1.0.113 publish $NAMESPACE # Nothing change
        env:
        - name: NAMESPACE
````

So we are actually running non reg while we deploy, which is not the purpose as we would target old version.

## Solution 2: use deployment rollout

This is the solution which we advise in comparsion with 0 and 1.

### We will use alpine to show an example

=> unlike job we can not override docker entrypoint / k8s command with kubectl as we had done [in paert d - job entrypoint override](6-use-linux-nameserver-part-d.md#kubernetes-link):
As explained here, we have to define a manifest:
https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#create-deployment


So let's do it 

````shell script
k delete deployment alpine-deployment 
k create deployment alpine-deployment --image=alpine --dry-run=client -o yaml > out.txt

echo ' 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: alpine-deployment
  name: alpine-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: alpine-deployment
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: alpine-deployment
    spec:
      containers:
      - image: alpine
        name: alpine
        command:
        - /bin/sleep
        - "3600"
        resources: {}
status: {}' > alpine-deployment.yaml
k create -f alpine-deployment.yaml
https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment
````

Then we can call the blocking command:

````shell script
sudo kubectl rollout status deployment alpine-deployment

# This is a blocking call and can even get the status 
echo $?
````


In Openshift similar command exist for `dc`

````shell script
oc rollout status dc automation-server ; echo $?
````

### Thus we can apply to our jenkins and any API server

````shell script
def version = "42.1"
// Trigger non regression job after load
sh "./path/to/oc rollout status dc automation-server; echo \$?"
sh "./path/to/oc create job non-regression-afer-load-${version} --from=cronjob/automation-api-non-regression"
````


Which is perfect 

I used `;` and not `&&` for this reason:
https://stackoverflow.com/questions/5130847/running-multiple-commands-in-one-line-in-shell

<!--
For early merge:
proj settings: default reviewer and repo settings: merge check
dns pr#70
-->

We could have following error (in our case only temporary the first time)

````shell script
/oc rollout status dc dns-automation-server
Waiting for rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
error: watch closed before Until timeout
script returned exit code 1
````
It seems to be a known issue
https://github.com/kubernetes/kubernetes/issues/40224

We can increase timeout by doing 

````shell script
kubectl rollout status deployment/app --namespace=app --timeout=60s
````

But if the version of the kubectl we use is tool old, this option will not be available to you.


<!-- relaunching twice and it worked so we can keep it -->

If  reproducing we can combine with solution and make Jenkins sleep, we know that a rollout is taking ~3min.

<!-- dns pr#72 tp remove entrypoint override which was useless as explained in solution 1
and  from [part d](6-use-linux-nameserver-part-d.md#kubectl-create-job).-->



## Assume we have in Openshift template/Helm:

````shell script
    - name: my-non-reg
      command: ["/bin/sh", "-c", "/bin/sh launch.sh ${DOCKER_IMAGE_VERSION} publish $NAMESPACE"]
      env:
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
````

Note here:
- `${DOCKER_IMAGE_VERSION}` is an Openshift template var
- In command we need for  `/bin/sh", "-c"` for environment var `$NAMESPACE`
Similar to that case in [part D](6-use-linux-nameserver-part-d.md#ip-as-container-env-var-and-shell-usage-ok).
Note kube synthax is exec form but consistent with fact overrides use exec form.
And we had seen that  `/bin/sh -c '/bin/sh -c "echo $PWD"'` is [working](6-use-linux-nameserver-part-d.md#note-that-system-environment-var-are-inherited).

- However the second `/bin/sh` seems useless as

````shell script
ssh sylvain@109.29.148.109

mkdir /tmp/docker

echo '#!/bin/bash 
 for i; do 
    echo $i 
 done
' > /tmp/docker/launch.sh


echo 'FROM ubuntu
COPY launch.sh /launch.sh
RUN chmod u+x /launch.sh
' > /tmp/docker/test.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/test.Dockerfile -t test

sudo docker run --name=optionalname --env NAMESPACE="scoulomb-ns" test  /bin/sh -c 'echo $NAMESPACE'
sudo docker run --env NAMESPACE="scoulomb-ns" test  cat launch.sh


sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/bin/sh /launch.sh 1 publish $NAMESPACE'
sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/launch.sh 1 publish $NAMESPACE'

````

Output is 

````shell script
sylvain@sylvain-hp:~$ sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/bin/sh /launch.sh 1 publish $NAMESPACE'
1
publish
scoulomb-ns
sylvain@sylvain-hp:~$ sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/launch.sh 1 publish $NAMESPACE'
1
publish
scoulomb-ns
sylvain@sylvain-hp:~$
````

To be rigorous, as explained in  [part d - Kubectl create job](6-use-linux-nameserver-part-d.md#kubectl-create-job).
When creating a job when we use  kubectl, it creates k8s command and same in our manifest. k8s command is Docker ENTRYPOINT. 
Thus we should use docker ENTRYPOINT so to be equivalent and not docker CMD as done above.
In Docker CLI it is `--entrypoint`, however when doing this we have some issue with docker CLI which does not take params in `--entrypoint` (or not easily). It interprets all as a single executable. So we will not do it.

But in spite of this removing it, prevents from finding the file! why?

So we need it and here is the explanation:
*If we use workdir we need /bin/sh to be located there*: 
Proof when using `WORKDIR`:

````shell script
mkdir /tmp/docker

echo '#!/bin/bash 
 for i; do 
    echo $i 
 done
' > /tmp/docker/launch.sh


echo 'FROM ubuntu
WORKDIR /dir
COPY launch.sh launch.sh

RUN chmod u+x launch.sh
' > /tmp/docker/test.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/test.Dockerfile -t test


sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/bin/sh launch.sh 1 publish $NAMESPACE'
sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c 'launch.sh 1 publish $NAMESPACE'
````
Output is

````shell script
sylvain@sylvain-hp:~$ sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c 'launch.sh 1 publish $NAMESPACE'
/bin/sh: 1: launch.sh: not found
sylvain@sylvain-hp:~$ sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/bin/sh launch.sh 1 publish $NAMESPACE'
1
publish
scoulomb-ns
sylvain@sylvain-hp:~$ sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c 'launch.sh 1 publish $NAMESPACE'
/bin/sh: 1: launch.sh: not found
````
Which reproduces the error.

Thus I will keep it.
<!-- pr 71 reverted with 73-->


## Note on echo status

When doing 

````shell script
sh "./path/to/oc rollout status dc automation-server; echo \$?"
````

as per usage of `;`, it would not make the task fail.
Thus it may be better to remove it.

<!-- ok suffit, DNS pr#74 -->


<!--
pr 70-71-72-73-74
impacts only end of Jenkins file finally => lb pr#293 (with echo)
oc get cj ; oc get jo; oc get po => completed and report is generated. Checked for DNS OK
-->

<!-- when job failng restart container and then send timeout ok
 STOP OK, part d completed only next-->


## Application in docker doctor
 
This knowledge is leverage in docker doctor.
See https://github.com/scoulomb/docker-doctor/blob/main/README.md

And in particular linked to myk8s here:  https://github.com/scoulomb/docker-doctor/blob/main/README.md#Link-other-projects

<!-- `--` in kubectl and docker explained in this doc ok --> 


<!-- All work linked with tasks -->


 

- Non reg secret (ns pr#68) 
- Completed https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md
and applications: https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d-other-applications.md 
=> so that we launch of non reg after PR is merged (it is secrets suite)
all was (doubt but well concluded) clear and linked clearly made in [part D -applications](6-use-linux-nameserver-part-d-other-applications.md).
- This part D-application knowledge is reused in Docker doctor
- Then Docker doctor completed: https://github.com/scoulomb/docker-doctor/blob/main/README.md#link-other-projects
and linked to other project 
- this enables to test device access as linked in docker doctor https://raw.githubusercontent.com/scoulomb/docker-doctor/main/README.md (sre pr#27)
- And opens to next section (e)  where run image docker directly. This is what enabled to detect issue in part d,
(no need to retest the image with change made with part d/ expose udp)
- nameserver sporadic non reg investigation results: "DNS+non+regression+sporadic+failures"
	- Linked to  traceroute TCP and capa https://github.com/scoulomb/docker-doctor#requirements => myk8s updates tough traceroute did not helps at it seems to stop at vip.
	- Then wonders if root cause was secret and wanted to improve but left intact, it was perfect as explained here: https://github.com/scoulomb/myk8s/blob/master/Volumes/secret-doc-deep-dive.md and explain secret flow pr#68 (search for "flow will be") and Jenkins setup (search for jenkins setup) made in first bullet. This is concluded and understood STOP
	and made pr to k8s https://github.com/kubernetes/website/pull/25027 (which is optional for conclusion)

Everything which is here is clearly concluded finally :)
bullet 2 (doubt but well concluded) -> OK STOP

Also side topic was https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-suite-b-dns-ip-search-api.md#search-endpoint which is ok

ADD:
- points from J.
    -Add  note on echo [status](#note-on-echo-status) 
    -add precision on [timeout](#we-will-use-alpine-to-show-an-example)
    - other points ok, checked
    - => All OK
    - Note this passed in jenkins in ns,lb OK
    
- Add point on using template/helm value: https://github.com/scoulomb/myk8s/pull/6
==> OK CCL
coming from next step for target ns (Todo list for production rollout)

Note other points here referenced in this page OK

- Update PR k8s but normal (see pull 6)
I had some issue when cloning k8s website thus made pr online
when needed to update wanted to fetch 
https://stackoverflow.com/questions/9537392/git-fetch-remote-branch
But same issue in different machine
But trying with github desktop via link in html gui,
selecting branch created online, open file in vs code integration, update and then open terminal and use normal command to amend

Note: in initial doc we mention initial phrasing, I remove the Kubelet but fine
And why original phrasing already mentioned
next steps independent and opt

could make similar for cm?
but harder to insert in doc: https://kubernetes.io/docs/concepts/configuration/configmap/ so no
made assumption same behavior as secret which I will not verify then
and about consumption mode mentioned in cm doc, consider aligned:
https://github.com/scoulomb/myk8s/blob/master/Volumes/volume4question.md#4-configmap-consumption

And the 4 ways to use a cm described here https://kubernetes.io/docs/concepts/configuration/configmap/
- Command line arguments to the entrypoint of a container
- Environment variables for a container
- Add a file in read-only volume, for the application to read
- Write code to run inside the Pod that uses the Kubernetes API to read a ConfigMap
aligned with https://github.com/scoulomb/myk8s/blob/master/Volumes/volume4question.md#4-configmap-consumption
"Write code to run inside the Pod that uses the Kubernetes API to read a ConfigMap" is "Can be used by system components and controller (k8s controller)"

But For "Command line arguments to the entrypoint of a container" it would be more accurate to say pod commands
Since as seen in [part d](6-use-linux-nameserver-part-d.md): Docker `ENTRYPOINT` <=> k8s `command`

Moreover 
- From https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#define-a-command-and-arguments-when-you-create-a-pod
> Note: The command field corresponds to entrypoint in some container runtimes. Refer to the Notes below.

Also Here https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#notes
rules are mentionned and same as docker in particular:
> If you supply a command (<-> docker ENTRYPONT) but no args (<-> docker CMD) for a Container, only the supplied command is used. 
> The default EntryPoint and the default Cmd defined in the Docker image are ignored.
(here they mention Docker so fine)
is equivalent to this note in docker doc

https://docs.docker.com/engine/reference/run/#entrypoint-default-command-to-execute-at-runtime

> Passing --entrypoint will clear out any default command set on the image (i.e. any CMD instruction in the Dockerfile used to build it).
(note command -. Docker CMD)

See here [part d](6-use-linux-nameserver-part-d.md#override-entrypoint-and-command) and fact we ue exec form.

Here
https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#notes
array similar to Docker but not the same details, 

https://docs.docker.com/engine/reference/builder/#entrypoint
-> The shell form prevents any CMD or run command line arguments from being used,
CMD [“p1_cmd”, “p2_cmd”] + ENTRYPOINT exec_entry p1_entry (shell from)
CMD exec_cmd p1_cmd      + ENTRYPOINT exec_entry p1_entry (shel form)
leads to /bin/sh -c exec_entry p1_entry

-From: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#use-configmap-defined-environment-variables-in-pod-commands
> You can use ConfigMap-defined environment variables in the command section of the Pod specification using the $(VAR_NAME) Kubernetes substitution syntax.

(note the special synthax)

I would propose
"Inside a Pod command"
https://github.com/kubernetes/website/pull/25068

Merge also optional

SO CAN CONCLUDE OK STOP HERE

-->