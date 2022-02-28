#!/usr/bin/env bash

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Set variables
if [[ -z ${AZ_CLIENT_KEY} ]]; then
  echo "Please provide environment variable AZ_CLIENT_KEY contining the Azure Client Secret"
  exit 1
fi

if [[ -z ${AZ_CLIENT_ID} ]]; then
  echo "Please provide environment variable AZ_CLIENT_ID containg the Azure Client ID"
  exit 1
fi

if [[ -z ${AZ_TEN_ID} ]]; then
  echo "Please provide environment variable AZ_TEN_ID containing the Azure Tenant ID"
  exit 1
fi

if [[ -z ${AZ_SUB_ID} ]]; then
  echo "Please provide environment variable AZ_SUB_ID containing the Azure Subscription ID"
  exit 1
fi

if [[ -z ${SSH_PRIV_FILE} ]]; then
  echo "Please provide environment variable SSH_PRIV_FILE"
  exit 1
fi

if [[ -z ${SSH_PUB_FILE} ]]; then
  echo "Please provide environment variable SSH_PUB_FILE"
  exit 1
fi

if [[ -z ${PULL_SECRET} ]]; then
  echo "Please provide environment variable PULL_SECRET"
  exit 1
fi

if [[ -z ${CLUSTER_NAME} ]]; then
  echo "Please provide environment variable CLUSTER_NAME"
  exit 1
fi

SEALED_SECRET_NAMESPACE=${SEALED_SECRET_NAMESPACE:-sealed-secrets}
SEALED_SECRET_CONTROLLER_NAME=${SEALED_SECRET_CONTROLLER_NAME:-sealed-secrets}

#extract values from values.yaml
eval $(parse_yaml values.yaml "VALUES_")

#form the data strucutre containing all the different ids
AZ_ID='{"clientId": "'$AZ_CLIENT_ID'", "clientSecret": "'$AZ_CLIENT_KEY'", "tenantId": "'$AZ_TEN_ID'", "subscriptionId": "'$AZ_SUB_ID'"}'

#read in public ssh key
ssh_pub_key=$(cat ${SSH_PUB_FILE})

cp templates/install-config.azure.yaml templates/install-config.yaml

install_config=$(helm template install-config . -s templates/install-config.yaml --set provider.sshPublickey="$ssh_pub_key" --values values.yaml | sed -e '/---/d' -e '/Source/d')
#remove the install config from templates so helm doesnt try to install it
rm templates/install-config.yaml
ENC_INST_CFG=$(echo -n "$install_config" | kubeseal --raw --name=$VALUES_cluster-install-config --namespace=$VALUES_cluster --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)

# Encrypt the secret using kubeseal and private key from the cluster
echo "Creating Secrets"

ENC_AZ_ID=$(echo -n ${AZ_ID} | kubeseal --raw --name=$VALUES_cluster-azure-creds --namespace=$VALUES_cluster --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_PULL_SECRET=$(echo -n ${PULL_SECRET} | kubeseal --raw --name=$VALUES_cluster-pull-secret --namespace=$VALUES_cluster --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_SSH_PRIV=$(cat ${SSH_PRIV_FILE} | kubeseal --raw --name=$VALUES_cluster-ssh-private-key --namespace=$VALUES_cluster  --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)

#sed -i '' -e 's#.*cluster.*$#cluster: '$CLUSTER_NAME'#g' values.yaml
sed -i '' -e 's#.*azure_creds.*$#  azure_creds: '$ENC_AZ_ID'#g' values.yaml
sed -i '' -e 's#.*pullSecret.*$#  pullSecret: '$ENC_PULL_SECRET'#g' values.yaml
sed -i '' -e 's#.*sshPrivatekey.*$#  sshPrivatekey: '$ENC_SSH_PRIV'#g' values.yaml
sed -i '' -e 's#.*installConfig.*$#  installConfig: '$ENC_INST_CFG'#g' values.yaml

