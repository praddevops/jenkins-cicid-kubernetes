#!/bin/sh

shopt -s nullglob

usage(){
    echo 'Usage:'
    echo "$0 (-i path_to_ssh_key) (-d deployment_template_filename_in_deploy_folder) (-s service_template_filename_in_deploy_folder) (-k k8s_admin_host_url_or_ip) (-u k8s_admin_host_user_name)"
    #OPTIONAL TODO to print detailed help for each option
    echo .
    exit 1
}


#
#
#
#

while getopts ":i:d:s:k:u:h" opt; do
   case $opt in
        h)
           usage
           ;;
        i)
           SSH_KEY="$OPTARG"
           ;;
        d)
           DEPLY_TEMPLT="$OPTARG"
           ;;
        s)
           SERVC_TEMPLT="$OPTARG"
           ;;
        k)
           K8S_ADM_HOST="$OPTARG"
           ;;
        u)
           K8S_ADM_USERNAME="$OPTARG"
           ;;
        \?)
           echo "INVALID OPTION: -$OPTARG" >&2
           usage
           ;;
        :)
           echo "Option -$OPTARG requires an argument" >&2
           exit 1
        ;;
    esac
done

if [ -z "$SSH_KEY" ]; then
    echo "SSH key path is not specified!"
    usage
fi

if [ -z "$DEPLY_TEMPLT" ]; then
    echo "Deployment template path is not specified!"
    usage
fi

if [ -z "$SERVC_TEMPLT" ]; then
    echo "Service template path is not specified!"
    usage
fi

if [ -z "$K8S_ADM_HOST" ]; then
    echo "Kubernetes admin host ip/url is not specified!"
    usage
fi

if [ -z "$K8S_ADM_USERNAME" ]; then
    echo "SSH Username to login to Kubernetes Admin host is not specified!"
    usage
fi

scp -i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q deploy/$DEPLY_TEMPLT $K8S_ADM_USERNAME@$K8S_ADM_HOST:/tmp/
scp -i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q deploy/$SERVC_TEMPLT $K8S_ADM_USERNAME@$K8S_ADM_HOST:/tmp/
ssh -i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $K8S_ADM_USERNAME@$K8S_ADM_HOST kubectl apply -f /tmp/$DEPLY_TEMPLT
ssh -i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $K8S_ADM_USERNAME@$K8S_ADM_HOST kubectl apply -f /tmp/$SERVC_TEMPLT
ssh -i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $K8S_ADM_USERNAME@$K8S_ADM_HOST rm -f /tmp/$DEPLY_TEMPLT /tmp/$SERVC_TEMPLT