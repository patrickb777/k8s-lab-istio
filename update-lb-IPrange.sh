#!/bin/bash
sed -i "s/172.*/$(docker network inspect -f '{{.IPAM.Config}}' kind | cut -c3-9 | awk '{print $1"255.200-"$1"255.250"}')/g" ./cluster/metallb-config.yaml