# Jenkins-helm-kubernetes

Jenkins pipeline to deploy new image to Kubernetes cluster using Helm chart

### Kubernetes 

* You must have a kubernetes admin host setup with kubeconfig to run kubectl commands to manage cluster resources

### App code is located in src/main/node-app. Any changes made will trigger the pipeline which builds new image and updates the Kubernetes deployment with new image

## CICD pipeline:

Jenkins version: 2.401.1

Jenkins Plugin Requirements(in addition to the default plugins): AnsiColor, Pipeline Utility Steps, Dynamic Extended Choice Parameter Plug-In (Tested Version 1.0.1), Active Choices (Tested Version 2.7.2)

Jenkins should have sufficient permission to access kubernetes cluster (kube config must be configured with jenkins)

### Following credentials should be present in Jenkins

* Dockerhub username and password must be available in Jenkins with credentials id `docker-login` (Credential type: Username with password)

### Jenkins Troubleshooting

* If pipeline fails due to `org.jenkinsci.plugins.scriptsecurity.sandbox.RejectedAccessException: Scripts not permitted to use....`, go to Manage Jenkins-->In process Script Approval to approve the scripts 


## Note
* Here, we are deploying to `default` namespace. In an Enterprise organization, there will be multiple environments like dev, test, production. Each application and its enviroment will have its own namespace and may be present in seperate clusters. So, in such scenario, deployment and service templates should include namespace parameter as well and the resources have to be created in clusters specific to each enviroment and application by using the kube config context while executing `kubectl apply`

* Helm relase name (`my-release` in this project) can be named as you wish. It will be appended to the names of the k8s objects created by Helm which is how helm tracks it's chart resources

## Significance of release name in Helm

The release name in Helm is significant for the following reasons:

* **It uniquely identifies a release.** Each Helm release is associated with a unique name, which allows you to easily track and manage your deployments.
* **It is used in Helm templates.** Helm templates allow you to customize the Kubernetes manifests that are generated for a release. You can use the release name in templates to insert dynamic values into the manifests, such as the name of the deployment or service.
* **It is used by Helm commands.** Many Helm commands, such as `helm install`, `helm upgrade`, and `helm rollback`, require you to specify the release name. This allows you to operate on specific releases in your cluster.

### Examples of how the release name is used in Helm:

* To view the status of a release, you can use the following command:

Use code with caution.

`helm status [RELEASE_NAME]`


* To rollback a release to a previous revision, you can use the following command:

`helm rollback [RELEASE_NAME] [REVISION]`


* To delete a release, you can use the following command:

`helm delete [RELEASE_NAME]`


* To use the release name in a Helm template, you can use the following syntax:

`{{ .Release.Name }}`

This will insert the release name into the manifest at that point.
Other uses of the release name in Helm

In addition to the above, the release name can also be used by Helm to store other information about a release, such as the chart version, namespace, and release notes. This information can be useful for troubleshooting and auditing purposes.

Overall, the release name is an important part of Helm because it allows you to uniquely identify, manage, and customize your deployments.

### Docker Troubleshooting

* To run the docker without sudo, add the user (`jenkins`) to the docker group

Create `docker` group if it doesn't exist already

`sudo groupadd docker`

Add the user to the docker group.

`sudo usermod -aG docker jenkins`

You would need to log out and log back in so that your group membership is re-evaluated or type the following command:

`su -s jenkins`

* If you are still getting `Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.40/containers/json: dial unix /var/run/docker.sock: connect: permission denied`, try the following command

`sudo chmod 666 /var/run/docker.sock`
