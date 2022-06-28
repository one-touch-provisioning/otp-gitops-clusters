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

# Set variables
if [[ -z ${RHOCM_TOKEN} ]]; then
  echo "Please provide environment variable RHOCM_TOKEN"
  exit 1
fi

SEALED_SECRET_NAMESPACE=${SEALED_SECRET_NAMESPACE:-sealed-secrets}
SEALED_SECRET_CONTROLLER_NAME=${SEALED_SECRET_CONTROLLER_NAME:-sealed-secrets}

#form the data strucutre containing all the different ids

#extract values from values.yaml
eval $(parse_yaml values.yaml "VALUES_")

#generate the provider config metadata.
read -r -d  '' provider_config << EOM
ocmAPIToken: $RHOCM_TOKEN
EOM

#remove the install config from templates so helm doesnt try to install it
ENC_PROV_CFG=$(echo -n "$provider_config" | kubeseal --raw --name=$VALUES_connection_name --namespace=rhacm-providers --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)

# Encrypt the secret using kubeseal and private key from the cluster
echo "Creating RHOCM Secrets"
sed -i '' -e 's#.*providerSecret.*$#providerSecret: '$ENC_PROV_CFG'#g' values.yaml

