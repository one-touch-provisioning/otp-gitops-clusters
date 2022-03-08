Each Cluster Type has a unqiue set of secrets required for them to be created automatically by RHACM

In order to maintain security Bitnami's SealedSecrets is used to protect the configuration when stored in git. To support ease of use a simple shell script has been created
to take pre-configured environment variables and encrypt them so they are suitable to be used with the SealedSecret kind.

1. cd into the directoy of the cluster you wish to install 
2. update the values files for  your deployment
3. create the environment variables (see below whats required for the different cloud providers)
4. ./make_secret.sh
5. git commit or use helm to deploy

AWS:

- AWS_KEY - the AWS secret access key
- AWS_ID - AWS access ID
- SSH_PRIV_FILE - File path to the SSH Priv Key (eg ~/.ssh/id_rsa)
- PULL_SECRET - the open shift pull secret

AZURE:

- AZ_CLIENT_ID - Azure Client ID
- AZ_CLIENT_KEY - Azure Client Key
- AZ_TEN_ID - Azure Tennant ID
- AZ_SUB_ID - Azure Subscription ID
- SSH_PRIV_FILE - File path to the SSH Priv Key (eg ~/.ssh/id_rsa)
- SSH_PUB_FILE - File path to the SSH Priv Key (eg ~/.ssh/id_rsa.pub)
- PULL_SECRET - the open shift pull secret

VSPHERE:

- VSPH_PASS - vSphere user
- VSPH_USER - vSphere password
- VSPH_PUB_CA_FILE - File path to the the public CA certificate of the vSphere server
- SSH_PUB_FILE - File path to the SSH Pub Key (eg ~/.ssh/id_rsa.pub)
- SSH_PRIV_FILE - File path to the SSH Priv Key (eg ~/.ssh/id_rsa)
- PULL_SECRET - the open shift pull secret

Red Hat OpenShift Cluster Manager:

- RHOCM_TOKEN - Red Hat OpenShift Cluster Manager Token (https://cloud.redhat.com/openshift/token)

Note: Currently the SSH Public Key is not made secret but is still required to be included in values files.
