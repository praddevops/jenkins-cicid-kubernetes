# Jenkins-cicd-kubernetes
Jenkins pipeline to deploy new image to Kubernetes cluster

### Kubernetes 
* You must have a kubernetes admin host setup with kubeconfig to run kubectl commands to manage cluster resources

### App code is located in src/main/node-app. Any changes made will trigger the pipeline which builds new image and updates the Kubernetes deployment with new image

## CICD pipeline:

Jenkins version: 2.234

Jenkins Plugin Requirements(in addition to default plugins): AnsiColor, Pipeline Utility Steps

### Following credentials should be present in Jenkins

* `ssh_key` (credential type: SSH Username with private key) to connect to the compute instance
* `dockerhub_username` (Credential type: secret text): "Dockerhub username"
* `dockerhub_pw` (Credential type: secret text): "Dockerhub repo password"

### Jenkins Troubleshooting

* If pipeline fails due to `org.jenkinsci.plugins.scriptsecurity.sandbox.RejectedAccessException: Scripts not permitted to use....`, go to Manage Jenkins-->In process Script Approval to approve the scripts 


