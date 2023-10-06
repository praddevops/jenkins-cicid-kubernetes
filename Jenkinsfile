#!/usr/bin/env groovy
def version = 'latest'
def MajorReleaseVersion = '1' //This should match with the Major Release Version of the application
properties([parameters([
    [$class: 'ChoiceParameter', 
        choiceType: 'PT_SINGLE_SELECT', 
        description: 'Select the BuildAction from the Dropdown List', 
        filterLength: 1, 
        filterable: false, 
        name: 'BuildAction', 
        randomName: 'choice-parameter-5631314439613978', 
        script: [
            $class: 'GroovyScript', 
            fallbackScript: [
                classpath: [], 
                sandbox: true, 
                script: 
                    'return [\"Error loading the choices\"]'
            ], 
            script: [
                classpath: [], 
                sandbox: true, 
                script: 
                    'return ["build-only","nobuild-deploy","build-and-deploy"]'
            ]
        ]
    ],
    [$class: 'CascadeChoiceParameter',
        choiceType: 'PT_SINGLE_SELECT',
        description: 'Enter the version of the Image, previously built, to deploy when nobuild-deploy is selected as the BuildAction',
        name: 'HelmAction',
        randomName: 'choice-parameter-6631314453175624',
        referencedParameters: 'BuildAction',
        filterLength: 1, 
        filterable: false,
        script: [
            $class: 'GroovyScript',
            fallbackScript: [
                classpath: [],
                sandbox: true,
                script: "return['Error loading the choices']"
            ],
            script: [
                classpath: [],
                sandbox: true,
                script:
                    """
                    // if (BuildAction != 'build-only'){
                    //   return ['helm-get','helm-dryrun','helm-install','helm-upgrade','helm-rollback','helm-uninstall']
                    // }else{
                    //   return ['NotApplicable']
                    // }

                    if (BuildAction == 'nobuild-deploy'){
                      return ['helm-get','helm-dryrun','helm-install','helm-upgrade','helm-rollback','helm-uninstall']
                    } else if (BuildAction == 'build-and-deploy'){
                      return ['helm-install','helm-upgrade']
                    } else {
                      return ['NotApplicable']
                    }
                    """
            ]
        ]
    ],
    [$class: 'CascadeChoiceParameter',
        choiceType: 'PT_SINGLE_SELECT',
        description: 'OS/ARCH of the Kubernetes cluster nodes. Docker image build is dependent on the underlying Architecture of the nodes',
        name: 'ARCH',
        randomName: 'choice-parameter-7831311453178624',
        referencedParameters: 'BuildAction,HelmAction',
        filterLength: 1, 
        filterable: false,
        script: [
            $class: 'GroovyScript',
            fallbackScript: [
                classpath: [],
                sandbox: true,
                script: "return['Error loading the choices']"
            ],
            script: [
                classpath: [],
                sandbox: true,
                script:
                    """
                    if (BuildAction in ['build-only', 'build-and-deploy']  && !(HelmAction in ['helm-get','helm-dryrun','helm-rollback','helm-uninstall'])){
                      return ['linux/arm/v7','linux/arm64/v8','linux/amd64']
                    }else{
                      return ['NotApplicable']
                    }
                    """
            ]
        ]
    ],
    [$class: 'DynamicReferenceParameter',
        choiceType: 'ET_FORMATTED_HTML',
        omitValueField: true,
        description: 'Enter the version of the Image, previously built, to deploy when nobuild-deploy is selected as the BuildAction',
        name: 'ImageVersion',
        randomName: 'choice-parameter-8631314456178624',
        referencedParameters: 'BuildAction,HelmAction',
        script: [
            $class: 'GroovyScript',
            fallbackScript: [
                classpath: [],
                sandbox: true,
                script: "return['Error loading the choices']"
            ],
            script: [
                classpath: [],
                sandbox: true,
                script:
                    '''
                    if (BuildAction in ["build-only","build-and-deploy"] || HelmAction in ["helm-get","helm-dryrun","helm-rollback","helm-uninstall"]) {
                      return "<input type=\\"text\\" name=\\"value\\" value=\\"NotApplicable\\" />"
                    }else{
                      return "<input type=\\"text\\" name=\\"value\\" value=\\"latest\\" />"
                    }
                    '''
            ]
        ]
    ]
    ])])
pipeline {
    agent any
    

    options {
        ansiColor('xterm')
        timestamps()
    }

    parameters{
      string(name: 'KubeconfigFilePath', defaultValue:'', description: 'kubeconfig file path if not present in $HOME/.kube/')
    }
    

  stages {

        stage('Set Build Version') {
            when {
                expression { "${params.BuildAction}" != 'nobuild-deploy' && !("${params.HelmAction}" in ["helm-get","helm-dryrun","helm-rollback","helm-uninstall"])} 
            }
            steps {
              script {
                // use 'version' to tag an image before publishing to a docker registry 
                def tokenizedVersion = "${MajorReleaseVersion}".tokenize(".")
                def release = tokenizedVersion[0]
                version = "${release}.${env.BUILD_NUMBER}.${env.GIT_COMMIT.substring(0, 5)}"  
                }
                echo "BUILD VERSION: ${version}"
              }
            }
        
        stage('Build Docker Image & Push to repository') {
            when {
                expression { "${params.BuildAction}" != 'nobuild-deploy' && !("${params.HelmAction}" in ["helm-get","helm-dryrun","helm-rollback","helm-uninstall"])}
            }
            steps {
             script{
                print ('Building the image')
                sh """
                set +x
                # yum remove docker \
                #  docker-client \
                #  docker-client-latest \
                #  docker-common \
                #  docker-latest \
                #  docker-latest-logrotate \
                #  docker-logrotate \
                #  docker-engine -y
                #  yum update -y --skip-broken
                # yum install -y docker
                # service docker start
                # 
                """
                withCredentials([usernamePassword(credentialsId: 'docker-login', passwordVariable: 'docker_pw', usernameVariable: 'docker_user')]) {
                sh"""
                docker build . -f build/Dockerfile --no-cache --build-arg ARCH="${params.ARCH}" -t ${docker_user}/node-app:${version} -t ${docker_user}/node-app:latest
                docker login --username=${docker_user} --password ${docker_pw}
                docker push ${docker_user}/node-app:${version}
                docker push ${docker_user}/node-app:latest
                echo 'Docker Image Push: Completed'
                docker system prune -a -f
                docker logout
                """
                }              
              } 
            }
        }

        stage('Helm') {
          when {
                expression { "${params.BuildAction}" != 'build-only' }
            }
          steps {
            script{
              HELMACTION = "${params.HelmAction}"
              KUBECONFIG= "${params.KubeconfigFilePath}"
              if ("${params.BuildAction}".toString() == 'nobuild-deploy'){
                version = "${params.ImageVersion}".toString()
                print "DEPLOYING THE IMAGE VERSION SPECIFIED BY THE USER: ${version}"
              } else{
                print "DEPLOYING IMAGE VERSION ===> ${version}"
              }
              
              //Following linux script works on dash interpreter. If using a different interpreter, script may not work
              sh"""
              set +x
              export KUBECONFIG=$KUBECONFIG
              export HELMACTION=$HELMACTION
              echo 'kubeconfig file path set to ${KUBECONFIG}'   
              if [ '$HELMACTION' =  'helm-get' ] 
              then
                echo 'HELM GET'
                helm get all my-release
              elif [ '$HELMACTION' =  'helm-dryrun' ] 
              then
                echo 'HELM DRY RUN'
                helm install --dry-run my-release helm/nodeapp-deployment
              elif [ '$HELMACTION' =  'helm-install' ]
              then
                echo 'HELM INSTALL'
                helm install my-release helm/nodeapp-deployment  --set 'image.tag=${version}'
              elif [ '$HELMACTION' =  'helm-upgrade' ]
              then
                echo 'HELM UPGRADE'
                helm upgrade my-release helm/nodeapp-deployment  --set 'image.tag=${version}'
              elif [ '$HELMACTION' =  'helm-rollback' ]
              then
                echo 'HELM ROLLBACK'
                helm rollback my-release
              elif [ '$HELMACTION' =  'helm-uninstall' ]
              then
                echo 'HELM UNINSTALL'
                helm uninstall my-release
              else
                echo 'HELM: NO CHANGES MADE'
              fi
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