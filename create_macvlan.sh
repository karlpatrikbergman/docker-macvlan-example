#!/usr/bin/env bash
docker network create -d macvlan \
    --subnet=172.16.15.0/22 \
    --gateway=172.16.12.1 \
    -o macvlan_mode=bridge \
    -o parent=eth0 macvlan70