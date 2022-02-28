# Amazon CloudWatch Agent
## Introduction
This Amazon Cloud Watch instance deploys the amazon cloudwatch agent, which has been configuired to scrape metrics from the built in prometheus instance of the OCP cluster and ship them to Amazon CloudWatch.

## Credentials
AWS credentials are needed for the logs to appear in the correct account.

Currently these credentials are added to a secret at runtime by kustomize. The agent (in the container) expects them to be in a file with a particualr format. The "credentials" file in each overlay is used by the kustomize secretGenerator function to create the final secret that is applied to OCP.

While a centralised secrets solution  is yet to be defined, the credentials are being created locally per cluster. 

**DO NOT COMMIT THE CREDENTIALS FILE TO GIT**


## Configuration
This is for informational purposes, the clustername customisation is done automatically, when the application is deployed, a job will run, find the cluster name and create the config map

Similar to the credentials, a configuration file that is cluster (maybe not always) specific needs to be also created, the configMapGenerator function of kustomize is also used to read the contents of the cwagentconfig.json and create a configmap from it.

Region, this can be the same for all, but does not have to be.
```
    "agent": {
      "region": "ap-northeast-1",
      "debug": true
    },
```

Cluster Name, in the example below aws-tokyo should be changed per cluster, in both the cluster_name and log_group_name
```
 "metrics_collected": {
        "prometheus": {
          "cluster_name": "aws-tokyo",
          "log_group_name": "/aws/containerinsights/aws-tokyo/prometheus",
          "prometheus_config_path": "/etc/prometheusconfig/prometheus.yaml",
```

More metrics can be collected by manipulating the metric_declaration blocks