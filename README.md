<!-- Main Repository language -->
[![Language](https://img.shields.io/badge/language-bash-green.svg)](https://img.shields.io/badge/language-bash-green.svg)

<!-- Repository License -->
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/ramonamela/guidance_cloud/blob/master/LICENSE)


# Cloud Utils

Utils to configure Guidance and COMPSs in a cloud environment.

---

## Table of Contents

* [Commands](#commands)
* [Contributing](#contributing)
* [Disclaimer](#disclaimer)
* [License](#license)

---

## Commands

```bash
./create_snapshot.sh -h
./create_cluster.sh -h
```

### Create snapshot
Before launching any execution, the snapshots that will serve as base to create the cluster master and workers need to be created. The most important information supplied in this step is the available amount of space in the disk both in the master and worker nodes.
Once this variables have been correctly set, launching the command as follows will create both snapshots:

```bash
./create_snapshot.sh --props=production.props
```

It is possible to store as many property files as wanted. They must be placed in the ```props``` folder.

<details><summary>Show snapshot properties description</summary>

<p>



</p>
</details>

### Create cluster
Once the snapshots have been created (the same snapshot can serve as base for several runs) a cluster with the amount of requested nodes can be created in order to launch a COMPSs execution.  

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
