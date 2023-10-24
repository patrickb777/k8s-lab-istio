# k8s-lab-istio
A KinD Kubernetes Cluster bootstrapped with Metal LB and an Istio Service Mesh.

## Setup
Clone this repo locally and change into the directory.  Build the cluster with `$ make`.  Verify the cluster and ingress are working with `$ curl -v <gateway_ip/mockserver/echo`.

## Clean up
To destroy the cluster run `$ make clean`.

## Vagrant
A `Vagrantfile` exists in `/vagrant` directory that will bootstrap a Debian Vagrant box with Docker, Kubernetes and Helm. Note the VM requires a minumum of 8gb of memory and 4x CPUs for Istio.
