## Setting up a Docker Swarm on the Multimico Cluster

### Purpose
This page describes the steps necessary to set up a stack using Docker Swarm within the Multimico cluster.

#### Connection to the multimico cluster
In a terminal window, type `ssh multimico@clt-lab-n-1171.zhaw.ch`.

You should see the following prompt: **`multimico@clt-lab-n-1171:~$`**

#### Retrieve the inventory of Docker nodes.
Type **`multimico@clt-lab-n-1171:~$`**`docker node ls` to get a table with basic information about the nodes.
```
ID                            HOSTNAME         STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
3gt2xdfletulgfag7exfu89up *   clt-lab-n-1171   Ready     Active         Leader           20.10.17
emhbsbj9thy4xexyldxkq5bbi     clt-lab-n-1172   Ready     Active                          20.10.17
5gmn0vg4ghb5q4415zjei9vd4     clt-lab-n-1173   Down      Active                          20.10.17
t998bkzrt70low3xm70f55khz     clt-lab-n-1174   Ready     Active                          20.10.17
```

