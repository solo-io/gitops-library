North/South:

0 - baseline

1 - routes
 - 1.1.a-route-cluster1
 - 1.1.b-route-cluster2
 - 1.2.a-weighted-multicluster

2 - security
 - 2.1.a-tls-cluster1 (TODO)
 - 2.2.b-tls-cluster2 (TODO)
 - 2.1.c-tls-weighted-multicluster (TODO)

3 - fault injection
 - 3.1.a-add-header
 - 3.2.a-add-delay
 - 3.3.a-add-retry
 
4 - HA
 - 4.1.a-failover (TODO)


East/West - ksvc-selector:

0 - baseline
 
1 - trafficpolicy
 - 1.1.a-abort-500-details-ksvc 
 - 1.2.a-retries-reviews-ksvc 
 - 1.3.a-delay-ratings-ksvc
 - 1.4.a-timeout-reviews-ksvc 

East/West - vhost-selector:

0 - baseline
 
1 - trafficpolicy
 - 1.1.a-abort-500-vhost
 - 1.2.a-delay-1s-vhost
 - 1.2.b-delay-4s-vhost
 - 1.3.a-ratelimit-vhost