# External Secrets

These manifests in this folder will install the External Secrets Operator.
External secrets provides a method to sync secrets from an external keystore, and write them to a local secret in OpenShift/Kubernetes. It will not write to the external key store, thus the secrets have to be updated outside the normal workflow of the OTP Pattern.

External Secrets Supports a number of backing keystores, many can be used in parallel if need be.
 + AWS Secrets Manager
 + AWS Parameter Store
 + Akeyless
 + Hashicorp Vault
 + Google Cloud Secrets Manager
 + Azure Key Vault
 + IBM Cloud Secrets Manager
 + Yandex Lockbox
 + Gitlab Project Variables
 + Alibaba Cloud KMS (Docs still missing, PRs welcomed!)
 + Oracle Vault
 + Generic Webhook

For more info refer to https://external-secrets.io/ and https://github.com/external-secrets/external-secrets

Once the operator is installed then Secret Stores and External Secrets need to be defined, a Secret Store can either be a ClusterSecretStore or a SecretStore, the SecretStore is resticted to the namespace its in while the ClusterSecretStore is cluster wide.

# Definitions
## ClusterSecretStore
The following is an example of creating a ClusterSecretStore for a Vault backend hosted within the Openshift Cluster (which is also part of the pattern), however the vault could be anywhere.

Replace the \<VAULT ROOT CA IN BASE64\> AND \<VAULT TOKEN IN BASE64\>

```
apiVersion: external-secrets.io/v1alpha1
kind: ClusterSecretStore
metadata:
  name: secretstore-vault
  namespace: external-secrets
spec:
  provider:
    vault:
      server: "https://vault.vault.svc.cluster.local:8200"
      version: "v1" # leave as v1
      path: ""  # added to every call to vault, needs to be co-ordinated with the external secret definition to build the path
      caBundle: "<VAULT ROOT CA IN BASE64>"
      auth:
        # points to a secret that contains a vault token, see below for example.
        # https://www.vultproject.io/docs/auth/token
        tokenSecretRef:
          name: "vault-token"
          namespace: "external-secrets"
          key: "token"
```

And the coresponding Secret for the token
```
---
apiVersion: v1
kind: Secret
metadata:
  name: vault-token
  namespace: external-secrets
data:
  token: <VAULT TOKEN IN BASE64>
```


## ExternalSecret
The External Secret Definition defines;
 - The Secret Store to use (see above) (secretStoreRef)
 - The Kubernetes Secret to Sync too (target)
 - The Sync Frequency (refreshInterval)
 - The secret definition from the External Store (remoteRef)

The following is an example the goes with the ClusterSecretStore definition above
 ```
 apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: vault-example
spec:
  refreshInterval: "15s"
  secretStoreRef:
    name: secretstore-vault
    kind: ClusterSecretStore
  target:
    name: example-sync
  data:
  - secretKey: foobar
    remoteRef:
      key: secret/foo
      property: my-value
```

The coresponding Kuberentes secret defintion that the remote secret will be synced to.
```
---
apiVersion: v1
kind: Secret
metadata:
  name: example-sync
data:
  foobar: czNjcjN0
```


## Creating Vault Secrets
Once a vault cluster has been initalized, then the corresponding cofiguration is will create secrets that the example ClusterSecretStore and ExternalSecret will work with.

These commands are run from within the vault pod i.e. 
``` 
oc exec -it vault-0 -n vault -- sh 

vault secrets enable -address https://vault-0.aws-cluster-shared-0.vault-internal.vault.svc.clusterset.local:8200 -ca-path /etc/vault-tls/ca.crt -path=secret/ kv
Success! Enabled the kv secrets engine at: secret/

vault kv put -address https://vault-0.aws-cluster-shared-0.vault-internal.vault.svc.clusterset.local:8200 -ca-path /etc/vault-tls/ca.crt  secret/foo my-vaule=s3cr3t
Success! Data written to: secret/foo
```


# Debugging
To check your secret is available and at the path you think it is you can use the following curl for v1 
```
curl -i -H "X-Vault-Token: <VAULT TOKEN>" -X GET https://vault.apps.aws-cluster-shared-0.ibmsbaasonaws.com/v1/secret/foo

HTTP/1.1 200 OK
cache-control: no-store
content-type: application/json
date: Wed, 19 Jan 2022 06:29:05 GMT
content-length: 192
set-cookie: 776683a2f8e81e21b94004411f371c70=d0848266843c025f96c297eaf493403f; path=/; HttpOnly; Secure; SameSite=None

{"request_id":"72305993-1adb-664f-940c-df91d23105be","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"my-value":"anothersecret"},"wrap_info":null,"warnings":null,"auth":null}
```

A curl for a key-value using v2 kv store, the key store is named kv-v2 and the seceret was called hello
```
curl -ik -H "X-Vault-Token: s.5v2kczlo4ujJS4eoVYCQadrV" https://vault.apps.aws-cluster-shared-0.ibmsbaasonaws.com/v1/v2-kv/data/hello

HTTP/1.1 200 OK
cache-control: no-store
content-type: application/json
date: Wed, 19 Jan 2022 05:57:37 GMT
content-length: 300
set-cookie: 776683a2f8e81e21b94004411f371c70=d0848266843c025f96c297eaf493403f; path=/; HttpOnly; Secure; SameSite=None

{"request_id":"b96f1bb2-576e-b4ae-e21a-b3e7c4936a11","lease_id":"","renewable":false,"lease_duration":0,"data":{"data":{"secret1":"wasssssup"},"metadata":{"created_time":"2022-01-19T05:50:31.819274929Z","deletion_time":"","destroyed":false,"version":1}},"wrap_info":null,"warnings":null,"auth":null}
```

The OperatorConfig included in the manifests will create a pod that performs the secret syncing under the external-secrets namespace.
The Pods logs can help dubug syncing problems e.g.

```
$> oc get pods -n external-secrets
NAME                                      READY   STATUS    RESTARTS   AGE
external-secrets-6c4f974df8-ndwqh         1/1     Running   0          99m
external-secrets-operator-catalog-b7fp4   1/1     Running   0          100m

$> oc logs -n external-secrets external-secrets-6c4f974df8-ndwqh
I0114 23:44:10.244207       1 request.go:668] Waited for 1.040091582s due to client-side throttling, not priority and fairness, request: GET:https://172.35.0.1:443/apis/security.openshift.io/v1?timeout=32s
{"level":"info","ts":1642203852.701633,"logger":"controller-runtime.metrics","msg":"metrics server is starting to listen","addr":":8080"}
{"level":"info","ts":1642203852.701975,"logger":"setup","msg":"starting manager"}
{"level":"info","ts":1642203852.7027054,"logger":"controller-runtime.manager","msg":"starting metrics server","path":"/metrics"}
{"level":"info","ts":1642203852.702793,"logger":"controller-runtime.manager.controller.secretstore","msg":"Starting EventSource","reconciler group":"external-secrets.io","reconciler kind":"SecretStore","source":"kind source: /, Kind="}
{"level":"info","ts":1642203852.702823,"logger":"controller-runtime.manager.controller.secretstore","msg":"Starting Controller","reconciler group":"external-secrets.io","reconciler kind":"SecretStore"}
{"level":"info","ts":1642203852.7028267,"logger":"controller-runtime.manager.controller.externalsecret","msg":"Starting EventSource","reconciler group":"external-secrets.io","reconciler kind":"ExternalSecret","source":"kind source: /, Kind="}
{"level":"info","ts":1642203852.7028623,"logger":"controller-runtime.manager.controller.externalsecret","msg":"Starting EventSource","reconciler group":"external-secrets.io","reconciler kind":"ExternalSecret","source":"kind source: /,
```
