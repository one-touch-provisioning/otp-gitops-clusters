{{- define "cluster.install-config" -}}
apiVersion: v1
metadata:
  name: '{{ .Values.cluster }}' 
baseDomain: {{ .Values.provider.baseDomain }}
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: {{ .Values.masters.count }}
  platform:
    azure:
      osDisk:
        diskSizeGB: {{ .Values.masters.diskSize }} 
      type:  {{ .Values.masters.machineType }}
compute:
- hyperthreading: Enabled
  name: 'worker'
  replicas: {{ .Values.workers.count }}
  platform:
    azure:
      type:  {{ .Values.workers.machineType }}
      osDisk:
        diskSizeGB: {{ .Values.workers.diskSize }}
      zones:
      - "1"
      - "2"
      - "3"
networking:
  clusterNetwork:
  - cidr: {{ .Values.network.clusterCidr }} 
    hostPrefix: 23
  machineNetwork:
  - cidr: {{ .Values.network.machineCidr }}
  networkType: OVNKubernetes
  serviceNetwork:
  - {{ .Values.network.serviceCidr }} 
platform:
  azure:
    baseDomainResourceGroupName: {{ .Values.provider.resource_group }}
    region: {{ .Values.provider.region }}
fips: {{ .Values.fipsModule }}
pullSecret: "" # skip, hive will inject based on it's secrets
sshKey: |-
    {{ .Values.provider.sshPublickey }}
{{- end -}}