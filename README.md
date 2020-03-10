<!-- Main Repository language -->
[![Language](https://img.shields.io/badge/language-bash-green.svg)](https://img.shields.io/badge/language-bash-green.svg)

<!-- Repository License -->
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/ramonamela/guidance_cloud/blob/master/LICENSE)


# Cloud Utils

Utils to configure Guidance and COMPSs in a cloud environment.

---

## Table of Contents

* [Commands](#commands)
* [Executing GUIDANCE](#exec)
* [Contributing](#contributing)
* [Disclaimer](#disclaimer)
* [License](#license)

---

## Commands

```bash
./create_snapshot.sh -h
./create_cluster.sh -h
```
This commands take into account the information presented in a configuration file.

### Create snapshot
Before launching any execution, the snapshots that will serve as base to create the cluster master and workers need to be created. The most important information supplied in this step is the available amount of space in the disk both in the master and worker nodes.
Once this variables have been correctly set, launching the command as follows will create both snapshots:

```bash
./create_snapshot.sh --props=production.props
```

It is possible to store as many property files as wanted. They must be placed in the ```props``` folder.

### Create cluster
Once the snapshots have been created (the same snapshot can serve as base for several runs) a cluster with the amount of requested nodes can be created in order to launch a COMPSs execution.

```bash
./create_cluster.sh --props=production.props
```

### Configuration file
It is possible to store as many property files as wanted. They must be placed in the ```props``` folder. The following configuration corresponds to the biggest execution performed until now. 

<details><summary>Show properties description</summary>


<p>

The content of the production.xml file is as follows:
```
## General project information
USERNAME="computational.genomics.bsc"
PUBLIC_SSH_FILE="${HOME}/.ssh/id_rsa.pub"
PROJECT_NAME="guidance"
IDENTIFICATION_JSON="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../guidance-252716-784e2a010688.json"

## Base instance information
BASE_INSTANCE_NAME="guidancebase"
SNAPSHOT_NAME="snap${PROJECT_NAME}"
OVERRIDE_INSTANCE="true"

## Bucket information
#BUCKET_NAME="bucket-${PROJECT_NAME}"
BUCKET_NAME="guidance_bucket"

## Cluster options
CLUSTER_INSTANCE_NAME="guidancecluster"
NODE_MEM="standard"  # standard, highmem, highcpu
NODE_CPUS=64
NUM_NODES=8
```

The first block of information concerns the identification information in order to access the Google Cloud platform. First, the username of the Google Cloud account must be set. Next, a public ssh file in order to access the remote machines to monitor the execution and the project name into which the execution will run. Finally, the identification json corresponding to the authentification service with all the permisions correctly set is given.

The second block specifies the name of the base instance that will be created in order to install all the dependencies and then create a snapshot with the specified name. In addition, there is a boolean value to point out whether an existant image with the given name should be erased or not.

</p>
</details>

## Execution

Once the cluster has been created, the following actions must be performed:

* Copy all the necessary files to the cluster
* Copy the configuration file to the cluster
* SSH into the master machine and execute the file `launch.sh` and wait until the execution finishes
* Copy all the files that need to be stored into the bucket or any other persistent disk
* Destroy the cluster through the Google Cloud's console

### Offline execution

With the previous instruction, GUIDANCE is launched directly in a console that should remain open during the whole execution. Nevertheless, in order to be able to shut down the local machine, the next command could be used:

```
ssh user@{master_ip} "/home/user/launch.sh > /home/user/output.txt 2> error.txt &"&
```

This way, the output is stored in the supplied file instead of the console. This enables shutting down the local machine at the same time that it is possible to check the progress of the execution.

## Contributing

All kinds of contributions are welcome. Please do not hesitate to open a new issue,
submit a pull request or contact the author if necessary. 
 

## Disclaimer

This is part of a collaboration between the [Computational Genomics][cg-bsc] and the [Workflows and Distributed Computing Team][wdc-bsc] group at the [BSC][bsc] and is still
under development. 


## License

Licensed under the [Apache 2.0 License][apache-2]


[wdc-bsc]: https://www.bsc.es/discover-bsc/organisation/scientific-structure/workflows-and-distributed-computing
[cg-bsc]: https://www.bsc.es/discover-bsc/organisation/scientific-structure/computational-genomics
[bsc]: https://www.bsc.es/

[apache-2]: http://www.apache.org/licenses/LICENSE-2.0
