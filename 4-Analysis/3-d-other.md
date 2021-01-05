# Misc

<!-- cf before ok, no come back before on 3, in particular similar to k8s api and then show higher level, 
 and pb my idempo was ok -->


## Question on the key for delete and modify

taking example of [infoblox DNS](../3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md). 
    - the key for A record is type + record name + ip. 
    - the key host record is  type + name (not the IP)

We would need to provide the IP. Query parameters or body?

### Query parameters

Query parameters is working but it impacts the behavior.
Like `/path/to/api?sessionName=$sessionName` or `/path/to/api?ipv4=$ipv4`
They are usually used to filter adn pagination.

### Delete body

Technically nothing prevents from making a DELETE with a body but it does not follow the standard.

From https://tools.ietf.org/html/rfc7231#section-4.3.5

> A payload within a DELETE request message has no defined semantics;
sending a payload body on a DELETE request might cause some existing
implementations to reject the request.

OpenAPI 3.0 now refuses delete in the body. This is specified here. This can be problematic if using it (and in particular connexion).
 
https://swagger.io/specification/#operationRequestBody (page seen on Jan 2021, it is 3.0.3 version)

> The request body applicable for this operation. 
> The requestBody is only supported in HTTP methods where the HTTP 1.1 specification RFC7231 has explicitly defined semantics for request bodies.
> In other cases where the HTTP spec is vague, requestBody SHALL be ignored by consumers.

But hey changed their mind: https://github.com/OAI/OpenAPI-Specification/pull/2117/commits
So that version 3.1.0 says: https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.1.0.md#requestBodyObject (f8449d1)

> The request body applicable for this operation.
> The `requestBody` is fully supported in HTTP methods where the HTTP 1.1 specification [RFC7231](https://tools.ietf.org/html/rfc7231#section-4.3.1) has explicitly defined semantics for request bodies.
> In other cases where the HTTP spec is vague (such as [GET](https://tools.ietf.org/html/rfc7231#section-4.3.1), [HEAD](https://tools.ietf.org/html/rfc7231#section-4.3.2) and [DELETE](https://tools.ietf.org/html/rfc7231#section-4.3.5)), 
>`requestBody` is permitted but does not have well-defined semantics and SHOULD be avoided if possible.


We have to be aware some load balancer drop body in a `DELETE`:
https://stackoverflow.com/questions/36048959/issue-with-request-body-in-options-or-delete-request-with-google-load-balancer

Now some API like Kubernetes uses body in delete to specifiy options (for instance job deletion options) 

See:
- https://github.com/scoulomb/myk8s/blob/6e6de11afe4fd78b761d785ecab80de021b7814e/Master-Kubectl/2-kubectl-create-explained-ressource-derived-from-pod-appendices.md#deletion-policy
- https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#deleteoptions-v1-meta

See also:
- https://stackoverflow.com/questions/299628/is-an-entity-body-allowed-for-an-http-delete-request
- https://restfulapi.net/rest-put-vs-post/

<!--
configuration+engine+API
https://kubernetes.io/docs/reference/using-api/api-concepts/#dry-run
-> no deeper but different dryrun
-->

### Other impacts 

When we have several A with same name but different IP it is doing a round robin.
See [here](../2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-k.md)

Some change management process could consider that adding a DNS record is safe (standard) but actually it is not.
We can break a service by directing to wrong ip

<!--
VALIDATION -> NO SERVICE WAS IMPACTED
VERIFICATION: change is ok
-->

## Kubernetes and declarative model 

See article: : https://tanzu.vmware.com/content/blog/kubernetes-for-product-managers 
And expand to https://github.com/scoulomb/myk8s/blob/master/container-engine/container-engine.md

<!-- concluded with expansion with podman, above ok YES-->


## Can I implement a modify as a delete followed by a create ? 

F5 uses transaction.
DNS could have some side effect with the zone TTL.

See [negative ttl](../2-advanced-bind/6-cache/negative-ttl.md).

<!-- gandi? can access soa in text mode but not $TTL OK -->

<!-- above OK - all STOP -- ccl !--> 

