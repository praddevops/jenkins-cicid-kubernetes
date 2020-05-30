#!/usr/bin/env groovy
def version
pipeline {
    agent any
    

    options {
        ansiColor('xterm')
        timestamps()
    }
    
    parameters {
       choice(name: 'Action', choices: ['build','deploy'], description: 'build: to build an image and push to dockerhub. deploy: to deploy to k8s')
       string(name: 'ReleaseVersion', defaultValue:'1', description: 'RELEASE VERSION NUMBER to tag an image in build stage. N/A when Action is "deploy"')
       string(name: 'deployment_image_version', defaultValue:'', description: 'Enter the image version to deploy. N/A when Action is "build"')
       string(name: 'kubernetes_admin_host', defaultValue:'', description: 'kubernetes admin host where kubeconfig is located. N/A when Action is "build"')
       string(name: 'kubernetes_admin_host_login_username', defaultValue:'', description: 'username to login (ssh) to kubernetes admin host. N/A when Action is "build"')
    }

    environment {
            RELEASE_VERSION = "${params.ReleaseVersion}"
            SECRETKEYFILE = credentials('ssh_key')
            DOCKERHUBUSERNAME = credentials('dockerhub_username')
            DOCKERHUBPASSW = credentials('dockerhub_pw')
    }
  stages {

        stage('Set version') {
            when {
                expression { "${params.Action}" == 'build' }
            }
            steps {
              script {
                // use 'version' to tag an image before publishing to a docker registry 
                def tokenizedVersion = "${RELEASE_VERSION}".tokenize(".")
                def release = tokenizedVersion[0]
                version = "${release}.${env.BUILD_NUMBER}.${env.GIT_COMMIT.substring(0, 5)}"  
                }
                echo "${version}"
              }
            }
        
        stage('Build Docker Image & Push to repository') {
            when {
                expression { "${params.Action}" == 'build' }
            }
            steps {
             script{
                print ('Building the image')
                sh """
                sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine -y
                sudo yum update -y --skip-broken
                sudo yum install -y docker
                sudo service docker start
                sudo docker system prune -a -f
                sudo docker build . -f build/Dockerfile --no-cache -t ${DOCKERHUBUSERNAME}/node-app:${version}
                sudo docker login --username=${DOCKERHUBUSERNAME} --password ${DOCKERHUBPASSW}
                sudo docker push ${DOCKERHUBUSERNAME}/node-app:${version}
                sudo docker logout
                """
              } 
            }
        }
        stage('Deploy to Kubernetes') {
            when {
                expression { "${params.Action}" == 'deploy' }
            }
            steps {
              script{
                def deploy_version = "${params.deployment_image_version}"
                def REMOTEUSERNAME = "${params.kubernetes_admin_host_login_username}"
                print ('deploying to kubernetes')
                sh """
                set +x
                cat ${SECRETKEYFILE} > ssh_key
                chmod 400 ssh_key
                sed "s/tagVersion/${deploy_version}/g" -i deploy/nodeapp-deployment.yaml
                scp -i ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q deploy/nodeapp-deployment.yaml ${REMOTEUSERNAME}@${params.kubernetes_admin_host}:/tmp/
                scp -i ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q deploy/nodeapp-service.yaml ${REMOTEUSERNAME}@${params.kubernetes_admin_host}:/tmp/
                ssh -i ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTEUSERNAME}@${params.kubernetes_admin_host} kubectl apply -f /tmp/nodeapp-deployment.yaml
                ssh -i ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTEUSERNAME}@${params.kubernetes_admin_host} kubectl apply -f /tmp/nodeapp-service.yaml
                ssh -i ssh_key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTEUSERNAME}@${params.kubernetes_admin_host} rm -f /tmp/nodeapp-deployment.yaml /tmp/nodeapp-service.yaml
                """
              } 
             
             }
        }
    }
    post { 
        always {
          cleanWs()
        }
    }
}