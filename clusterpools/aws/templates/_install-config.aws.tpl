{{- define "cluster.install-config" -}}
apiVersion: v1
metadata:
  name: '{{ .Values.cluster }}' 
baseDomain: {{ .Values.provider.baseDomain }}
controlPlane:
  architecture: {{ .Values.masters.architecture }}
  hyperthreading: Enabled
  name: master
  replicas: {{ .Values.masters.count }}
  platform:
    aws:
      rootVolume:
        iops: {{ .Values.masters.diskIops }}
        size: {{ .Values.masters.diskSize }} 
        type: {{ .Values.masters.diskType }}
      type: {{ .Values.masters.machineType }}
compute:
- hyperthreading: Enabled
  architecture: {{ .Values.workers.architecture }}
  name: 'worker'
  replicas: {{ .Values.workers.count }}
  platform:
    aws:
      rootVolume:
        iops: {{ .Values.workers.diskIops }}
        size: {{ .Values.workers.diskSize }} 
        type: {{ .Values.workers.diskType }}
      type: {{ .Values.workers.machineType }}
networking:
  clusterNetwork:
  - cidr: {{ .Values.network.clusterCidr }} 
    hostPrefix: 23
  machineNetwork:
  - cidr: {{ .Values.network.machineCidr }}
  networkType: OpenShiftSDN
  serviceNetwork:
  - {{ .Values.network.serviceCidr }} 
platform:
  aws:
    region: {{ .Values.provider.region }}
pullSecret: "" # skip, hive will inject based on it's secrets
sshKey: |-
    {{ .Values.provider.sshPublickey }}
{{- end -}}