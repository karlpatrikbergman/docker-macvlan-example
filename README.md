# Docker Macvlan Driver Example

## Scenario
Run one or more XTM docker containers on your virtual machine (ex. pabe_test on tnm-vm7)  
Give each of the containers a unique ip number, available on the network.  
&nbsp;  
*** 

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
Using [this](https://atlas.transmode.se/bitbucket/users/pabe/repos/libvirt-examples/browse/get_domain_ip_address.sh) 
script I find that the ip address of my virtual machine is 172.16.15.230.
```shell
$ ssh root@172.16.15.230
[root@pabe-test-machine ~]# nmcli device show eth0 | grep IP4
IP4.ADDRESS[1]:                         172.16.15.230/22
IP4.GATEWAY:                            172.16.12.1
IP4.DNS[1]:                             192.168.201.2
IP4.DNS[2]:                             192.168.201.12
IP4.DOMAIN[1]:                          transmode.se
```
Now I know the gateway for the network where my vm resides, and also the subnet from which to find  available ip addresses.
## Create docker macvlan network
### Docker Machine
I have used docker machine to install docker engine on my vm "pabe_test", and will use it to execute docker commands remotely.
An alternative is to ssh to the vm, install docker and run commands.  
Go to local directory of this project:
```shell
[root@pabe-test-machine ~]# exit
logout
Connection to 172.16.15.230 closed. 
$ cd /usr/local/src/docker-macvlan-example
```
List my docker-machines:
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
Run bash script "create_macvlan.sh". It looks as follows:
```shell
docker network create -d macvlan \
    --subnet=172.16.15.0/22 \
    --gateway=172.16.12.1 \
    -o macvlan_mode=bridge \
    -o parent=eth0 macvlan70
```
Run it:
```shell
$ create_macvlan.sh
```
Now we can run and attach an XTM docker container to network
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