# SemVer Bumps for Kubernetes Operator CSVs

A container image that handles bumping Kubernetes Operator Metadata ClusterServiceVersion yaml files. 

We all know the value of [Semantic Versioning](https://semver.org/). Yet, the actual version bumping, 
is tedious and error prone. Not to mention that I'm sure you have 
[better ways of spending your time](https://twitter.com).

This container image helps with taking care of the version bumping of CSVs. 

## Usage

### Requirements

* An Operator Lifecycle Manager (OLM)-compatible operator
* Your operator manifests in some directory in your filesystem
* Each version of the manifests in a separate sub-folder, inside the `manifests` directory. The name
 of the sub-folder is expected to be the version name (e.g. `0.1.2`, `0.3.5`, `1.9.0`, etc.)

Here is an example of the folder structure, from the [3scale Apicast API Gateway Operator](https://github.com/3scale/apicast-operator-metadata):

```bash
$ tree .
.
├── Dockerfile
├── Makefile
└── manifests
    ├── 0.2.0
    │   ├── apicast-operator.v0.2.0.clusterserviceversion.yaml
    │   └── apps_v1alpha1_apicast_crd.yaml
    ├── 0.2.1
    │   ├── apicast-operator.v0.2.1.clusterserviceversion.yaml
    │   └── apps_v1alpha1_apicast_crd.yaml
    ├── 0.2.2
    │   ├── apicast-operator.v0.2.2.clusterserviceversion.yaml
    │   └── apps_v1alpha1_apicast_crd.yaml
    ├── 0.3.0
    │   ├── apicast-operator.v0.3.0.clusterserviceversion.yaml
    │   └── apps_v1alpha1_apicast_crd.yaml
    ├── 0.4.0
    │   ├── apicast-operator.v0.4.0.clusterserviceversion.yaml
    │   └── apps_v1alpha1_apicast_crd.yaml
    └── apicast-operator.package.yaml

6 directories, 13 files
``` 

### Bump Version

To actually bump the version and create the folders and files, run the container, replacing the below
 `PATH_TO_MANIFESTS` with the appropriate path on your filesystem.  
  

```bash
 docker run -v <PATH_TO_MANIFESTS>:/workdir/manifests gsaslis/operator-csv-semver-bumps:latest minor
```  


## Acknowledgements 

The bumping logic is appropriated from [@jonastl's](https://github.com/jonastl) project [bump-semver](https://github.com/tomologic/bump-semver) . 