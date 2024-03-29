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


<!-- All work (in part d) linked with proj and other files:

- Non reg secret (ns pr#68) 
- Completed https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md
and applications: https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d-other-applications.md 
=> so that we launch of non reg after PR is merged (it is secrets suite)
all was (doubt but well concluded) clear and linked clearly made in [part D -applications](6-use-linux-nameserver-part-d-other-applications.md).
- This part D-application knowledge is reused in Docker doctor
- Then Docker doctor completed: https://github.com/scoulomb/docker-doctor/blob/main/README.md#link-other-projects
and linked to other project + sre-setup - TestV2.md (prd target + read user comment -> sre-setup pr#29)
- this enables to test device access as linked in docker doctor https://raw.githubusercontent.com/scoulomb/docker-doctor/main/README.md (sre pr#27)
- And opens to next section (e)  where we run image docker directly. This is what enabled to detect issue in part d,
(no need to retest the image with change made with part d/ expose udp)
- nameserver sporadic non reg investigation results: see Cfe "DNS+non+regression+sporadic+failures" [UPDATED 9/12]
We have this error: org.apache.http.conn.ConnectTimeoutException: Connect to xx.xx.xx.xx:443 [/xx.xx.xx.xx] failed: Connect timed out (see difference on connection and request timeout:https://github.com/scoulomb/http-over-socket) on some tests in des
And at same time we had <username> <password > which is matching placeholder in Karateconfig at 1AM
	- hypotesis 0: we should use cookie auth -> NO
	- hypothesis 1:We could think the order is not accurate when we create cronjob and then the secret is overriden is ns pr#68, but it is correct as explained here: https://github.com/scoulomb/myk8s/blob/master/Volumes/secret-doc-deep-dive.md#do-we-need-to-forward-declare-the-secret
	and made pr to k8s https://github.com/kubernetes/website/pull/25027. 
	We can see header is correct `> 1 > Authorization: Basic YWRtaW46aW5mb2Jsb3g=` and `echo "YWRtaW46aW5mb2Jsb3g=" | base64 --decode`.
	If credentials were incorrect we would have a 401.
	- hypothesis 2: lb issue: traceroute TCP and capa https://github.com/scoulomb/docker-doctor#requirements 
	Actually it seems Infoblox drops some queries. Since too many authentication failure are performed. Infoblox stops processing requests. Which explains why only some features are failing and the sporadic effect.
	- hypothesis 3: we do too many authentication requests? -> seems adding user <username>/<password> user fix the issues
	- hypothesis 4:  we do too many FAILED authentication requests in short amount of time?
	This is because we have non-regression where secrets is not setup in other namespaces (QCP, UAT) running at the same time (same cronjob) with wrong credentials.
    This blows Infoblox cluster, and it start dropping packets, including the one of DES which has correct credentials and should work. Indeed same Infoblox instance is used for all test phases,
    Secret in phases different from DES has not been setup, and it is not performed via a Jenkins but via manual script.
    We update the manual script and same challenge as ns pr#68 for Jenkinsfile (order issue, rollout to run nr after load completed). Only done for DNS.
    => Secrets in SRE scripts: PR#76 (we have to repush the secret otherwise overridden with secret along the cj, when automated it is not an issue to re-enter pwd).
    This faces same challenge as ns pr#68 and as described here with the rollout and https://github.com/scoulomb/myk8s/blob/master/Volumes/secret-doc-deep-dive.md#do-we-need-to-forward-declare-the-secret
    PR#76 not ported to other components.
    [TODO: communicate, DONE] When testing this script deleted secrets which invalidates token: https://github.com/scoulomb/myk8s/blob/master/Volumes/secret-doc-deep-dive.md#pr-25027
     It is better, and reduces drastically sporadic errors but still issue. 
    - hypothesis 5: we just do too many requests in a short amount of time and authentication failure was making it reach the throughput limit faster (this is based on observations)
    See: https://community.infoblox.com/t5/API-Integration/Recommended-API-call-rate-limit/td-p/17939 (related question how to prevent from ddos attack)
    Here is an analysis on credentials + error management on Infoblox: https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/6-Infoblox-error-management/infoblox_api_content_type.md 
    For invalid credentials retry it returns a 403. So it does not drop packet for invalid credentials, but makes reach the throughput limit reached faster.
        
    The actual fix is described here: https://github.com/scoulomb/myk8s/blob/master/Setup/ArchDevVM/known-issues.md#issue-b (**before we had to fix several issues**)
    [TODO: could determine Infoblox throughput via JMeter => scoulombel/repos/stress_test/browse,
    DONE HERE: https://github.com/scoulomb/private_script/blob/main/infoblox_throughput/README.md and there link to mirror "Infoblox+throughput+test" OK]
    Some very rare cases still have timeout but fine.

    All hypothesis now aligned with: "DNS+non+regression+sporadic+failures" page OK

- Thus same analysis on infoblox error for hypo 5 also enables to improve **Infoblox credentials management and error forwarding** (see status end of page: https://raw.githubusercontent.com/scoulomb/myDNS/master/3-DNS-solution-providers/1-Infoblox/6-Infoblox-error-management/infoblox_api_content_type.md)''
https://github.com/scoulomb/private_script/blob/main/dns-auto/nocommit_test_error_fw_invalid_cred.sh
[TODO move last version, DONE: https://github.com/scoulomb/private_script/tree/main/dns-auto]
- Misc:
    => non-reg nightly had some issue because tag was not put on good commit, so it runs version without the fix, and also because of pull rate limit did not deliver last version (base image not mirrored)
    => Auto load in des ok (had to relaunch via script as got  500, so do before oc delete cj --all, oc delete dc --all then manual_deploy
    will see later it was issue with find API which is not homogeneous: [TODO fix, DONE: https://github.com/scoulomb/private_script/blob/main/dns-auto/README_find_bug.md]
    https://github.com/scoulomb/myDNS/blob/master/3-DNS-solution-providers/1-Infoblox/3-suite-b-dns-ip-search-api.md#search-endpoint  and
     ../../3-DNS-solution-providers/1-Infoblox/3-suite-b-ip-search-non-homogeneous.md. 
    
    => UAT OOM killed increase mem lim and all worked (pr#91)-> to PRD (load proc: Procedure+for+DEV+to+Load+Network+Automation, 20500184, script follows same version as code, maybe we should ensure to checkout good script version)
    [TODO: Check also fixed DONE:  https://github.com/scoulomb/private_script/blob/main/dns-auto/end_of_year_2020.md#adjust-requests-done]
    => feature loaded was v1lalpha1 to v1 (dns pr#90)
    => We had some point on readiness: https://github.com/scoulomb/myk8s/blob/master/Deployment/resilient-deployment.md (oc describe to see probe + initialdelayseconds with start up probes => OK)

All 5 [TODO] issues here are also referenced: https://github.com/scoulomb/private_script/blob/main/dns-auto/end_of_year_2020.md (put direct link ok)
-->

## Note on exec from and Kubernetes shell expansion

See note on k8s PR: https://github.com/scoulomb/myk8s/blob/master/Volumes/secret-doc-deep-dive.md#PR-25027

<details>
  <summary>Click to expand!</summary>

Here we state what was happening for [override](6-use-linux-nameserver-part-d.md#kubernetes-link) in Kubernetes,
And as it is an override we use exec form as stated [here](6-use-linux-nameserver-part-d.md#also-when-we-override-it-is-like-we-use-the-exec-form).

But Kubernetes has a special feature for environment var expansion!
In kubernetes documentation it is mentioned here:
- Inject data app: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#define-a-command-and-arguments-when-you-create-a-pod
- ConfigMap: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#use-configmap-defined-environment-variables-in-pod-commands

### $(ENV) kubernetes expansion

This is what is done in CM example:
https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#use-configmap-defined-environment-variables-in-pod-commands

#### Test 0

````shell script
echo 'apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dnsv3
  name: dnsv3
spec:
  containers:
  - image: dnsv3
    name: dnsv3
    imagePullPolicy: Never
    command: [ "/bin/sh", "-c", "echo $(ENV_VAR_1) $(ENV_VAR_2)" ]    
    env:
    - name: ENV_VAR_1
      value: "toto"
    - name: ENV_VAR_2
      value: "titi"
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}' > test.yaml

kubectl delete -f test.yaml
kubectl apply -f test.yaml
kubectl logs pod/dnsv3
````

output is 

````shell script
root@sylvain-hp:/home/sylvain# kubectl logs pod/dnsv3
toto titi
````

### Test 1 

But here we use a shell so variable expansion would be done by shell if need 

<!--
(k8s does apply before, a=3, proof echo $(a) not working in normal shell).
-->

````shell script
echo 'apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dnsv3
  name: dnsv3
spec:
  containers:
  - image: dnsv3
    name: dnsv3
    imagePullPolicy: Never
    command: [ "/bin/sh", "-c", "echo $ENV_VAR_1 $ENV_VAR_2" ]    
    env:
    - name: ENV_VAR_1
      value: "toto"
    - name: ENV_VAR_2
      value: "titi"
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}' > test.yaml

kubectl delete -f test.yaml
kubectl apply -f test.yaml
kubectl logs pod/dnsv3
````

output is

````shell script
root@sylvain-hp:/home/sylvain# kubectl logs pod/dnsv3
toto titi
````


### Test 2 

It has a full interest when doing 


````shell script
echo 'apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dnsv3
  name: dnsv3
spec:
  containers:
  - image: dnsv3
    name: dnsv3
    imagePullPolicy: Never
    command: [ "/bin/echo", "$(ENV_VAR_1) $(ENV_VAR_2)" ]    
    env:
    - name: ENV_VAR_1
      value: "toto"
    - name: ENV_VAR_2
      value: "titi"
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}' > test.yaml

kubectl delete -f test.yaml
kubectl apply -f test.yaml
kubectl logs pod/dnsv3
````


Output is 

````shell script
root@sylvain-hp:/home/sylvain# kubectl logs pod/dnsv3
toto titi
````

[IMP1_PR] So here in the doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#use-configmap-defined-environment-variables-in-pod-commands
: we could remove `/bin/sh` to really show the use of `$(VAR_NAME)`.

<!--

[1] In the given example we want to show `$(VAR_NAME)` usage of Kubernetes substitution syntax.

current doc is as #test 0
we use a shell (`/bin/sh`),  it would work without the k8s substitution syntax (which is applied before). 
I propose to replace with a case where variable expansion is needed.

which is #test 2

````
kubectl create -f https://kubernetes.io/examples/configmap/configmap-multikeys.yaml
echo 'apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod-11
spec:
  containers:
    - name: test-container
      image: k8s.gcr.io/busybox
      command: [ "/bin/echo", "$(SPECIAL_LEVEL_KEY) $(SPECIAL_TYPE_KEY)" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_LEVEL
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_TYPE
  restartPolicy: Never' > test.yaml
kubectl apply -f test.yaml
````
output is

````
root@sylvain-hp:/home/sylvain# kubectl logs pod/dapi-test-pod-11
very charm
````

as #test 1 to show variable expansion would be done by shell.

````
echo 'apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod-123456
spec:
  containers:
    - name: test-container
      image: k8s.gcr.io/busybox
      command: [ "/bin/sh", "-c", "echo $SPECIAL_LEVEL_KEY $SPECIAL_TYPE_KEY" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_LEVEL
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_TYPE
  restartPolicy: Never' > test.yaml
kubectl apply -f test.yaml
````
output is

````
root@sylvain-hp:/home/sylvain# kubectl logs dapi-test-pod-123456
very charm
````



-->


### Test 3

Indeed if not if not doing special expansion 

````shell script
echo 'apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dnsv3
  name: dnsv3
spec:
  containers:
  - image: dnsv3
    name: dnsv3
    imagePullPolicy: Never
    command: [ "/bin/echo", "$ENV_VAR_1 $ENV_VAR_2" ]    
    env:
    - name: ENV_VAR_1
      value: "toto"
    - name: ENV_VAR_2
      value: "titi"
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}' > test.yaml

kubectl delete -f test.yaml
kubectl apply -f test.yaml
kubectl logs pod/dnsv3
````

output is 

````shell script
root@sylvain-hp:/home/sylvain# kubectl logs pod/dnsv3
$ENV_VAR_1 $ENV_VAR_2
````

<!--
````
echo 'apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod-123456789
spec:
  containers:
    - name: test-container
      image: k8s.gcr.io/busybox
      command: [ "/bin/echo", "$SPECIAL_LEVEL_KEY $SPECIAL_TYPE_KEY" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_LEVEL
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_TYPE
  restartPolicy: Never' > test.yaml
kubectl apply -f test.yaml
````
output is

````
#  kubectl logs dapi-test-pod-123456789
$SPECIAL_LEVEL_KEY $SPECIAL_TYPE_KEY
````
-->

### Kubernetes has something similar to Docker shell form and exec form but it is always exec from 

And it does care if we use what would look like a shell form or exec form in Docker as here this would be equivalent 
to [test 3](#test-3) with shell form .


````shell script
echo 'apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dnsv3
  name: dnsv3
spec:
  containers:
  - image: dnsv3
    name: dnsv3
    imagePullPolicy: Never
    command: 
    - "/bin/echo"
    -  "$ENV_VAR_1 $ENV_VAR_2"
    env:
    - name: ENV_VAR_1
      value: "toto"
    - name: ENV_VAR_2
      value: "titi"
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}' > test.yaml

kubectl delete -f test.yaml
kubectl apply -f test.yaml
kubectl logs pod/dnsv3
````

output is

````shell script
root@sylvain-hp:/home/sylvain# kubectl logs pod/dnsv3
$ENV_VAR_1 $ENV_VAR_2
````

And it does not output the var as in [test 1](#test-1) or [test 0](#test-0).
Which we would expect in Docker in Shell form see why [here](6-use-linux-nameserver-part-d.md#conclusion).

So to make it work as in test 2 we should use the special syntax

````shell script
echo 'apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dnsv3
  name: dnsv3
spec:
  containers:
  - image: dnsv3
    name: dnsv3
    imagePullPolicy: Never
    command: 
    - "/bin/echo"
    -  "$(ENV_VAR_1) $(ENV_VAR_2)"
    env:
    - name: ENV_VAR_1
      value: "toto"
    - name: ENV_VAR_2
      value: "titi"
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}' > test.yaml

kubectl delete -f test.yaml
kubectl apply -f test.yaml
kubectl logs pod/dnsv3
````

output is 

````shell script
root@sylvain-hp:/home/sylvain# kubectl logs pod/dnsv3
toto titi
````

### It is actually also working in Kubernetes args

#### k8s command + args 
https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#use-environment-variables-to-define-arguments

````shell script
echo 'apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dnsv3
  name: dnsv3
spec:
  containers:
  - image: dnsv3
    name: dnsv3
    imagePullPolicy: Never
    command: 
    - "/bin/echo"
    args:
    -  "$(ENV_VAR_1) $(ENV_VAR_2)"
    env:
    - name: ENV_VAR_1
      value: "toto"
    - name: ENV_VAR_2
      value: "titi"
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}' > test.yaml

kubectl delete -f test.yaml
kubectl apply -f test.yaml
kubectl logs pod/dnsv3
````

output is 

````shell script
root@sylvain-hp:/home/sylvain# kubectl logs pod/dnsv3
toto titi
````


or 

#### void k8s commands and args

````shell script
echo 'apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: dnsv3
  name: dnsv3
spec:
  containers:
  - image: dnsv3
    name: dnsv3
    imagePullPolicy: Never
    command:
    - "" # need to define void otherwise keeps original entrypoint
    args:
    - "/bin/echo"
    -  "$(ENV_VAR_1) $(ENV_VAR_2)"
    env:
    - name: ENV_VAR_1
      value: "toto"
    - name: ENV_VAR_2
      value: "titi"
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}' > test.yaml

kubectl delete -f test.yaml
kubectl apply -f test.yaml
kubectl logs pod/dnsv3
````

output is 

````
root@sylvain-hp:/home/sylvain# kubectl logs pod/dnsv3
toto titishell script
````

So here in the doc they mentioned both 

https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#define-a-command-and-arguments-when-you-create-a-pod

but not here 

https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#use-configmap-defined-environment-variables-in-pod-commands

[IMP_2_PR] They could say command and args sections.
We can use configmap defined environment var (and k8s substitution) not only in pod commands , but also args of container section.

<!--
kubectl create -f https://kubernetes.io/examples/configmap/configmap-multikeys.yaml
echo 'apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod-22
spec:
  containers:
    - name: test-container
      image: k8s.gcr.io/busybox
      command: []
      args: [ "/bin/echo", "$(SPECIAL_LEVEL_KEY) $(SPECIAL_TYPE_KEY)" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_LEVEL
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_TYPE
  restartPolicy: Never' > test.yaml
kubectl apply -f test.yaml
kubectl logs pod/dapi-test-pod-22
````
output is

````
root@sylvain-hp:/home/sylvain# kubectl logs pod/dapi-test-pod-22
very charm
````
-->

### Finally to prove it is a k8s feature
 
This is the equivalent to [void k8s commands and args](#void-k8s-commands-and-args).
 
(entrypoint via cli does not manage to make exec + args)

````shell script
# override (so exec) but with a shell, env var expansion 
sudo docker run --rm --name test-expansion --entrypoint="" --env ENV_VAR_1="toto" dnsv3 /bin/sh -c 'echo $ENV_VAR_1'
# Override but no shell =>  no expansion
sudo docker run --rm --name test-expansion --entrypoint="" --env ENV_VAR_1="toto" dnsv3 /bin/echo $ENV_VAR_1
# Override but no shell but using expansion feature =>  no expansion as it is Kubernetes specific
sudo docker run --rm --name test-expansion --entrypoint="" --env ENV_VAR_1="toto" dnsv3 /bin/echo $(ENV_VAR_1)

````

output is


````shell script
root@sylvain-hp:/home/sylvain# sudo docker run --rm --name test-expansion --entrypoint="" --env ENV_VAR_1="toto" dnsv3 /bin/sh -c 'echo $ENV_VAR_1'
toto
root@sylvain-hp:/home/sylvain# sudo docker run --rm --name test-expansion --entrypoint="" --env ENV_VAR_1="toto" dnsv3 /bin/echo $ENV_VAR_1

root@sylvain-hp:/home/sylvain# sudo docker run --rm --name test-expansion --entrypoint="" --env ENV_VAR_1="toto" dnsv3 /bin/echo $(ENV_VAR_1)
ENV_VAR_1: command not found

root@sylvain-hp:/home/sylvain#
````

And as explained needs a shell (exec form) in other cases;

### No env var 

Sometimes env var expansion is not sufficient and we need a shell as stated here
https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#run-a-command-in-a-shell

## As a consequence 

[IMP1_PR] + [IMP2_PR] + PR#25068 comment => could lead to a new pull request 

- Inject data app: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#define-a-command-and-arguments-when-you-create-a-pod
=> Here arguments is command and args keep it
- ConfigMap: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#use-configmap-defined-environment-variables-in-pod-commands
=> Here we can do PR: https://github.com/kubernetes/website/pull/25089
Which enables to update  PR#25068 in a consistent way

<!--
Note here I did alignment in overview :
https://github.com/kubernetes/website/pull/25068 which is just merged 18Nov2020
and then realigned in another PR: https://github.com/kubernetes/website/pull/25089 in a better way 
and 25089 much better and merged also
In explain below 
we can see cli is using docker terminology but mentions it, except entrypoint so OK
so it is correct to use kubernetes terminology OK, and this was clear in https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d-other-applications.md
and link made in my doc each time: https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d-other-applications.md and referenced link (may have one way from here but actually ok)

There is a link to podman,rocket and https://medium.com/better-programming/kubernetes-is-deprecating-docker-8a9f7566fbca  as want genericity
-->

<!-- did not try init container 
kubectl explain deployment.spec.template.spec.containers
kubectl explain rc.spec.template.spec.containers
kubectl explain job.spec.template.spec.containers
kubectl explain cj.spec.jobTemplate.spec.template.spec.containers
kubectl explain pod.spec.containers


Here they mix

root@sylvain-hp:/home/sylvain# kubectl explain job.spec.template.spec.containers.command
KIND:     Job
VERSION:  batch/v1

FIELD:    command <[]string>

DESCRIPTION:
     Entrypoint array. Not executed within a shell. The docker image's
     ENTRYPOINT is used if this is not provided. Variable references $(VAR_NAME)
     are expanded using the container's environment. If a variable cannot be
     resolved, the reference in the input string will be unchanged. The
     $(VAR_NAME) syntax can be escaped with a double $$, ie: $$(VAR_NAME).
     Escaped references will never be expanded, regardless of whether the
     variable exists or not. Cannot be updated. More info:
     https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell
root@sylvain-hp:/home/sylvain# kubectl explain job.spec.template.spec.containers.args
KIND:     Job
VERSION:  batch/v1

FIELD:    args <[]string>

DESCRIPTION:
     Arguments to the entrypoint. The docker image's CMD is used if this is not
     provided. Variable references $(VAR_NAME) are expanded using the
     container's environment. If a variable cannot be resolved, the reference in
     the input string will be unchanged. The $(VAR_NAME) syntax can be escaped
     with a double $$, ie: $$(VAR_NAME). Escaped references will never be
     expanded, regardless of whether the variable exists or not. Cannot be
     updated. More info:
     https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell
and aligned with our understanding, link inaccurate but not last version of kubectl
And it is visible they to link to docker and mention it except here: Entrypoint array
-->

### Link with CM and secret

Here we had seen ConfigMap and secret
https://github.com/scoulomb/myk8s/blob/master/Volumes/secret-doc-deep-dive.md#note-on-configmap

And the 4 ways to use a cm described here

- https://kubernetes.io/docs/concepts/configuration/configmap which are
    - Command line arguments to the entrypoint of a container (PR#25068: https://github.com/kubernetes/website/pull/25068 => Inside a container command and args) -> this one is a particular case of env var where we can use substitution synthax or shell 
    - Environment variables for a container
    - Add a file in read-only volume, for the application to read
    - Write code to run inside the Pod that uses the Kubernetes API to read a ConfigMap
- aligned with https://github.com/scoulomb/myk8s/blob/master/Volumes/volume4question.md#4-configmap-consumption
On of them is consumption as container in pod command https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#use-configmap-defined-environment-variables-in-pod-commands

</details>