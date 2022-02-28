#!/usr/bin/env bash

if [[ -z ${AWS_KEY} ]]; then
  echo "Please provide environment variable AWS_KEY"
  exit 1
fi

if [[ -z ${AWS_ID} ]]; then
  echo "Please provide environment variable AWS_ID"
  exit 1
fi

if [[ -z ${SSH_PRIV} ]]; then
  echo "Please provide environment variable SSH_PRIV"
  exit 1
fi

if [[ -z ${SSH_PUB} ]]; then
  echo "Please provide environment variable SSH_PUB"
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

cp templates/install-config.aws.yaml templates/install-config.yaml
install_config=$(helm template install-config . -s templates/install-config.yaml --set provider.sshPublickey="$SSH_PUB" --values values.yaml | sed -e '/---/d' -e '/Source/d')
ENC_INST_CFG=$(echo -n "$install_config" | kubeseal --raw --name=$CLUSTER_NAME-install-config --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
rm templates/install-config.yaml

# Encrypt the secret using kubeseal and private key from the cluster
echo "Creating sealed secrets"
ENC_AWS_ID=$(echo -n ${AWS_ID} | kubeseal --raw --name=$CLUSTER_NAME-aws-creds --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_AWS_KEY=$(echo -n ${AWS_KEY} | kubeseal --raw --name=$CLUSTER_NAME-aws-creds --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME  --from-file=/dev/stdin)
ENC_PULL_SECRET=$(echo -n ${PULL_SECRET} | kubeseal --raw --name=$CLUSTER_NAME-pull-secret --namespace=$CLUSTER_NAME --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)
ENC_SSH_PRIV=$(echo -n ${SSH_PRIV} | kubeseal --raw --name=$CLUSTER_NAME-ssh-private-key --namespace=$CLUSTER_NAME  --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)

echo "Updating values file with encrypted secrets"
sed -i '' -e 's#.*cluster.*$#cluster: '$CLUSTER_NAME'#g' values.yaml
sed -i '' -e 's#.*aws_access_key_id.*$#    aws_access_key_id: '$ENC_AWS_ID'#g' values.yaml
sed -i '' -e 's#.*aws_secret_access_key.*$#    aws_secret_access_key: '$ENC_AWS_KEY'#g' values.yaml
sed -i '' -e 's#.*pullSecret.*$#    pullSecret: '$ENC_PULL_SECRET'#g' values.yaml
sed -i '' -e 's#.*sshPrivatekey.*$#    sshPrivatekey: '$ENC_SSH_PRIV'#g' values.yaml
sed -i '' -e 's#.*installConfig.*$#    installConfig: '$ENC_INST_CFG'#g' values.yaml
