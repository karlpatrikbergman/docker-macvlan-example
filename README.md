# Docker Macvlan Driver Example

## Network Information

### tnm-vm7 = the physical machine
My guess is that br0 is the physical network device on tnm-vm7
```shell
$ ssh root@tnm-vm7
[root@tnm-vm7 ~]# nmcli device show br0 | grep IP4
IP4.ADDRESS[1]:                         172.16.15.233/22
IP4.GATEWAY:                            172.16.12.1
IP4.DNS[1]:                             192.168.201.2
IP4.DNS[2]:                             192.168.201.12
IP4.GATEWAY:                            172.16.12.1
```
### pabe_test = my "private" vm running on tnm-vm7
```shell
$ ssh ssh root@172.16.15.230
[root@pabe-test-machine ~]# nmcli device show eth0 | grep IP4
IP4.ADDRESS[1]:                         172.16.15.230/22
IP4.GATEWAY:                            172.16.12.1
IP4.DNS[1]:                             192.168.201.2
IP4.DNS[2]:                             192.168.201.12
IP4.DOMAIN[1]:                          transmode.s
```
### Docker Machine
Go to local directory of this project:
```shell
$ cd /usr/local/src/docker-macvlan-example
```
I have previously created a docker-machine on the vm pabe_test. It can be listed like so:
```shell
$ docker-machine ls
NAME                ACTIVE   DRIVER       STATE     URL                        SWARM   DOCKER        ERRORS
default             -        virtualbox   Stopped                                      Unknown       
pabe-test-machine   -        generic      Running   tcp://172.16.15.230:2376           v17.05.0-ce 
```
Connect current shell to machine (so my docker client can talk to it)
```shell
$ eval "$(docker-machine env pabe-test-machine)"
```
Now we should be able to create a macvlan network on host (the vm pabe_test)
```shell
$ docker network create -d macvlan \
        --subnet=172.16.15.0/22 \
        --gateway=172.16.12.1 \
-o macvlan_mode=bridge \
    -o parent=eth0 macvlan70
```
Attached XTM docker container to network
```shell
$ docker run --name=node1--net=macvlan70 -d -p 80:80 se-artif-prd.infinera.com/tm3k/trunk-hostenv:latest
```
Retrieve ip address assigned to docker container:
```shell
$ docker inspect node1 | grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.16.12.2
```
Now I can reach the XTM web gui from my development machine by going to  http://172.16.12.2
I repeated the process and verified that I could reach the second container at http://172.16.12.3